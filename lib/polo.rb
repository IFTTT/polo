require "polo/version"
require "polo/sql_translator"

module Polo

  class Explorer
    def initialize(base_class, id, dependency_tree={})
      @base_class = base_class
      @id = id
      @dependency_tree = dependency_tree
    end

    def run
      selects = []
      queries_collector = lambda do |name, start, finish, id, payload|

        selects << {
          class_name: payload[:name].gsub(' Load', '').constantize,
          sql: payload[:sql]
        }
      end

      ActiveSupport::Notifications.subscribed(queries_collector, 'sql.active_record') do
        base_finder = @base_class.includes(@dependency_tree).where(id: @id)

        selects << {
          class_name: @base_class,
          sql: base_finder.to_sql
        }

        base_finder.to_a
      end

      active_record_instances = selects.flat_map do |select|
        select[:class_name].find_by_sql(select[:sql]).to_a
      end

      SqlTranslator.new(active_record_instances).to_sql.uniq
    end
  end

  def self.explorer(base_class, id, dependencies={})
    Explorer.new(base_class, id, dependencies)
  end
end
