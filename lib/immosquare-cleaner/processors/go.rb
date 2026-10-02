require "shellwords"

module ImmosquareCleaner
  module Processors
    class Go < Base

      def self.match?(file_path)
        file_path.end_with?(".go")
      end

      def run
        if !system("which gofmt > /dev/null 2>&1")
          warn("ERROR: gofmt is not installed. Please install Go with: brew install go")
          return
        end

        ##============================================================##
        ## gofmt flags:
        ## -s : apply gofmt's simplifications (redundant composite
        ##      literal types, `s[a:len(s)]` → `s[a:]`...)
        ## -w : write the result back to the file in place
        ## Indentation stays in tabs: gofmt has no option for it, and
        ## converting to spaces would make every Go tool (gopls,
        ## `gofmt -l` in CI) flag the file as unformatted.
        ##============================================================##
        launch_cmds(["gofmt -s -w #{Shellwords.escape(file_path)}"])
      end

    end
  end
end
