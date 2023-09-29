require_relative "immosquare-cleaner/configuration"
require          "immosquare-yaml"

module ImmosquareCleaner
  
  class << self

    ##===========================================================================##
    ## Constants
    ##===========================================================================##
    NEWLINE = "\n".freeze
    SHEBANG = "#!/usr/bin/env ruby".freeze

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
      cmd     = []
      options = {}.merge(options)

      
      begin
        raise("Error: The file '#{file_path}' does not exist.") if !File.exist?(file_path)

        ##============================================================##
        ## We normalize the last line of the file to ensure it ends with a single
        ##============================================================##
        normalize_last_line(file_path)

        ##============================================================##
        ## We clean files based on their extension
        ##============================================================##
        if file_path.end_with?(".html.erb")
          cmd << "bundle exec htmlbeautifier #{file_path} #{ImmosquareCleaner.configuration.htmlbeautifier_options || "--keep-blank-lines 4"}"
          cmd << "bundle exec erblint -c #{gem_root}/linters/erb-lint.yml #{file_path} #{ImmosquareCleaner.configuration.erblint_options || "--autocorrect"}"
        elsif file_path.end_with?(".rb", ".rake", "Gemfile", "Rakefile", ".axlsx", ".gemspec", ".ru", ".podspec", ".jbuilder", ".rabl", ".thor", "config.ru", "Berksfile", "Capfile", "Guardfile", "Podfile", "Thorfile", "Vagrantfile") || File.open(file_path, &:gets)&.include?(SHEBANG)
          cmd << "bundle exec rubocop -c #{gem_root}/linters/rubocop.yml #{file_path} #{ImmosquareCleaner.configuration.rubocop_options || "--autocorrect-all"}"
        elsif file_path =~ %r{locales/.*\.yml$}
          ImmosquareYaml.clean(file_path)
        end


        if cmd.empty?
          extension = File.extname(file_path)
          puts("extension: #{extension} not supported") if cmd.nil?
        else
          ##===========================================================================##
          ## We change the current directory to the gem root to ensure the gem's paths
          ## are used when executing the commands
          ##===========================================================================##
          Dir.chdir(gem_root) do
            cmd.each do |c|
              system(c)
            end
          end
        end
      rescue StandardError => e
        puts(e.message)
        false
      end
    end




    private

    def gem_root
      File.expand_path("..", __dir__)
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
      ##============================================================##
      ## Read all lines from the file
      ## https://gist.github.com/guilhermesimoes/d69e547884e556c3dc95
      ##============================================================##
      lines = File.read(file_path).lines

      ##============================================================##
      ## Ensure the last line ends with a newline character
      ##============================================================##
      lines[-1] = "#{lines[-1]}#{NEWLINE}" if !lines[-1].end_with?(NEWLINE)
      
      ##===========================================================================##
      ## Remove all trailing empty lines at the end of the file
      ##===========================================================================##
      lines.pop while lines.last && lines.last.strip.empty?
    
      ##===========================================================================##
      ## Append a newline at the end to maintain the file structure
      ###===========================================================================##
      lines += [NEWLINE]
      
      ##===========================================================================##
      ## Write the modified lines back to the file
      ##===========================================================================##
      File.write(file_path, lines.join)

      ##===========================================================================##
      ## Return the total number of lines in the modified file
      ##===========================================================================##
      lines.size
    end


  end
end

