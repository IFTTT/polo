module Polo
  class Collector
    @@subscriber = nil

    def initialize(base_class, id, dependency_tree={})
      @base_class = base_class
      @id = id
      @dependency_tree = dependency_tree
      @selects = []
      # If a previous Brillo instance has subscribed, unsubscribe.
      # Unfortunately we can't use the block scoped syntax because of the lazy enumerable
      end_subscriber!
    end

    # Public: Traverses the dependency tree and collects every SQL query.
    #
    # This is done by wrapping a top level call to includes(...) with a
    # ActiveSupport::Notifications block and collecting every generate SQL query.
    #
    def collect
      start_subscriber!
      enumerable = nil
      unprepared_statement do
        base_finder = @base_class.includes(@dependency_tree).where(@base_class.primary_key => @id)
        collect_sql(@base_class, base_finder.to_sql)
        enumerable = Enumerator::Lazy.new(base_finder.find_in_batches.with_index) do |yielder, batch, batch_index|
          # Expose each select to the enumerated block
          @selects.compact.each do |selected|
            yielder << selected
          end
          # Now reset the accumulator (don't hog memory!)
          @selects = []
        end
      end
      enumerable
    end

    private

    def start_subscriber!
      collector_instance = collector
      @@subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
        collector_instance.call(*args)
      end
    end

    def end_subscriber!
      ActiveSupport::Notifications.unsubscribe(@@subscriber) if @@subscriber
    end

    # Internal: Store ActiveRecord queries in @selects
    #
    # Collector will intersect every ActiveRecord query performed within the
    # ActiveSupport::Notifications.subscribed block defined in #run and store
    # the resulting SQL query in @selects
    #
    def collector
      lambda do |name, start, finish, id, payload|
        return unless payload[:name] =~ /^(.*) Load$/
        begin
          class_name = $1.constantize
          sql = payload[:sql]
          collect_sql(class_name, sql)
        rescue ActiveRecord::StatementInvalid, NameError
          # invalid table name (common when prefetching schemas)
        end
      end
    end

    def collect_sql(klass, sql)
      @selects << {
        klass: klass,
        sql: sql
      }
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
