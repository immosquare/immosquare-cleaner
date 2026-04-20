module ImmosquareCleaner
  module Processors
    class Yaml < Base

      def self.match?(file_path)
        file_path =~ %r{locales/.*\.yml$}
      end

      def run
        ImmosquareYaml.clean(file_path)
      end

    end
  end
end
