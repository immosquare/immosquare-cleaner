module ImmosquareCleaner
  class Configuration

    attr_accessor :htmlbeautifier_options, :rubocop_options

    def initialize
      @htmlbeautifier_options = nil
      @rubocop_options        = nil
    end

    


  end
end