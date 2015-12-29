require 'polo/configuration'

module Polo
  class TranslatorBase

    def initialize(object, configuration=Configuration.new)
      @record = object
      @records = Array.wrap(@record)
      @configuration = configuration
    end

    def translation
      raise NotImplementedError
    end
  end
end