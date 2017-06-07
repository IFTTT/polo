module Polo
  module Adapters
    class Postgres
      # TODO: Implement UPSERT. This command became available in 9.1.
      #
      # See: http://www.the-art-of-web.com/sql/upsert/
      def on_duplicate_key_update(inserts, records)
        raise 'on_duplicate: :override is not currently supported in the PostgreSQL adapter'
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
          table_name = record.class.arel_table.name
          id = record[:id]
          insert = insert.gsub(/VALUES \((.+)\)$/m, 'SELECT \\1')
          insert << " WHERE NOT EXISTS (SELECT 1 FROM #{table_name} WHERE id=#{id});"
        end
      end
    end
  end
end
