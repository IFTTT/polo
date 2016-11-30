require 'spec_helper'
require 'fileutils' #to remove files when done

describe  Polo::CSVTranslator do

  before(:all) do
    TestData.create_netto
  end

  it 'instantiates CSVTranslator' do
    expect{Polo::CSVTranslator.new(AR::Chef, "test.csv")}.not_to raise_error
  end

  it 'prevents instantiation if not csv file' do
    expect{Polo::CSVTranslator.new(AR::Chef, "notcsv.txt")}.to raise_error(ArgumentError, "file name must end in .csv")
  end

  it 'prevents instantiation if table not in database' do
    expect{Polo::CSVTranslator.new(AR::NotATable, "test.csv")}.to raise_error(NameError)
  end

  describe 'to_csv' do
    let(:translator) {Polo::CSVTranslator.new(AR::Chef, "test.csv")}
    let(:translator2) {Polo::CSVTranslator.new(AR::Recipe, "test2.csv")}

    it 'creates a new file with csv name' do
      translator.to_csv
      expect(File.exist?("test.csv")).to be_truthy
    end

    it 'adds headers to csv' do
      expect(CSV.readlines("test.csv")[0]).to match_array ["id", "name", "email"]
    end

    it 'adds all rows to csv file' do
      translator2.to_csv
      expect(CSV.readlines("test2.csv").size).to equal(AR::Recipe.count+1)
    end

  end

  after(:all) do
    FileUtils.rm("test.csv")
    FileUtils.rm("test2.csv")
  end
end

