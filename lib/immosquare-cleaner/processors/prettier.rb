require "shellwords"

module ImmosquareCleaner
  module Processors
    ##============================================================##
    ## Fallback processor — used by ImmosquareCleaner.processor_for
    ## when no other processor matches. It intentionally has no
    ## `.match?` method: the fallback selection is explicit in the
    ## caller, not part of the scan.
    ##============================================================##
    class Prettier < Base

      def run
        cmds = ["bun prettier --write #{Shellwords.escape(file_path)} --config #{ImmosquareCleaner.gem_root}/linters/prettier.yml"]
        launch_cmds(cmds)
      end

    end
  end
end
