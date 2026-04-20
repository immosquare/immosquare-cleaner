module ImmosquareCleaner
  module Processors
    class Ruby < Base

      ##============================================================##
      ## RUBY_FILES contains common Ruby-related file extensions and
      ## filenames used in Rails and Ruby development.
      ##============================================================##
      RUBY_FILES = [
        ".rb",
        ".rake",
        ".axlsx",
        ".gemspec",
        ".cap",
        ".ru",
        ".podspec",
        ".jbuilder",
        ".rabl",
        ".thor",
        "Berksfile",
        "Brewfile",
        "Capfile",
        "Gemfile",
        "Guardfile",
        "Podfile",
        "Rakefile",
        "Thorfile",
        "Vagrantfile"
      ].freeze

      SHEBANG = "#!/usr/bin/env ruby".freeze

      def self.match?(file_path)
        file_path.end_with?(*RUBY_FILES) ||
          (File.exist?(file_path) && File.open(file_path, &:gets)&.include?(SHEBANG))
      end

      def run
        rubocop_options = ImmosquareCleaner.configuration.rubocop_options || "--autocorrect-all --no-parallel"
        config_path     = "#{ImmosquareCleaner.gem_root}/linters/rubocop-#{RUBY_VERSION}.yml"

        cmds = ["bundle exec rubocop -c #{config_path} \"#{file_path}\" #{rubocop_options}"]
        launch_cmds(cmds)
        normalize_last_line
      end

    end
  end
end
