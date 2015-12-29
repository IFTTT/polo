require 'active_record'
require 'json'
require 'polo/translator_base'

module Polo
  class JsonTranslator < TranslatorBase
    def translation
      @records.map do |record|
        {
          table: record.class.table_name,
          attributes: record.attributes
        }
      end.to_json
    end
  end
end
