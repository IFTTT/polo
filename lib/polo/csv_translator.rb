require 'active_record'
require 'polo/configuration'
require 'csv'

module Polo
  class CSVtranslator
    def intialize(table, csv_file)
      @csv = csv_file
      @table = table
    end

    def to_csv
        CSV.open(@csv, "w", write_hearders: true, headers: @table.column_names) do |csv|
          @table.all.each do |row|
            csv << row.values
          end
        end
    end
  end
end
