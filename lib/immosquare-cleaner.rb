require "English"
require "yaml"
require "json"
require "immosquare-yaml"
require "immosquare-extensions"
require "fileutils"
require_relative "immosquare-cleaner/configuration"
require_relative "immosquare-cleaner/markdown"
require_relative "immosquare-cleaner/railtie" if defined?(Rails)

##============================================================##
## Processors
##============================================================##
require_relative "immosquare-cleaner/processors/base"
require_relative "immosquare-cleaner/processors/ruby"
require_relative "immosquare-cleaner/processors/erb"
require_relative "immosquare-cleaner/processors/javascript"
require_relative "immosquare-cleaner/processors/json"
require_relative "immosquare-cleaner/processors/markdown"
require_relative "immosquare-cleaner/processors/shell"
require_relative "immosquare-cleaner/processors/yaml"
require_relative "immosquare-cleaner/processors/prettier"

##============================================================##
## note 1 : Importing the 'English' library allows us to use more human-readable
## global variables, such as $INPUT_RECORD_SEPARATOR instead of $/,
## which enhances code clarity and makes it easier to understand
## the purpose of these variables in our code.
## ---------
## note 2 :
## Custom erb_lint linters are stored in this folder.
## A symlink .erb_linters -> linters/erb_lint is required at the
## gem root because erb_lint hardcodes the custom linters directory
## to ".erb_linters" and this cannot be configured.
## See: https://github.com/Shopify/erb_lint/blob/main/lib/erb_lint/linter_registry.rb#L7
##============================================================##
module ImmosquareCleaner
  class << self

    ##============================================================##
    ## Gem configuration
    ##============================================================##
    attr_writer(:configuration)

    def configuration
      return @configuration if @configuration

      ##============================================================##
      ## Assign the Configuration instance BEFORE loading the user's
      ## initializer. Otherwise, any `ImmosquareCleaner.config { ... }`
      ## call inside the initializer would re-enter this method while
      ## @configuration is still nil and recurse infinitely.
      ##============================================================##
      @configuration = Configuration.new
      config_file    = File.join(Dir.pwd, "config/initializers/immosquare-cleaner.rb")
      load(config_file) if File.exist?(config_file)
      @configuration
    end

    def config
      yield(configuration)
    end

    def clean(file_path)
      ##============================================================##
      ## Ensure linter configurations are ready
      ##============================================================##
      setup_linter_configs!

      ##============================================================##
      ## Return if the file is in the exclusion list
      ##============================================================##
      exclude_files = configuration.exclude_files.map {|file| File.join(Dir.pwd, file) }
      return if exclude_files.include?(file_path)

      begin
        processor = processor_for(file_path)
        processor.run(file_path)
      rescue StandardError => e
        warn("Error cleaning #{file_path}: #{e.message}")
        warn(e.backtrace&.join("\n") || "(no backtrace)")
      end
    end

    def gem_root
      File.expand_path("..", __dir__)
    end

    private

    ##============================================================##
    ## Processor registry — order matters.
    ##
    ## The list is scanned top-to-bottom and the first processor
    ## whose `.match?` returns true wins. Specific matchers must
    ## come before generic ones. For example:
    ##   - Erb (.html.erb) before Javascript (.ts.erb / js.erb),
    ## so that .html.erb never falls through to Javascript.
    ##   - Ruby (which also detects `#!/usr/bin/env ruby` shebangs)
    ## before Shell, since a shebang'd Ruby script could have
    ## an unrelated extension.
    ##
    ## Prettier is the fallback and is NOT in this list — it is
    ## returned by `processor_for` when nothing else matches.
    ##============================================================##
    PROCESSORS = [
      Processors::Erb,
      Processors::Ruby,
      Processors::Yaml,
      Processors::Javascript,
      Processors::Json,
      Processors::Markdown,
      Processors::Shell
    ].freeze

    def processor_for(file_path)
      PROCESSORS.find {|p| p.match?(file_path) } || Processors::Prettier
    end

    ##============================================================##
    ## Setup linter with the correct ruby version
    ## This is run once to avoid redundant file operations.
    ##============================================================##
    def setup_linter_configs!
      @setup_linter_configs ||= begin
        rubocop_config_with_version_path = "#{gem_root}/linters/rubocop-#{RUBY_VERSION}.yml"
        erblint_config_with_version_path = "#{gem_root}/linters/erb-lint-#{RUBY_VERSION}.yml"

        if !File.exist?(rubocop_config_with_version_path)
          rubocop_config                                  = YAML.load_file("#{gem_root}/linters/rubocop.yml")
          rubocop_config["AllCops"]["TargetRubyVersion"]  = RUBY_VERSION
          rubocop_config["AllCops"]["ParserEngine"]       = RUBY_VERSION >= "3.3" ? "parser_prism" : "parser_whitequark"
          File.write(rubocop_config_with_version_path, rubocop_config.to_yaml)
        end

        if !File.exist?(erblint_config_with_version_path)
          erblint_config                                                         = YAML.load_file("#{gem_root}/linters/erb-lint.yml")
          erblint_config["linters"]["Rubocop"]["rubocop_config"]["inherit_from"] = ["linters/rubocop-#{RUBY_VERSION}.yml"]
          File.write(erblint_config_with_version_path, erblint_config.to_yaml)
        end
        true
      end
    end

  end
end
