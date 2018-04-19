require "polo/version"
require "polo/collector"
require "polo/translator"
require "polo/configuration"

module Polo

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
    Traveler.collect_in_batches(base_class, id, dependencies).flat_map do |traveler|
      # Within each batch, unique-ify, as Rails batch processing seems to cause
      # repeat queries that lead to erronous duplicate rows.
      traveler.translate(defaults).uniq
    end
  end


  # Public: Sets up global settings for Polo
  #
  # block - Takes a block with the settings you decide to use
  #
  #   obfuscate - Takes a blacklist with sensitive fields you wish to scramble
  #   on_duplicate - Defines the on_duplicate strategy for your INSERTS
  #     e.g. :override, :ignore
  #
  # usage:
  #   Polo.configure do
  #     obfuscate(:email, :password, :credit_card)
  #     on_duplicate(:override)
  #   end
  #
  def self.configure(&block)
    @configuration = Configuration.new
    @configuration.instance_eval(&block) if block_given?
    @configuration
  end

  # Public: Returns the default settings
  #
  def self.defaults
    @configuration || configure
  end


  class Traveler

    def self.collect_in_batches(base_class, id, dependencies={})
      select_batches = Collector.new(base_class, id, dependencies).collect
      select_batches.map { |selects| new(selects) }
    end

    def initialize(selects)
      @selects = selects
    end

    def translate(configuration=Configuration.new)
      Translator.new(@selects, configuration).translate
    end
  end
end
