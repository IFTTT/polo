require "polo/version"
require "polo/collector"
require "polo/translator"

module Polo

  def self.explore(base_class, id, dependencies={})
    selects = Collector.new(base_class, id, dependencies).collect
    Translator.new(selects).translate
  end
end
