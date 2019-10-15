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
        if record.is_a?(Hash)
          raw_sql_from_hash(record)
        else
          raw_sql_from_record(record)
        end
      end
    end

    private

    # Internal: Generates an insert SQL statement for a given record
    #
    # It will make use of the InsertManager class from the Arel gem to generate
    # insert statements
    #
    def raw_sql_from_record(record)
      record.class.arel_table.create_insert.tap do |insert_manager|
        insert_manager.insert(insert_values(record))
      end.to_sql
    end

    # Internal: Generates an insert SQL statement from a hash of values
    def raw_sql_from_hash(hash)
      connection = ActiveRecord::Base.connection
      attributes = hash.fetch(:values)
      table_name = connection.quote_table_name(hash.fetch(:table_name))
      columns = attributes.keys.map{|k| connection.quote_column_name(k)}.join(", ")
      value_placeholders = attributes.values.map{|v| "?" }.join(", ")
      ActiveRecord::Base.send(:sanitize_sql_array, ["INSERT INTO #{table_name} (#{columns}) VALUES (#{value_placeholders})", *attributes.values])
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
    # their set values (for Rails 5.0 & 5.1).
    #
    # Serializers have changed again in rails 5.
    # We now use the type_caster from the arel_table.
    #
    module ActiveRecordFivePointZeroOrOne
      # Based on the codepath used in Rails 5
      def raw_sql_from_record(record)
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

    # Internal: Returns an object's attribute definitions along with
    # their set values (for Rails >= 5.2).
    module ActiveRecordFive
      def raw_sql_from_record(record)
        values = record.send(:attributes_with_values_for_create, record.class.column_names)
        model = record.class
        substitutes_and_binds = model.send(:_substitute_values, values)

        insert_manager = model.arel_table.create_insert
        insert_manager.insert substitutes_and_binds

        model.connection.unprepared_statement do
          model.connection.to_sql(insert_manager)
        end
      end
    end

    # Internal: Returns an object's attribute definitions along with
    # their set values (for Rails 6.0).
    module ActiveRecordSix
      def raw_sql_from_record(record)
        values = record.send(:attributes_with_values, record.class.column_names)
        model = record.class
        substitutes_and_binds = model.send(:_substitute_values, values)

        insert_manager = model.arel_table.create_insert
        insert_manager.insert substitutes_and_binds

        model.connection.unprepared_statement do
          model.connection.to_sql(insert_manager)
        end
      end
    end

    if ActiveRecord::VERSION::MAJOR < 4
      include ActiveRecordLessThanFour
    elsif ActiveRecord::VERSION::MAJOR == 4
      include ActiveRecordFour
    elsif ActiveRecord::VERSION::MAJOR == 5 && ActiveRecord::VERSION::MINOR < 2
      prepend ActiveRecordFivePointZeroOrOne
    elsif ActiveRecord::VERSION::MAJOR == 5
      prepend ActiveRecordFive
    else
      prepend ActiveRecordSix
    end
  end
end
