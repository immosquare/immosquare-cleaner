module ImmosquareCleaner
  class Configuration

    attr_accessor :rubocop_options, :htmlbeautifier_options, :erblint_options, :exclude_files

    def initialize
      @rubocop_options        = nil
      @htmlbeautifier_options = nil
      @erblint_options        = nil
      @exclude_files          = []
    end




  end
end
