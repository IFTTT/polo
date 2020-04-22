# https://stackoverflow.com/a/44286212
if ActiveRecord::VERSION::MAJOR < 5
  module Arel
    module Visitors
      class DepthFirst < Arel::Visitors::Visitor
        alias :visit_Integer :terminal
      end

      class Dot < Arel::Visitors::Visitor
        alias :visit_Integer :visit_String
      end

      if ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR >= 2
        class ToSql < Arel::Visitors::Reduce
          alias :visit_Integer :literal
        end
      else
        class ToSql < Arel::Visitors::Visitor
          alias :visit_Integer :literal
        end
      end
    end
  end
end
