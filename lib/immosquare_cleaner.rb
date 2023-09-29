require_relative "immosquare-cleaner/configuration"


module ImmosquareCleaner
  
  class << self

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
        raise("Error: The file '#{file_path}' does not exist.") if !File.exist?(file_path)

        cmd = nil
        if file_path.end_with?(".html.erb")
          cmd = "bundle exec htmlbeautifier #{file_path} --keep-blank-lines 4"
        elsif file_path.end_with?(".rb")  
          cmd = "bundle exec rubocop #{file_path} --autocorrect-all"
        end

        puts(cmd)
        system(cmd) if !cmd.nil?
    
      rescue StandardError => e
        puts(e.message)
        false
      end
    end




    private

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