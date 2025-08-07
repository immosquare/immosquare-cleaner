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
## Importing the 'English' library allows us to use more human-readable
## global variables, such as $INPUT_RECORD_SEPARATOR instead of $/,
## which enhances code clarity and makes it easier to understand
## the purpose of these variables in our code.
##============================================================##
module ImmosquareCleaner
  class << self

    ##============================================================##
    ## Constants
    ##============================================================##
    SHEBANG    = "#!/usr/bin/env ruby".freeze
    RUBY_FILES = [
      ".rb",
      ".rake",
      "Gemfile",
      "Rakefile",
      "Capfile",
      ".axlsx",
      ".gemspec",
      ".cap",
      ".ru",
      ".podspec",
      ".jbuilder",
      ".rabl",
      ".thor",
      "Berksfile",
      "Guardfile",
      "Podfile",
      "Thorfile",
      "Vagrantfile"
    ].freeze

    ##============================================================##
    ## Gem configuration
    ##============================================================##
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


      ##============================================================##
      ## On charge le fichier de configuration s'il existe
      ##============================================================##
      config_file = File.join(Dir.pwd, "config/initializers/immosquare-cleaner.rb")
      load(config_file) if File.exist?(config_file)

      ##============================================================##
      ## On retourne si le fichier est dans la liste des fichiers à exclure
      ##============================================================##
      exclude_files = ImmosquareCleaner.configuration.exclude_files.map {|file| File.join(Dir.pwd, file) }
      return if exclude_files.include?(file_path)

      ##============================================================##
      ## Setup linter with the correct ruby version
      ## Ruby Files
      ## ---------
      ## We create a rubocop config file with the ruby version
      ## if it does not exist with the node TargetRubyVersion
      ## to avoid the warning "Warning: No Ruby version specified in the configuration file"
      ## ---------
      ## Parser : https://docs.rubocop.org/rubocop/configuration.html#setting-the-parser-engine
      ##============================================================##
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

      begin
        ##============================================================##
        ## .html.erb files
        ##============================================================##
        if file_path.end_with?(".html.erb", ".html")
          cmds = []
          cmds << "bundle exec htmlbeautifier #{file_path} #{ImmosquareCleaner.configuration.htmlbeautifier_options || "--keep-blank-lines 4"}"
          cmds << "bundle exec erb_lint --config #{erblint_config_with_version_path} #{file_path} #{ImmosquareCleaner.configuration.erblint_options || "--autocorrect"}"
          launch_cmds(cmds)
          File.normalize_last_line(file_path)
          FileUtils.rm_f("#{file_path}.tmp")



        ##============================================================##
        ## ruby files
        ##============================================================##
        elsif file_path.end_with?(*RUBY_FILES) || File.open(file_path, &:gets)&.include?(SHEBANG)
          ##============================================================##
          ## --autocorrect-all : Auto-correct all offenses that RuboCop can correct, and leave all other offenses unchanged.
          ## --no-parallel     : Disable RuboCop's parallel processing for performance reasons because we pass only one file
          ##============================================================##
          rubocop_options = ImmosquareCleaner.configuration.rubocop_options || "--autocorrect-all --no-parallel"

          cmds = ["bundle exec rubocop -c #{rubocop_config_with_version_path} \"#{file_path}\" #{rubocop_options}"]
          launch_cmds(cmds)
          File.normalize_last_line(file_path)



        ##============================================================##
        ## locles.yml
        ##============================================================##
        elsif file_path =~ %r{locales/.*\.yml$}
          ImmosquareYaml.clean(file_path)

          ##============================================================##
          ## JS files
          ## 16/05/2024
          ## maj 06/01/2025
          ## ---------
          ## Depuis eslint V9 (acutellement en V9.17.0), il y a une erreur
          ## "warning  File ignored because outside of base path"
          ## si le fichier à linté est dans un dossier supérieur à celui du fichier de config.
          ## ISSUE : https://github.com/eslint/eslint/issues/19118
          ## ---------
          ## Dans nos apps nous sommes tjs dans ce cas car le fichier de config est dans le dossier du gem.
          ## et les fichiers à linté sont dans les apps.
          ## ---------
          ## Pour éviter ce problème on met le fichier dans un dossier temporaire dans le dossier du gem
          ## et on le supprime par la suite.
          ##============================================================##
        elsif file_path.end_with?(".js", ".mjs", "js.erb")
          begin
            temp_folder_path = "#{gem_root}/tmp"
            temp_file_path = "#{temp_folder_path}/#{File.basename(file_path)}"
            FileUtils.mkdir_p(temp_folder_path)
            File.write(temp_file_path, File.read(file_path))
            cmds = []
            cmds << "bundle exec erb_lint --config #{erblint_config_with_version_path} #{file_path} #{ImmosquareCleaner.configuration.erblint_options || "--autocorrect"}" if file_path.end_with?("js.erb")
            cmds << "bun eslint --config #{gem_root}/linters/eslint.config.mjs  #{temp_file_path} --fix"

            launch_cmds(cmds)
            File.normalize_last_line(temp_file_path)
            File.write(file_path, File.read(temp_file_path))
          ensure
            FileUtils.rm_f(temp_file_path)
          end



        ##============================================================##
        ## JSON files
        ##============================================================##
        elsif file_path.end_with?(".json")
          json_str = File.read(file_path)
          parsed_data = JSON.parse(json_str)
          formated    = parsed_data.to_beautiful_json
          File.write(file_path, formated)
          File.normalize_last_line(file_path)


        ##============================================================##
        ## Markdown files
        ##============================================================##
        elsif file_path.end_with?(".md", ".md.erb")
          formatted_md = ImmosquareCleaner::Markdown.clean(file_path)
          File.write(file_path, formatted_md)
          File.normalize_last_line(file_path)

        ##============================================================##
        ## Shell files (.sh)
        ## ---------
        ## Uses shfmt to format shell scripts with 2-space indentation
        ## Checks if shfmt is available before processing
        ##============================================================##
        elsif file_path.end_with?(".sh")
          if system("which shfmt > /dev/null 2>&1")
            cmds = ["shfmt -i 2 -w \"#{file_path}\""]
            launch_cmds(cmds)
            File.normalize_last_line(file_path)
          else
            puts "ERROR: shfmt is not installed. Please install it with: brew install shfmt"
          end

        ##============================================================##
        ## Autres formats
        ##============================================================##
        else
          prettier_parser = nil
          prettier_parser = "--parser markdown" if file_path.end_with?(".md.erb")
          cmds = ["bun prettier --write #{file_path} #{prettier_parser} --config #{gem_root}/linters/prettier.yml"]
          launch_cmds(cmds)
        end
      rescue StandardError => e
        puts(e.message)
        puts(e.backtrace)
      end
    end

    private

    def gem_root
      File.expand_path("..", __dir__)
    end

    ##============================================================##
    ## We change the current directory to the gem root to ensure the gem's paths
    ## are used when executing the commands
    ##============================================================##
    def launch_cmds(cmds)
      Dir.chdir(gem_root) do
        cmds.each {|cmd| system(cmd) }
      end
    end


  end
end
