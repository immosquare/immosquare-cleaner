module ImmosquareCleaner
  class Configuration

    attr_accessor(:rubocop_options, :htmlbeautifier_options, :erblint_options, :exclude_files)
    attr_reader :ruby_target_version

    def initialize
      @rubocop_options        = nil
      @ruby_target_version    = nil
      @htmlbeautifier_options = nil
      @erblint_options        = nil
      @exclude_files          = []
    end

    def ruby_target_version=(version)
      @ruby_target_version = version.nil? ? nil : RubyTarget.normalize(version)
    end

  end
end
