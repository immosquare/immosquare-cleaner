require "English"
require "yaml"
require "immosquare-yaml"
require "immosquare-extensions"
require_relative "immosquare-cleaner/configuration"
require_relative "immosquare-cleaner/markdown"
require_relative "immosquare-cleaner/railtie" if defined?(Rails)

##===========================================================================##
## Importing the 'English' library allows us to use more human-readable
## global variables, such as $INPUT_RECORD_SEPARATOR instead of $/,
## which enhances code clarity and makes it easier to understand
## the purpose of these variables in our code.
##===========================================================================##
module ImmosquareCleaner
  class << self

    ##===========================================================================##
    ## Constants
    ##===========================================================================##
    SHEBANG    = "#!/usr/bin/env ruby".freeze
    RUBY_FILES = [".rb", ".rake", "Gemfile", "Rakefile", ".axlsx", ".gemspec", ".ru", ".podspec", ".jbuilder", ".rabl", ".thor", "config.ru", "Berksfile", "Capfile", "Guardfile", "Podfile", "Thorfile", "Vagrantfile"].freeze

    ##===========================================================================##
    ## Gem configuration
    ##===========================================================================##
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def config
      yield(configuration)
    end

    def clean(file_path, **options)
      ##============================================================##
      ## Default options
      ##============================================================##
      options = {}.merge(options)

      begin
        ##============================================================##
        ## .html.erb files
        ##============================================================##
        if file_path.end_with?(".html.erb", ".html")
          cmds = []
          cmds << "bundle exec htmlbeautifier #{file_path} #{ImmosquareCleaner.configuration.htmlbeautifier_options || "--keep-blank-lines 4"}"
          cmds << "bundle exec erblint --config #{gem_root}/linters/erb-lint.yml #{file_path} #{ImmosquareCleaner.configuration.erblint_options || "--autocorrect"}"
          launch_cmds(cmds)
          File.normalize_last_line(file_path)
          return
        end

        ##============================================================##
        ## Ruby Files
        ## We create a rubocop config file with the ruby version
        ## if it does not exist...Normally rubocop does it alone
        ## of this based on .ruby-version file but it doesn't work
        ## in our case where rubocop is in a gem which is called
        ## in a project...
        ##============================================================##
        if file_path.end_with?(*RUBY_FILES) || File.open(file_path, &:gets)&.include?(SHEBANG)
          rubocop_config_with_version_path = "#{gem_root}/linters/rubocop-#{RUBY_VERSION}.yml"

          if !File.exist?(rubocop_config_with_version_path)
            rubocop_config = YAML.load_file("#{gem_root}/linters/rubocop.yml")
            rubocop_config["AllCops"] ||= {}
            rubocop_config["AllCops"]["TargetRubyVersion"] = RUBY_VERSION
            File.write(rubocop_config_with_version_path, rubocop_config.to_yaml)
          end

          cmds = ["bundle exec rubocop -c #{rubocop_config_with_version_path} #{file_path} #{ImmosquareCleaner.configuration.rubocop_options || "--autocorrect-all"}"]
          launch_cmds(cmds)
          File.normalize_last_line(file_path)
          return
        end

        ##============================================================##
        ## Yml translations files
        ##============================================================##
        if file_path =~ %r{locales/.*\.yml$}
          ImmosquareYaml.clean(file_path)
          return
        end

        ##============================================================##
        ## JS files
        ##============================================================##
        if file_path.end_with?(".js")
          cmds = ["bun eslint --config #{gem_root}/linters/eslintrc.json  #{file_path} --fix"]
          launch_cmds(cmds)
          File.normalize_last_line(file_path)
          return
        end

        ##============================================================##
        ## JSON files
        ##============================================================##
        if file_path.end_with?(".json")
          json_str    = File.read(file_path)
          parsed_data = JSON.parse(json_str)
          formated    = parsed_data.to_beautiful_json
          File.write(file_path, formated)
          File.normalize_last_line(file_path)
          return
        end

        ##============================================================##
        ## Markdown files
        ##============================================================##
        if file_path.end_with?(".md", ".md.erb")
          formatted_md = ImmosquareCleaner::Markdown.clean(file_path)
          File.write(file_path, formatted_md)
          File.normalize_last_line(file_path)
          return
        end

        ##============================================================##
        ## Autres formats
        ##============================================================##
        prettier_parser = nil
        prettier_parser = "--parser markdown" if file_path.end_with?(".md.erb")
        cmds = ["bun prettier --write #{file_path} #{prettier_parser} --config #{gem_root}/linters/prettier.yml"]
        launch_cmds(cmds)
      rescue StandardError => e
        puts(e.message)
        puts(e.backtrace)
      end
    end

    private

    def gem_root
      File.expand_path("..", __dir__)
    end

    ##===========================================================================##
    ## We change the current directory to the gem root to ensure the gem's paths
    ## are used when executing the commands
    ##===========================================================================##
    def launch_cmds(cmds)
      Dir.chdir(gem_root) do
        cmds.each {|cmd| system(cmd) }
      end
    end


  end
end
