require 'spec_helper'

describe Polo::SqlTranslator do

  let(:netto) do
    AR::Chef.find_by(name: 'Netto')
  end

  before(:all) do
    TestData.create_netto
  end

  it 'translates records to inserts' do
    insert_netto = [%q{INSERT INTO `chefs` (`id`, `name`, `email`) VALUES (1, 'Netto', 'nettofarah@gmail.com')}]
    netto_to_sql = Polo::SqlTranslator.new(netto).to_sql
    expect(netto_to_sql).to eq(insert_netto)
  end

  describe "options" do
    describe "on_duplicate: :ignore" do
      it 'uses INSERT IGNORE as opposed to regular inserts' do
        insert_netto = [%q{INSERT IGNORE INTO `chefs` (`id`, `name`, `email`) VALUES (1, 'Netto', 'nettofarah@gmail.com')}]
        netto_to_sql = Polo::SqlTranslator.new(netto, on_duplicate: :ignore ).to_sql
        expect(netto_to_sql).to eq(insert_netto)
      end
    end

    describe "on_duplicate: :override" do
      it 'appends ON DUPLICATE KEY UPDATE to the statement' do
        insert_netto = [
          %q{INSERT INTO `chefs` (`id`, `name`, `email`) VALUES (1, 'Netto', 'nettofarah@gmail.com') ON DUPLICATE KEY UPDATE id = VALUES(id), name = VALUES(name), email = VALUES(email)}
        ]

        netto_to_sql = Polo::SqlTranslator.new(netto, on_duplicate: :override).to_sql
        expect(netto_to_sql).to eq(insert_netto)
      end
    end
  end
end
