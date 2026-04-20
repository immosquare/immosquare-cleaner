require "json"

module ImmosquareCleaner
  module Processors
    class Json < Base
      def self.match?(file_path)
        file_path.end_with?(".json")
      end

      def run
        json_str    = File.read(file_path)
        parsed_data = JSON.parse(json_str)
        formatted   = parsed_data.to_beautiful_json
        File.write(file_path, formatted)
        normalize_last_line
      end
    end
  end
end
