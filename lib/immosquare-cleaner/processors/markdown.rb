module ImmosquareCleaner
  module Processors
    class Markdown < Base
      def self.match?(file_path)
        file_path.end_with?(".md", ".md.erb")
      end

      def run
        formatted_md = ImmosquareCleaner::Markdown.clean(file_path)
        File.write(file_path, formatted_md)
        normalize_last_line
      end
    end
  end
end
