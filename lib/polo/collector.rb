module Polo
  class Collector

    # Public: Creates a new Polo::Collector
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
    def initialize(base_class, id, dependency_tree={})
      @base_class = base_class
      @id = id
      @dependency_tree = dependency_tree
      @selects = []
    end

    # Public: Traverses the dependency tree and collects every SQL query.
    #
    # This is done by wrapping a top level call to includes(...) with a
    # ActiveSupport::Notifications block and collecting every generate SQL query.
    #
    def collect
      ActiveSupport::Notifications.subscribed(collector, 'sql.active_record') do
        base_finder = @base_class.includes(@dependency_tree).where(id: @id)
        collect_sql(@base_class, base_finder.to_sql)
        base_finder.to_a
      end

      @selects.uniq
    end

    private

    # Internal: Store ActiveRecord queries in @selects
    #
    # Collector will intersect every ActiveRecord query performed within the
    # ActiveSupport::Notifications.subscribed block defined in #run and store
    # the resulting SQL query in @selects
    #
    def collector
      lambda do |name, start, finish, id, payload|
        class_name = payload[:name].gsub(' Load', '').constantize
        sql = payload[:sql]
        collect_sql(class_name, sql)
      end
    end

    def collect_sql(klass, sql)
      @selects << {
        klass: klass,
        sql: sql
      }
    end
  end
end
