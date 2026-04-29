require "shellwords"

module ImmosquareCleaner
  module Processors
    class Shell < Base

      EXTENSIONS = [
        ".sh",
        "bash",
        "bash_profile",
        "bashrc",
        "zprofile",
        "zsh",
        "zshrc"
      ].freeze

      def self.match?(file_path)
        file_path.end_with?(*EXTENSIONS)
      end

      def run
        if system("which shfmt > /dev/null 2>&1")
          cmds = ["shfmt -i 2 -w #{Shellwords.escape(file_path)}"]
          launch_cmds(cmds)
          normalize_last_line
        else
          warn("ERROR: shfmt is not installed. Please install it with: brew install shfmt")
        end
      end

    end
  end
end
