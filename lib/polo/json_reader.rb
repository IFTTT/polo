require 'active_record'
require 'json'
require 'polo/reader_base'

module Polo
  class JsonReader < ReaderBase
    def read
      tables = active_record_tables
      data = JSON.parse(@serialized)
      data.map do |record|
        klass = tables[record['table']]
        if klass
          p_key = klass.primary_key
          record_instance = klass.new(record['attributes'])
          record_instance[p_key] = record['attributes'][p_key]
          record_instance
        end
      end
    end

    private

    def active_record_tables
      Hash[ActiveRecord::Base.descendants.collect { |c| [c.table_name, c] }]
    end
  end
end
