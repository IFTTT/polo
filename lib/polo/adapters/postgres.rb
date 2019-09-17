module Polo
  module Adapters
    class Postgres
      def on_duplicate_key_update(inserts, records)
        @pg_version ||= ActiveRecord::Base.connection.select_value('SELECT version()')[/PostgreSQL ([\d\.]+)/, 1]

        insert_and_record = inserts.zip(records)
        insert_and_record.map do |insert, record|
          if @pg_version < '9.5.0'
            naive_update_insert(insert, record)
          else
            add_upsert_to_insert(insert, record)
          end
        end
      end

      def add_upsert_to_insert(insert, record)
        if record.is_a?(Hash)
          return naive_update_insert(insert, record)
        end

        attrs = record.is_a?(Hash) ? record.fetch(:values) : record.attributes.slice(*record.class.column_names)
        values_syntax = attrs.keys.reject { |key| key.to_s == 'id' }.map do |key|
          %{"#{key}" = EXCLUDED."#{key}"}
        end

        # Conflict on id column
        on_dup_syntax = "ON CONFLICT (#{record.class.primary_key}) DO UPDATE SET #{values_syntax.join(', ')}"

        "#{insert} #{on_dup_syntax}"
      end

      def naive_update_insert(insert, record)
        table_name, id = table_name_and_key_for(record)

        attrs = record.is_a?(Hash) ? record.fetch(:values) : record.attributes_before_type_cast.slice(*record.class.column_names)
        updates = attrs.except('id').map do |key, value|
          column = ActiveRecord::Base.connection.send(:quote_column_name, key)

          ActiveRecord::Base.send(:sanitize_sql_array, ["#{column} = ?", value])
        end
        condition = if id.blank?
                      record[:values].map { |k, v|
                        column = ActiveRecord::Base.connection.send(:quote_column_name, k)
                        ActiveRecord::Base.send(:sanitize_sql_array, ["#{column} = ?", v])
                      }.join(' and ')
                    else
                      "id = #{id}"
                    end

        "do $$
          begin
            #{insert};
            exception when unique_violation then
            update #{table_name} set #{updates.join(', ')} where #{condition};
            end $$;"
      end

      # Internal: Transforms an INSERT with PostgreSQL-specific syntax. Ignores
      #           records that already exist in the table. To do this, it uses
      #           a heuristic, i.e. checks if there is a record with the same id
      #           in the table.
      #           See: http://stackoverflow.com/a/6527838/32816
      #
      # inserts - The Array of INSERT statements.
      # records - The Array of Arel objects.
      #
      # Returns the Array of transformed INSERT statements.
      def ignore_transform(inserts, records)
        insert_and_record = inserts.zip(records)
        insert_and_record.map do |insert, record|
          table_name, id = table_name_and_key_for(record)
          insert = insert.gsub(/VALUES \((.+)\)$/m, 'SELECT \\1')
          insert << " WHERE NOT EXISTS (SELECT 1 FROM #{table_name} WHERE id=#{id});"
        end
      end

      def table_name_and_key_for(record)
        if record.is_a?(Hash)
          id = record.fetch(:values)[:id]
          table_name = record.fetch(:table_name)
        else
          id = record[:id]
          table_name = record.class.arel_table.name
        end
        [table_name, id]
      end
    end
  end
end
