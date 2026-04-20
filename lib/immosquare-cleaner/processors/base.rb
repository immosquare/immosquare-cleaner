module ImmosquareCleaner
  module Processors
    class Base
      def self.run(file_path)
        new(file_path).run
      end

      attr_reader :file_path

      def initialize(file_path)
        @file_path = file_path
      end

      def run
        raise NotImplementedError
      end

      private

      def launch_cmds(cmds)
        Dir.chdir(ImmosquareCleaner.gem_root) do
          cmds.each {|cmd| system(cmd) }
        end
      end

      def normalize_last_line(path = file_path)
        File.normalize_last_line(path)
      end
    end
  end
end
