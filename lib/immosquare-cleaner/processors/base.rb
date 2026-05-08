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
        ##============================================================##
        ## Use Process.spawn's :chdir option instead of Dir.chdir to
        ## set the child process's working directory. Dir.chdir is
        ## process-global and not thread-safe — running multiple
        ## chdir blocks concurrently raises "conflicting chdir during
        ## another chdir block", which breaks the parallel rake task.
        ##============================================================##
        cmds.each {|cmd| system(cmd, :chdir => ImmosquareCleaner.gem_root) }
      end

      def normalize_last_line(path = file_path)
        File.normalize_last_line(path)
      end
    end
  end
end
