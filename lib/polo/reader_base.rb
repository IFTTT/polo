require 'polo/configuration'

module Polo
  class ReaderBase

    def initialize(serialized, configuration=Configuration.new)
      @serialized = serialized
      @configuration = configuration
    end

    def read
      raise NotImplementedError
    end
  end
end