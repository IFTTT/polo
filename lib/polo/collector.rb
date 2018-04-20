module Polo
  class Collector
    DEFAULT_BATCH_SIZE = 1_000
    SqlRecord = Struct.new(:klass, :sql)

    def initialize(base_class, id, dependency_tree={})
      @base_class = base_class
      @ids = Array(id)
      @dependency_tree = dependency_tree
      @selects = Set.new
    end

    # Public: Traverses the dependency tree and collects every SQL query.
    #
    # This is done by wrapping a top level call to includes(...) with a
    # ActiveSupport::Notifications block and collecting every generate SQL query.
    #
    def collect
      base_finder = @base_class.includes(@dependency_tree)
      # If there are dependencies to load, we reduce the the batch size to compensate for
      # the increased memory of loading all the associations at the same time.
      batch_size = @dependency_tree.blank? ? DEFAULT_BATCH_SIZE : DEFAULT_BATCH_SIZE / 10
      enumerable = Enumerator.new do |yielder|
        @ids.each_slice(batch_size).with_index do |batch_of_ids, batch_index|
          with_sql_subscription do
            base_finder.where(@base_class.primary_key => batch_of_ids).load
          end
          # Expose this batch of SELECTs to the enumerator
          yielder.yield(@selects)
          # Reset the accumulator for the next batch (don't hog memory!)
          @selects.clear
        end
      end
      # By using a lazy enumerator, we make it possible to garbage collect records
      # as we process a batch, so long as the end user accesses the data via #each
      # and does not maintain references to previous rows. Example:
      #   Polo.explore(klass, ids, associations).each { |row| file.puts(row) }
      enumerable.to_enum.lazy
    end

    private

    # Captures all SQL queries executed in the given block, passing them to the collector
    def with_sql_subscription
      ActiveSupport::Notifications.subscribed(collector, 'sql.active_record') do
        unprepared_statement do
          yield
        end
      end
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
      @selects << SqlRecord.new(klass, sql)
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
