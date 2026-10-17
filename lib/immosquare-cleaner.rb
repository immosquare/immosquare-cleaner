require "English"
require "yaml"
require "json"
require "immosquare-yaml"
require "immosquare-extensions"
require "fileutils"
require "digest"
require_relative "immosquare-cleaner/ruby_target"
require_relative "immosquare-cleaner/configuration"
require_relative "immosquare-cleaner/markdown"
require_relative "immosquare-cleaner/directory_cleaner"
require_relative "immosquare-cleaner/hook"

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
require_relative "immosquare-cleaner/processors/rust"
require_relative "immosquare-cleaner/processors/go"
require_relative "immosquare-cleaner/processors/toml"
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
  LINTER_CONFIG_MUTEX = Mutex.new
  LINTER_CONFIG_NAMES = ["rubocop", "erb-lint", "js-erb-lint"].freeze

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

    def clean(file_path, origin_path = nil)
      ##============================================================##
      ## Return if the file is in the exclusion list or is a generator
      ## template. With `-p`, file_path is a /tmp copy: the template
      ## check runs on origin_path
      ##============================================================##
      exclude_files = configuration.exclude_files.map {|file| File.join(Dir.pwd, file) }
      return if exclude_files.include?(file_path)
      return if DirectoryCleaner.generator_template?(File.dirname(origin_path || file_path).split("/"))

      begin
        processor = processor_for(file_path)
        processor.run(file_path, origin_path)
      rescue StandardError => e
        warn("Error cleaning #{file_path}: #{e.message}")
        warn(e.backtrace&.join("\n") || "(no backtrace)")
      end
    end

    def clean_directory(root)
      DirectoryCleaner.run(root)
    end

    def supported?(file_path)
      PROCESSORS.any? {|processor| processor.match?(file_path) } || file_path.end_with?(*Processors::Prettier::EXTENSIONS)
    end

    def gem_root
      File.expand_path("..", __dir__)
    end

    ##============================================================##
    ## path : the file's location in its project (origin_path), which
    ##        decides the Ruby target unless ruby_target_version is set
    ##============================================================##
    def linter_config_path(name, path)
      raise(ArgumentError, "Unknown Ruby linter configuration") if !LINTER_CONFIG_NAMES.include?(name)

      target = configuration.ruby_target_version || RubyTarget.detect(path)
      setup_linter_configs!(target).fetch(name)
    end

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
      Processors::Shell,
      Processors::Rust,
      Processors::Go,
      Processors::Toml
    ].freeze

    private

    def processor_for(file_path)
      PROCESSORS.find {|p| p.match?(file_path) } || Processors::Prettier
    end

    ##============================================================##
    ## Configs are shared by target Ruby and template fingerprint.
    ## Atomic writes and a mutex prevent partially generated YAML
    ## during parallel cleaning; template edits invalidate the cache.
    ##============================================================##
    def setup_linter_configs!(target)
      templates = LINTER_CONFIG_NAMES.to_h {|name| [name, File.join(gem_root, "linters", "#{name}.yml")] }
      signature = templates.values.map {|path| [File.mtime(path), File.size(path)] }
      LINTER_CONFIG_MUTEX.synchronize do
        @linter_configs ||= {}
        key = [target, signature]
        return @linter_configs[key] if @linter_configs.key?(key)

        sources = templates.transform_values {|path| File.read(path) }
        fingerprint = Digest::SHA256.hexdigest(sources.values.join("\n")).slice(0, 16)
        paths = LINTER_CONFIG_NAMES.to_h {|name| [name, File.join(gem_root, "linters", "#{name}-#{target}-#{fingerprint}.yml")] }
        rubocop_config = YAML.safe_load(sources.fetch("rubocop"))
        rubocop_config["AllCops"]["TargetRubyVersion"] = target
        rubocop_config["AllCops"]["ParserEngine"] = Gem::Version.new(target) >= Gem::Version.new("3.3") ? "parser_prism" : "parser_whitequark"
        write_linter_config(paths.fetch("rubocop"), rubocop_config)

        ["erb-lint", "js-erb-lint"].each do |name|
          config = YAML.safe_load(sources.fetch(name))
          config["linters"]["Rubocop"]["rubocop_config"]["inherit_from"] = ["linters/#{File.basename(paths.fetch("rubocop"))}"]
          write_linter_config(paths.fetch(name), config)
        end
        @linter_configs[key] = paths.freeze
      end
    end

    def write_linter_config(path, config)
      return if File.file?(path)

      temporary = "#{path}.#{Process.pid}.#{Thread.current.object_id}.tmp"
      File.write(temporary, config.to_yaml)
      File.rename(temporary, path)
    ensure
      File.delete(temporary) if temporary && File.file?(temporary)
    end

  end
end
