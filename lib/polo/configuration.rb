module Polo

  class Configuration
    attr_reader :on_duplicate_strategy, :blacklist

    def initialize(options={})
      options = { on_duplicate: nil, obfuscate: {} }.merge(options)
      @on_duplicate_strategy = options[:on_duplicate]
      obfuscate(options[:obfuscate])
    end

    # TODO: document this
    # This normalizes an array or hash of fields to a hash of
    # { field_name => strategy }
    def obfuscate(*fields)
      if fields.is_a?(Array)
        fields = fields.flatten
      end

      fields_and_strategies = {}

      fields.each do |field|
        if field.is_a?(Symbol) || field.is_a?(String)
          fields_and_strategies[field] = nil
        elsif field.is_a?(Hash)
          fields_and_strategies = fields_and_strategies.merge(field)
        end
      end

      @blacklist = fields_and_strategies
    end

    def on_duplicate(strategy)
      @on_duplicate_strategy = strategy
    end
  end
end
