module ImmosquareCleaner
  class RubyTarget

    MUTEX                     = Mutex.new
    GEMSPEC_REQUIREMENT_REGEX = /required_ruby_version\s*=\s*(?:Gem::Requirement\.new\()?\s*(\[[^\]]*\]|"[^"]*"|'[^']*')/
    RUBY_VERSION_FILE_REGEX   = /\A(?:ruby-)?(\d+\.\d+)/
    LOWER_BOUND_OPERATORS     = [">=", ">", "~>", "="].freeze
    PROJECT_MARKERS           = ["Gemfile", ".git"].freeze

    class << self

      ##============================================================##
      ## RuboCop targets Ruby releases rather than patch versions.
      ## Explicit targets must be supported by the installed RuboCop.
      ##============================================================##
      def normalize(version)
        value = version.to_s
        raise(ArgumentError, "ruby_target_version must be a Ruby version such as 3.2 or 3.2.6") if !value.match?(/\A\d+\.\d+(?:\.\d+)?\z/)

        target = release(value)
        validate!(target)
        target
      end

      def release(version)
        Gem::Version.new(version).segments.first(2).join(".")
      end

      ##============================================================##
      ## Target of the project that owns the file: the gemspec minimum
      ## (a gem must keep working on the oldest Ruby it accepts), then
      ## .ruby-version, then the running Ruby. The lookup stops at the
      ## project root so a parent folder's .ruby-version never applies.
      ## Autocorrect with a newer target can introduce syntax that the
      ## project's Ruby rejects (`_1` rewritten to `it`, Ruby 3.4+).
      ##============================================================##
      def detect(path)
        directory = File.dirname(File.expand_path(path))
        MUTEX.synchronize do
          @detected ||= {}
          @detected[directory] ||= supported_target(declared_version(directory)) || release(RUBY_VERSION)
        end
      end

      private

      def declared_version(directory)
        loop do
          gemspecs = Dir.glob("*.gemspec", :base => directory).sort
          version  = gemspec_minimum(directory, gemspecs) || ruby_version_file(directory)
          return release(version) if version
          return nil if gemspecs.any? || PROJECT_MARKERS.any? {|marker| File.exist?(File.join(directory, marker)) }

          parent = File.dirname(directory)
          return nil if parent == directory

          directory = parent
        end
      end

      def gemspec_minimum(directory, gemspecs)
        gemspecs.each do |name|
          declaration = File.read(File.join(directory, name))[GEMSPEC_REQUIREMENT_REGEX, 1]
          next if declaration.nil?

          requirement = Gem::Requirement.new(*declaration.scan(/["']([^"']+)["']/).flatten)
          bounds      = requirement.requirements.filter_map {|operator, version| version if LOWER_BOUND_OPERATORS.include?(operator) }
          return bounds.max.to_s if bounds.any?
        rescue Gem::Requirement::BadRequirementError
          next
        end
        nil
      end

      def ruby_version_file(directory)
        path = File.join(directory, ".ruby-version")
        File.file?(path) ? File.read(path).strip[RUBY_VERSION_FILE_REGEX, 1] : nil
      end

      ##============================================================##
      ## A declared version the installed RuboCop cannot target falls
      ## back to the running Ruby: cleaning must never stop on it.
      ##============================================================##
      def supported_target(target)
        return nil if target.nil?
        return target if target == release(RUBY_VERSION)

        validate!(target)
        target
      rescue ArgumentError => e
        warn("immosquare-cleaner: #{e.message}; using Ruby #{release(RUBY_VERSION)}")
        nil
      end

      def validate!(target)
        require "rubocop"

        config = RuboCop::Config.new({"AllCops" => {"TargetRubyVersion" => target}}, __FILE__)
        raise(ArgumentError, "ruby_target_version #{target.inspect} does not match RuboCop's effective target #{config.target_ruby_version}") if config.target_ruby_version.to_s != target

        config.validate_after_resolution
      rescue RuboCop::ValidationError => e
        raise(ArgumentError, "Invalid ruby_target_version #{target.inspect}: #{e.message}")
      end

    end

  end
end
