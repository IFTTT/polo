require 'spec_helper'

describe Polo::SqlTranslator do

  let(:netto) do
    AR::Chef.find_by(name: 'Netto')
  end

  before(:all) do
    TestData.create_netto
  end

  it 'translates records to inserts' do
    insert_netto = [%q{INSERT INTO `chefs` (`id`, `name`) VALUES (1, 'Netto')}]
    netto_to_sql = Polo::SqlTranslator.new(netto).to_sql
    expect(netto_to_sql).to eq(insert_netto)
  end

  describe "ignore_duplicate_rows" do

    it 'uses INSERT IGNORE as opposed to regular inserts' do
      insert_netto = [%q{INSERT IGNORE INTO `chefs` (`id`, `name`) VALUES (1, 'Netto')}]
      netto_to_sql = Polo::SqlTranslator.new(netto, OpenStruct.new(ignore_duplicate_rows: true)).to_sql
      expect(netto_to_sql).to eq(insert_netto)
    end
  end
end
