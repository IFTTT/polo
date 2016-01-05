require 'active_record'
require 'json'
require 'polo/translator_base'

module Polo
  class JsonTranslator < TranslatorBase
    def translation
      data = @records.map do |record|
        {
          table: record.class.table_name,
          attributes: record.attributes
        }
      end
      if @configuration.should_pretty_print
        JSON.pretty_generate data
      else
        data.to_json
      end
    end
  end
end
