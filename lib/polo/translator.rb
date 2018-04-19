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
      SqlTranslator.new(instances, @configuration).to_sql
    end

    def instances
      active_record_instances = @selects.flat_map do |select|
        select[:klass].find_by_sql(select[:sql]).to_a
      end

      if (fields = @configuration.blacklist) && !fields.empty?
        active_record_instances = active_record_instances.map { |instance| obfuscate!(instance, fields) }
      end

      active_record_instances
    end

    private

    def obfuscate!(instance, fields)
      instance if intersection(instance.attributes.keys, fields).empty?

      fields.each do |field, strategy|
        field = field.to_s

        if table = table_name(field)
          field = field_name(field)
        end

        correct_table = table.nil? || instance.class.table_name == table

        if correct_table && instance.attributes[field]
          instance.send("#{field}=", new_field_value(field, strategy, instance))
        end
      end

      instance
    end

    def field_name(field)
      field.to_s.include?('.') ? field.split('.').last : field.to_s
    end

    def table_name(field)
      field.to_s.include?('.') ? field.split('.').first : nil
    end

    def intersection(attrs, fields)
      attrs & fields.map { |pair| field_name(pair.first) }
    end

    def new_field_value(field, strategy, instance)
      value = instance.attributes[field]
      if strategy.nil?
        value.split("").shuffle.join
      else
        strategy.arity == 1 ? strategy.call(value) : strategy.call(value, instance)
      end
    end
  end
end
