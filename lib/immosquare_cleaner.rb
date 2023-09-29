require "English"
require "neatjson"
require_relative "immosquare_cleaner/configuration"
require_relative "immosquare_cleaner/railtie" if defined?(Rails)

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
      procesed = false
      cmd      = []
      options  = {}.merge(options)


      begin
        raise("Error: The file '#{file_path}' does not exist.") if !File.exist?(file_path)

        ##============================================================##
        ## .html.erb files
        ##============================================================##
        if file_path.end_with?(".html.erb")
          cmd << "bundle exec htmlbeautifier #{file_path} #{ImmosquareCleaner.configuration.htmlbeautifier_options || "--keep-blank-lines 4"}"
          cmd << "bundle exec erblint --config #{gem_root}/linters/erb-lint.yml #{file_path} #{ImmosquareCleaner.configuration.erblint_options || "--autocorrect"}"
          procesed = true
        end

        ##============================================================##
        ## Ruby Files
        ##============================================================##
        if !procesed && (file_path.end_with?(*RUBY_FILES) || File.open(file_path, &:gets)&.include?(SHEBANG))
          cmd << "bundle exec rubocop -c #{gem_root}/linters/rubocop.yml #{file_path} #{ImmosquareCleaner.configuration.rubocop_options || "--autocorrect-all"}"
          procesed = true
        end

        ##============================================================##
        ## Yml translations files
        ##============================================================##
        if !procesed && file_path =~ %r{locales/.*\.yml$}
          ImmosquareYaml.clean(file_path)
          procesed = true
        end

        ##============================================================##
        ## JS files
        ##============================================================##
        if !procesed && file_path.end_with?(".js")
          cmd << "npx eslint --config #{gem_root}/linters/eslintrc.json  #{file_path} --fix"
          procesed = true
        end

        ##============================================================##
        ## JSON files
        ##============================================================##
        if !procesed && file_path.end_with?(".json")
          json_str    = File.read(file_path)
          parsed_data = JSON.parse(json_str)
          formated    = JSON.neat_generate(parsed_data, :aligned => true)
          File.write(file_path, formated)
          procesed = true
        end

        ##============================================================##
        ## Autres formats
        ##============================================================##
        if npx_installed? && prettier_installed?
          prettier_parser = nil
          prettier_parser = "--parser markdown" if file_path.end_with?(".md.erb")
          cmd << "npx prettier --write #{file_path} #{prettier_parser} --config #{gem_root}/linters/prettier.yml"
        else
          puts("Warning: npx and/or prettier are not installed. Skipping formatting.")
        end if !procesed


        ##===========================================================================##
        ## We change the current directory to the gem root to ensure the gem's paths
        ## are used when executing the commands
        ##===========================================================================##
        Dir.chdir(gem_root) do
          cmd.each {|c| system(c) }
        end if !cmd.empty?

        ##============================================================##
        ## We normalize the last line of the file to ensure it ends with a single
        ##============================================================##
        normalize_last_line(file_path)
      rescue StandardError => e
        puts(e.message)
        puts(e.backtrace)
      end
    end


    private

    def gem_root
      File.expand_path("..", __dir__)
    end

    def npx_installed?
      system("which npx > /dev/null 2>&1")
    end

    def prettier_installed?
      system("npx prettier --version > /dev/null 2>&1")
    end

    ##===========================================================================##
    ## This method ensures the file ends with a single newline, facilitating
    ## cleaner multi-line blocks. It operates by reading all lines of the file,
    ## removing any empty lines at the end, and then appending a newline.
    ## This guarantees the presence of a newline at the end, and also prevents
    ## multiple newlines from being present at the end.
    ##
    ## Params:
    ## +file_path+:: The path to the file to be normalized.
    ##
    ## Returns:
    ## The total number of lines in the normalized file.
    ##===========================================================================##
    def normalize_last_line(file_path)
      end_of_line = $INPUT_RECORD_SEPARATOR
      ##============================================================##
      ## Read all lines from the file
      ## https://gist.github.com/guilhermesimoes/d69e547884e556c3dc95
      ##============================================================##
      content = File.read(file_path)


      ##===========================================================================##
      ## Remove all trailing empty lines at the end of the file
      ##===========================================================================##
      content.gsub!(/#{Regexp.escape(end_of_line)}+\z/, "")

      ##===========================================================================##
      ## Append an EOL at the end to maintain the file structure
      ##===========================================================================##
      content << end_of_line

      ##===========================================================================##
      ## Write the modified lines back to the file
      ##===========================================================================##
      File.write(file_path, content)

      ##===========================================================================##
      ## Return the total number of lines in the modified file
      ##===========================================================================##
      content.lines.size
    end

  end
end
