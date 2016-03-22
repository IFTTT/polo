require 'active_record'
require 'polo/configuration'
require 'polo/translator_base'

module Polo
  class SqlTranslator < TranslatorBase
    def translation
      sqls = @records.map do |record|
        raw_sql(record)
      end

      if @configuration.on_duplicate_strategy == :ignore
        sqls = ignore_transform(sqls)
      end

      if @configuration.on_duplicate_strategy == :override
        sqls = on_duplicate_key_update(sqls, @records)
      end

      sqls.uniq
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

    # Internal: Generates an insert SQL statement for a given record
    #
    # It will make use of the InsertManager class from the Arel gem to generate
    # insert statements
    #
    def raw_sql(record)
      record.class.arel_table.create_insert.tap do |insert_manager|
        insert_manager.insert(insert_values(record))
      end.to_sql
    end

    # Internal: Returns an object's attribute definitions along with
    # their set values (for Rails 3.x).
    #
    module ActiveRecordLessThanFour
      def insert_values(record)
        record.send(:arel_attributes_values)
      end
    end

    # Internal: Returns an object's attribute definitions along with
    # their set values (for Rails >= 4.x).
    #
    # From Rails 4.2 onwards, for some reason attributes with custom serializers
    # wouldn't be properly serialized automatically. That's why explict
    # 'type_cast' call are necessary.
    #
    module ActiveRecordFourOrGreater
      def insert_values(record)
        connection = ActiveRecord::Base.connection
        values = record.send(:arel_attributes_with_values_for_create, record.attribute_names)
        values.each do |attribute, value|
          column = record.send(:column_for_attribute, attribute.name)
          values[attribute] = connection.type_cast(value, column)
        end
      end
    end

    if ActiveRecord::VERSION::MAJOR < 4
      include ActiveRecordLessThanFour
    else
      include ActiveRecordFourOrGreater
    end
  end
end
