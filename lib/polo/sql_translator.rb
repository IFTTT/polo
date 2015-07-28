module Polo
  class SqlTranslator

    def initialize(object, options={})
      @record = object
      @options = options
    end

    def to_sql
      records = Array.wrap(@record)

      sqls = records.map do |record|
        raw_sql(record)
      end

      if @options[:ignore_duplicate_rows]

        sqls.map! do |sql|
          sql.gsub("INSERT", "INSERT IGNORE")
        end
      end

      sqls
    end

    private

    def raw_sql(record)
      connection = ActiveRecord::Base.connection
      attributes = record.attributes

      keys = attributes.keys.map do |key|
        "`#{key}`"
      end

      values = attributes.values.map do |value|
        connection.quote(value)
      end

      "INSERT INTO `#{record.class.table_name}` (#{keys.join(', ')}) VALUES (#{values.join(', ')})"
    end
  end
end

