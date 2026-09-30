require "open3"

module ImmosquareCleaner
  module Processors
    class Rust < Base

      DEFAULT_EDITION    = "2024".freeze
      EDITION_REGEX      = /^\s*edition\s*=\s*["'](\d{4})["']/
      CONFIG_FILES       = [".rustfmt.toml", "rustfmt.toml"].freeze
      GLOBAL_CONFIG_DIRS = [
        Dir.home,
        File.join(ENV.fetch("XDG_CONFIG_HOME", File.join(Dir.home, ".config")), "rustfmt"),
        File.join(Dir.home, "Library", "Application Support", "rustfmt")
      ].freeze

      def self.match?(file_path)
        file_path.end_with?(".rs")
      end

      def run
        if !system("which rustfmt > /dev/null 2>&1")
          warn("ERROR: rustfmt is not installed. Please install it with: rustup component add rustfmt")
          return
        end

        ##============================================================##
        ## The file goes through stdin: given a path, rustfmt also
        ## rewrites every child module declared with `mod foo;`
        ## (skip_children is nightly only). In stdin mode rustfmt
        ## looks for its config from the cwd, so it is passed
        ## explicitly.
        ## --edition     : standalone rustfmt parses as edition 2015
        ##                 and rejects `async fn` & co
        ## --config-path : the project or global rustfmt.toml
        ## --config      : immosquare default (2-space indent), only
        ##                 when no rustfmt.toml exists — it would
        ##                 override the file's values
        ##============================================================##
        config = rustfmt_config
        cmd    = ["rustfmt", "--edition", edition, "--emit", "stdout"]
        cmd   += config ? ["--config-path", config] : ["--config", "tab_spaces=2"]
        output, status = Open3.capture2(*cmd, :stdin_data => File.read(file_path), :chdir => ImmosquareCleaner.gem_root)
        File.write(file_path, output) if status.success?
      end

      private

      ##============================================================##
      ## A workspace member usually declares `edition.workspace = true`
      ## (not matched by EDITION_REGEX): the lookup keeps going up to
      ## the workspace root, which declares it in [workspace.package]
      ##============================================================##
      def edition
        ancestor_dirs.each do |dir|
          cargo_toml = File.join(dir, "Cargo.toml")
          next if !File.file?(cargo_toml)

          found = File.read(cargo_toml)[EDITION_REGEX, 1]
          return found if found
        end
        DEFAULT_EDITION
      end

      ##============================================================##
      ## Same lookup order as rustfmt: closest directory first, then
      ## the user's global config
      ##============================================================##
      def rustfmt_config
        (ancestor_dirs + GLOBAL_CONFIG_DIRS).product(CONFIG_FILES).map {|dir, name| File.join(dir, name) }.find {|path| File.file?(path) }
      end

      def ancestor_dirs
        dirs = [File.dirname(File.expand_path(origin_path))]
        dirs << File.dirname(dirs.last) while File.dirname(dirs.last) != dirs.last
        dirs
      end

    end
  end
end
