module ImmosquareCleaner
  module Processors
    class Base

      def self.run(file_path, origin_path = nil)
        new(file_path, origin_path).run
      end

      ##============================================================##
      ## origin_path : location of the file in its project, used to
      ##               look up project config (Cargo.toml...). Differs
      ##               from file_path when a /tmp copy is cleaned (-p)
      ##============================================================##
      attr_reader :file_path, :origin_path

      def initialize(file_path, origin_path = nil)
        @file_path   = file_path
        @origin_path = origin_path || file_path
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
