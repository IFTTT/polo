require 'spec_helper'

describe Polo::Adapters::Postgres do

  let(:adapter) { Polo::Adapters::Postgres.new }

  let(:netto) do
    AR::Chef.where(name: 'Netto').first
  end

  before(:all) do
    TestData.create_netto
  end

  let(:translator) { Polo::SqlTranslator.new([netto].to_enum, Polo::Configuration.new(adapter: :postgres)) }

  describe '#on_duplicate_key_update' do
    it 'should raise an error' do
      expect { adapter.on_duplicate_key_update(double(), double()) }.to raise_error('on_duplicate: :override is not currently supported in the PostgreSQL adapter')
    end
  end

  describe '#ignore_transform' do
    it 'transforms INSERT by appending WHERE NOT EXISTS clause' do

      insert_netto = [%q{INSERT INTO "chefs" ("id", "name", "email") SELECT 1, 'Netto', 'nettofarah@gmail.com' WHERE NOT EXISTS (SELECT 1 FROM chefs WHERE id=1);}]

      records = translator.records
      inserts = translator.inserts
      translated_sql = adapter.ignore_transform(inserts, records)
      expect(translated_sql).to eq(insert_netto)
    end
  end
end
