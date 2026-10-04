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

      ##============================================================##
      ## Extensions Prettier formats out of the box. Used by the
      ## directory clean to decide which fallback files to send;
      ## a single-file clean still falls back for any extension
      ##============================================================##
      EXTENSIONS = [
        ".css",
        ".graphql",
        ".gql",
        ".handlebars",
        ".hbs",
        ".less",
        ".scss",
        ".vue",
        ".yaml",
        ".yml"
      ].freeze

      def run
        return if erb_templated_yaml?

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

      private

      ##============================================================##
      ## A YAML file holding ERB tags (Rails' database.yml, cable.yml…)
      ## is a template, not YAML. Prettier's YAML parser reads the Ruby
      ## inside the tags as YAML syntax: `a ? :ci : :personal` becomes
      ## `a ? :ci: :personal`, and a ternary in a value aborts with
      ## "Nested mappings are not allowed". Such files are left as is.
      ##============================================================##
      def erb_templated_yaml?
        file_path.end_with?(".yml", ".yaml") && File.read(file_path).include?("<%")
      end

    end
  end
end
