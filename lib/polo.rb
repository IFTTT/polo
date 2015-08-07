require "polo/version"
require "polo/collector"
require "polo/translator"

module Polo

  class Traveler

    def self.collect(base_class, id, dependencies)
      selects = Collector.new(base_class, id, dependencies).collect
      new(selects)
    end

    def initialize(selects)
      @selects = selects
    end

    def translate(options={})
      Translator.new(@selects, options).translate
    end
  end

  # Public: Traverses a dependency graph based on a seed ActiveRecord object
  # and generates all the necessary INSERT queries for each one of the records
  # it finds along the way.
  #
  # base_class - An ActiveRecord::Base class for the seed record.
  # id - An ID used to find the desired seed record.
  #
  # dependency_tree - An ActiveRecord::Associations::Preloader compliant that
  # will define the path Polo will traverse.
  #
  # (from ActiveRecord::Associations::Preloader docs)
  # It may be:
  # - a Symbol or a String which specifies a single association name. For
  #   example, specifying +:books+ allows this method to preload all books
  #   for an Author.
  # - an Array which specifies multiple association names. This array
  #   is processed recursively. For example, specifying <tt>[:avatar, :books]</tt>
  #   allows this method to preload an author's avatar as well as all of his
  #   books.
  # - a Hash which specifies multiple association names, as well as
  #   association names for the to-be-preloaded association objects. For
  #   example, specifying <tt>{ author: :avatar }</tt> will preload a
  #   book's author, as well as that author's avatar.
  #
  # +:associations+ has the same format as the +:include+ option for
  # <tt>ActiveRecord::Base.find</tt>. So +associations+ could look like this:
  #
  #   :books
  #   [ :books, :author ]
  #   { author: :avatar }
  #   [ :books, { author: :avatar } ]
  #
  def self.explore(base_class, id, dependencies={})
    Traveler.new.collect(base_class, id, dependencies).translate
  end
end
