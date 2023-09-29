module ImmosquareCleaner
  class Configuration

    attr_accessor :rubocop_options, :htmlbeautifier_options, :erblint_options

    def initialize
      @rubocop_options        = nil
      @htmlbeautifier_options = nil
      @erblint_options        = nil
    end

    


  end
end

