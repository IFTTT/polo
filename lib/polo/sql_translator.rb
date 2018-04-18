require 'active_record'
require 'polo/configuration'
require 'polo/adapters/mysql'
require 'polo/adapters/postgres'

module Polo
  class SqlTranslator

    def initialize(object, configuration = Configuration.new)
      @record = object
      @configuration = configuration

      case @configuration.adapter
      when :mysql
        @adapter = Polo::Adapters::MySQL.new
      when :postgres
        @adapter = Polo::Adapters::Postgres.new
      else
        raise "Unknown SQL adapter: #{@configuration.adapter}"
      end
    end

    def to_sql
      case @configuration.on_duplicate_strategy
      when :ignore
        @adapter.ignore_transform(inserts, records)
      when :override
        @adapter.on_duplicate_key_update(inserts, records)
      else inserts
      end
    end

    def records
      Array.wrap(@record)
    end

    def inserts
      records.map do |record|
        raw_sql(record)
      end
    end

    private

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
    module ActiveRecordFour
      def insert_values(record)
        connection = ActiveRecord::Base.connection
        values = record.send(:arel_attributes_with_values_for_create, connection.schema_cache.columns(record.class.table_name).map(&:name))
        values.each do |attribute, value|
          column = record.send(:column_for_attribute, attribute.name)
          values[attribute] = connection.type_cast(value, column)
        end
      end
    end

    # Internal: Returns an object's attribute definitions along with
    # their set values (for Rails >= 5.x).
    #
    # Serializers have changed again in rails 5.
    # We now use the type_caster from the arel_table.
    #
    module ActiveRecordFive
      # Based on the codepath used in Rails 5
      def raw_sql(record)
        values = record.send(:arel_attributes_with_values_for_create, record.class.column_names)
        model = record.class
        substitutes, binds = model.unscoped.substitute_values(values)

        insert_manager = model.arel_table.create_insert
        insert_manager.insert substitutes

        model.connection.unprepared_statement do
          model.connection.to_sql(insert_manager, binds)
        end
      end
    end

    if ActiveRecord::VERSION::MAJOR < 4
      include ActiveRecordLessThanFour
    elsif ActiveRecord::VERSION::MAJOR == 4
      include ActiveRecordFour
    else
      prepend ActiveRecordFive
    end
  end
end
