module Polo
  module Adapters
    class MySQL
      def on_duplicate_key_update(inserts, records)
        insert_and_record = inserts.zip(records)
        insert_and_record.map do |insert, record|
          values_syntax = record.attributes.keys.map do |key|
            "`#{key}` = VALUES(`#{key}`)"
          end

          on_dup_syntax = "ON DUPLICATE KEY UPDATE #{values_syntax.join(', ')}"

          "#{insert} #{on_dup_syntax}"
        end
      end

      def ignore_transform(inserts, records)
        inserts.map do |insert|
          insert.gsub("INSERT", "INSERT IGNORE")
        end
      end
    end
  end
end