module Polo

  class Configuration
    attr_reader :on_duplicate_strategy, :blacklist

    def initialize(options={})
      options = { on_duplicate: nil, obfuscate: {} }.merge(options)
      @on_duplicate_strategy = options[:on_duplicate]
      @blacklist = options[:obfuscate]
    end

    def obfuscate(*fields)
      @blacklist = fields
    end

    def on_duplicate(strategy)
      @on_duplicate_strategy = strategy
    end
  end
end
