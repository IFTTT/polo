# require 'active_record'
# require 'polo/configuration'
require 'csv'

module Polo
  class CSVTranslator
    def initialize(table, csv_file, configuration=Configuration.new)
      # (.csv)$/.match(csv_file)? @csv = csv_file :
      @table = table
      @configuration = configuration
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
