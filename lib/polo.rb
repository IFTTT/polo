require "polo/version"
require "polo/sql_translator"

module Polo

  class Explorer
    def initialize(base_class, id, dependency_tree={})
      @base_class = base_class
      @id = id
      @dependency_tree = dependency_tree

      @selects = []
    end

    def run
      ActiveSupport::Notifications.subscribed(collector, 'sql.active_record') do
        base_finder = @base_class.includes(@dependency_tree).where(id: @id)
        collect_sql(@base_class, base_finder.to_sql)
        base_finder.to_a
      end

      active_record_instances = @selects.flat_map do |select|
        select[:klass].find_by_sql(select[:sql]).to_a
      end

      SqlTranslator.new(active_record_instances).to_sql.uniq
    end

    private

    # Private
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

  def self.explorer(base_class, id, dependencies={})
    Explorer.new(base_class, id, dependencies)
  end
end
