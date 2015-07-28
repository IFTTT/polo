module Polo
  class Collector

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
