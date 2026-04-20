require "fileutils"

module ImmosquareCleaner
  module Processors
    class Erb < Base

      def self.match?(file_path)
        file_path.end_with?(".html.erb", ".html")
      end

      def run
        config_path            = "#{ImmosquareCleaner.gem_root}/linters/erb-lint-#{RUBY_VERSION}.yml"
        htmlbeautifier_options = ImmosquareCleaner.configuration.htmlbeautifier_options || "--keep-blank-lines 4"
        erblint_options        = ImmosquareCleaner.configuration.erblint_options || "--autocorrect"

        cmds = [
          "bundle exec htmlbeautifier #{file_path} #{htmlbeautifier_options}",
          "bundle exec erb_lint --config #{config_path} #{file_path} #{erblint_options}"
        ]

        launch_cmds(cmds)
        normalize_last_line
        FileUtils.rm_f("#{file_path}.tmp")
      end

    end
  end
end
