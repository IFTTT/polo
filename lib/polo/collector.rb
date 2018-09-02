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
      unprepared_statement do
        ActiveSupport::Notifications.subscribed(collector, 'sql.active_record') do
          base_finder = @base_class.includes(@dependency_tree).where(@base_class.primary_key => @id)
          collect_sql(klass: @base_class, sql: base_finder.to_sql)
          base_finder.to_a
        end
      end

      @selects.compact.uniq
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
        sql = payload[:sql]
        if payload[:name] =~ /^HABTM_.* Load$/
          collect_sql(connection: @base_class.connection, sql: sql)
        elsif payload[:name] =~ /^(.*) Load$/
          begin
            class_name = $1.constantize
            collect_sql(klass: class_name, sql: sql)
          rescue ActiveRecord::StatementInvalid, NameError
            # invalid table name (common when prefetching schemas)
          end
        end
      end
    end

    def collect_sql(select)
      @selects << select
    end

    def unprepared_statement
      if ActiveRecord::Base.connection.respond_to?(:unprepared_statement)
        ActiveRecord::Base.connection.unprepared_statement do
          yield
        end
      else
        yield
      end
    end
  end
end
