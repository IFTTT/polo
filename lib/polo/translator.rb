require "polo/sql_translator"
require "polo/configuration"

module Polo
  class Translator

    # Public: Creates a new Polo::Collector
    #
    # selects - An array of SELECT queries
    #
    def initialize(selects, configuration=Configuration.new)
      @selects = selects
      @configuration = configuration
    end

    # Public: Translates SELECT queries into INSERTS.
    #
    def translate
      SqlTranslator.new(instances, @configuration).to_sql.uniq
    end

    def instances
      active_record_instances = @selects.flat_map do |select|
        select[:klass].find_by_sql(select[:sql]).to_a
      end

      if fields = @configuration.blacklist
        obfuscate!(active_record_instances, fields)
      end

      active_record_instances
    end

    private

    def obfuscate!(instances, fields)
      instances.each do |instance|
        next if intersection(instance.attributes.keys, fields).empty?
        fields.each do |field, strategy|
          value = instance.attributes[field.to_s] || ''
          instance.send("#{field}=", new_field_value(field, strategy, value))
        end
      end
    end

    def intersection(attrs, fields)
      attrs & fields.to_a.flatten.map(&:to_s)
    end

    def new_field_value(field, strategy, value)
      if strategy.nil?
        value.split("").shuffle.join
      else
        strategy.call(value)
      end
    end
  end
end
