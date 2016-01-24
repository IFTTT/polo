require 'csv'

module Polo
  class CSVTranslator

    # Tool to translate table to csv file
    # Future updates: translate CSV to table

    def initialize(model, csv_file, configuration=Configuration.new)
      raise ArgumentError, "file name must end in .csv" unless /(.csv)$/.match(csv_file)
      @csv = csv_file
      @model = model
      @configuration = configuration
    end

    def to_csv
      #
        CSV.open(@csv, "w", write_headers: true, headers: @model.column_names) do |csv|
          @model.all.each do |row|
            csv << row.attributes.values
          end
        end
    end
  end
end
