require "polo/sql_translator"

module Polo
  class Translator

    # Public: Creates a new Polo::Collector
    #
    # selects - An array of SELECT queries
    #
    def initialize(selects, options={})
      @selects = selects
      @options = options
    end

    # Public: Translates SELECT queries into INSERTS.
    #
    def translate
      active_record_instances = @selects.flat_map do |select|
        select[:klass].find_by_sql(select[:sql]).to_a
      end

      SqlTranslator.new(active_record_instances, @options).to_sql.uniq
    end
  end
end
