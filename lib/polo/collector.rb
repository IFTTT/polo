module Polo
  class Collector
    SqlRecord = Struct.new(:klass, :sql)
    def initialize(base_class, id, dependency_tree={})
      @base_class = base_class
      @id = id
      @dependency_tree = dependency_tree
      @selects = Set.new
    end

    # Public: Traverses the dependency tree and collects every SQL query.
    #
    # This is done by wrapping a top level call to includes(...) with a
    # ActiveSupport::Notifications block and collecting every generate SQL query.
    #
    def collect
      base_finder = @base_class.includes(@dependency_tree).where(@base_class.primary_key => @id)
      # If we are not also looking up relationships, we can process many more records at once
      batch_size = @dependency_tree.blank? ? 10_000 : 1_000
      enumerable = Enumerator.new do |yielder|
        collect_sql(@base_class, base_finder.to_sql)
        unprepared_statement do
          ActiveSupport::Notifications.subscribed(collector, 'sql.active_record') do
            base_finder.find_in_batches(batch_size: batch_size).with_index do |batch, batch_index|
              # Expose each select to the enumerator
              yielder.yield(@selects)
              # Now reset the accumulator (don't hog memory!)
              @selects = Set.new
            end
          end
        end
      end
      # By using a lazy enumerator, we make it possible to garbage collect records
      # as we process a batch, so long as the end user accesses the data via #each
      # and does not maintain references to previous rows. Example:
      #   Polo.explore(klass, ids, associations).each { |row| file.puts(row) }
      enumerable.to_enum.lazy
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
