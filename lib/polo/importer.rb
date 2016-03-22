require "polo/sql_translator"
require "polo/configuration"

module Polo
  class Importer

    # Public: Creates a new Polo::Collector
    #
    # selects - An array of SELECT queries
    #
    def initialize(serialized, configuration=Configuration.new)
      @serialized = serialized
      @configuration = configuration
    end

    # Public: Translates SELECT queries into INSERTS.
    #
    def read
      if @configuration.reader
        @configuration.reader.new(@serialized, @configuration).read.uniq
      else
        @serialized.uniq
      end
    end
  end
end
