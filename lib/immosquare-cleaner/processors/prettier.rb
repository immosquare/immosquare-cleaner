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
        ##============================================================##
        ## Prettier flags:
        ## --no-color : strip ANSI escape codes — VS Code Output panel
        ##              renders them as raw `ESC` characters
        ## --write    : format the file in place
        ## --config   : pin the shared config shipped with the gem
        ##============================================================##
        cmds = ["bun prettier --no-color --write #{Shellwords.escape(file_path)} --config #{ImmosquareCleaner.gem_root}/linters/prettier.yml"]
        launch_cmds(cmds)
      end

    end
  end
end
