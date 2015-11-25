require 'active_record'
require 'polo/configuration'

module Polo
  class SqlTranslator

    def initialize(object, configuration=Configuration.new)
      @record = object
      @configuration = configuration
    end

    def to_sql
      records = Array.wrap(@record)

      sqls = records.map do |record|
        raw_sql(record)
      end

      if @configuration.on_duplicate_strategy == :ignore
        sqls = ignore_transform(sqls)
      end

      if @configuration.on_duplicate_strategy == :override
        sqls = on_duplicate_key_update(sqls, records)
      end

      sqls
    end

    private

    def on_duplicate_key_update(sqls, records)
      insert_and_record = sqls.zip(records)
      insert_and_record.map do |insert, record|
        values_syntax = record.attributes.keys.map do |key|
          "#{key} = VALUES(#{key})"
        end

        on_dup_syntax = "ON DUPLICATE KEY UPDATE #{values_syntax.join(', ')}"

        "#{insert} #{on_dup_syntax}"
      end
    end

    def ignore_transform(inserts)
      inserts.map do |insert|
        insert.gsub("INSERT", "INSERT IGNORE")
      end
    end

    def raw_sql(record)
      connection = ActiveRecord::Base.connection
      attributes = record.attributes

      keys = []
      values = []
      attributes.each_pair do |key, value|
        column = record.column_for_attribute(key)

        next unless column

        keys << connection.quote_column_name(key)
        values << connection.quote(cast_attribute(record, column, value))
      end

      quoted_table_name = connection.quote_table_name record.class.table_name

      "INSERT INTO #{quoted_table_name} (#{keys.join(', ')}) VALUES (#{values.join(', ')})"
    end

    module ActiveRecordLessThanFourPointTwo
      def cast_attribute(record, column, value)
        attribute = record.send(:type_cast_attribute_for_write, column, value)

        if record.class.serialized_attributes.include?(column.name)
          attribute.serialize
        else
          attribute
        end
      end
    end

    module ActiveRecordFourPointTwoOrGreater
      def cast_attribute(record, column, value)
        column.type_cast_for_database(value)
      end
    end

    if ActiveRecord::VERSION::STRING.start_with?('3.2') ||
        ActiveRecord::VERSION::STRING.start_with?('4.0') ||
        ActiveRecord::VERSION::STRING.start_with?('4.1')
      include ActiveRecordLessThanFourPointTwo
    else
      include ActiveRecordFourPointTwoOrGreater
    end
  end
end
