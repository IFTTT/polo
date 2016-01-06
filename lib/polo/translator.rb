require "polo/configuration"

module Polo
  class Translator

    # Public: Creates a new Polo::Collector
    #
    # selects - An array of SELECT queries
    #
    def self.with_selects(selects, configuration=Configuration.new)
      new(selects, nil, configuration)
    end

    def self.with_reads(reads, configuration=Configuration.new)
      new(nil, reads, configuration)
    end

    def initialize(selects, reads, configuration=Configuration.new)
      @selects = selects
      @reads = reads
      @configuration = configuration
    end

    # Public: Translates SELECT queries into INSERTS.
    #
    def translate
      if @configuration.translator
        @configuration.translator.new(instances, @configuration).translation
      else
        instances
      end
    end

    def instances
      records = @reads ? @reads : @selects.flat_map { |select| select[:klass].find_by_sql(select[:sql]).to_a }

      if fields = @configuration.blacklist
        obfuscate!(records, fields)
      end

      records
    end

    private

    def obfuscate!(instances, fields)
      instances.each do |instance|
        next if intersection(instance.attributes.keys, fields).empty?

        fields.each do |field, strategy|
          field = field.to_s

          if table = table_name(field)
            field = field_name(field)
          end

          correct_table = table.nil? || instance.class.table_name == table

          if correct_table && value = instance.attributes[field]
            instance.send("#{field}=", new_field_value(field, strategy, value))
          end
        end
      end
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

    def new_field_value(field, strategy, value)
      if strategy.nil?
        value.split("").shuffle.join
      else
        strategy.call(value)
      end
    end
  end
end
