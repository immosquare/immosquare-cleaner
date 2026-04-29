require "digest"
require "fileutils"
require "shellwords"

module ImmosquareCleaner
  module Processors
    class Javascript < Base

      EXTENSIONS = [
        ".js",
        ".mjs",
        ".jsx",
        ".ts",
        ".tsx",
        "js.erb",
        ".ts.erb"
      ].freeze

      def self.match?(file_path)
        file_path.end_with?(*EXTENSIONS)
      end

      def run
        ##============================================================##
        ## ESLint V9 (currently V9.17.0) throws an error:
        ## "warning File ignored because outside of base path"
        ## if the file to lint is in a parent directory of the config file.
        ## ISSUE: https://github.com/eslint/eslint/issues/19118
        ##
        ## To avoid this, we copy the file to a temporary location inside
        ## the gem's root folder, process it there, and copy it back.
        ## The temp filename is hashed from the absolute path so that two
        ## files with the same basename don't collide.
        ##============================================================##
        temp_dir = File.join(ImmosquareCleaner.gem_root, "tmp")
        FileUtils.mkdir_p(temp_dir)

        temp_filename  = "temp_#{Digest::MD5.hexdigest(file_path)}_#{File.basename(file_path)}"
        temp_file_path = File.join(temp_dir, temp_filename)

        begin
          FileUtils.cp(file_path, temp_file_path)
          cmds         = []
          escaped_temp = Shellwords.escape(temp_file_path)

          ##============================================================##
          ## Run erb_lint against the TEMP file, not the original. Otherwise
          ## its autocorrect edits would be overwritten by the final
          ## `FileUtils.cp(temp_file_path, file_path)` below (the temp
          ## copy was taken before erb_lint ran).
          ##============================================================##
          if file_path.end_with?(".erb")
            erblint_config  = "#{ImmosquareCleaner.gem_root}/linters/erb-lint-#{RUBY_VERSION}.yml"
            erblint_options = ImmosquareCleaner.configuration.erblint_options || "--autocorrect"
            cmds << "bundle exec erb_lint --config #{erblint_config} #{escaped_temp} #{erblint_options}"
          else
            cmds << "bun #{ImmosquareCleaner.gem_root}/linters/normalize-comments.mjs #{escaped_temp}"
          end

          cmds << "bun eslint --config #{ImmosquareCleaner.gem_root}/linters/eslint.config.mjs #{escaped_temp} --fix"

          launch_cmds(cmds)
          normalize_last_line(temp_file_path)
          FileUtils.cp(temp_file_path, file_path)
        ensure
          FileUtils.rm_f(temp_file_path)
        end
      end

    end
  end
end
