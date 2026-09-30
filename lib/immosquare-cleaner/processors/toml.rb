require "shellwords"

module ImmosquareCleaner
  module Processors
    class Toml < Base

      def self.match?(file_path)
        file_path.end_with?(".toml")
      end

      def run
        if !system("which taplo > /dev/null 2>&1")
          warn("ERROR: taplo is not installed. Please install it with: brew install taplo")
          return
        end

        ##============================================================##
        ## RUST_LOG=warn : taplo logs its file discovery at INFO level
        ##                 on every run; syntax errors stay visible
        ## taplo flags:
        ## --no-auto-config         : taplo looks for .taplo.toml in the
        ##                            working directory, which is the gem
        ##                            root here, not the edited project
        ## -o align_entries=true    : align the `=` of consecutive keys
        ##                            like the other immosquare linters
        ## -o indent_string="  "    : 2-space indent for nested arrays
        ## -o column_width=10000    : never wrap, same as prettier.yml
        ## -o array_auto_collapse=false : keep multi-line arrays as
        ##                            written (workspace members...)
        ##============================================================##
        options = ["align_entries=true", "indent_string=  ", "column_width=10000", "array_auto_collapse=false"].map {|option| "-o #{Shellwords.escape(option)}" }.join(" ")
        launch_cmds(["RUST_LOG=warn taplo fmt --no-auto-config --colors never #{options} #{Shellwords.escape(file_path)}"])
      end

    end
  end
end
