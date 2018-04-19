require 'spec_helper'

describe Polo::Adapters::MySQL do

  let(:adapter) { Polo::Adapters::MySQL.new }

  let(:netto) do
    AR::Chef.where(name: 'Netto').first
  end

  before(:all) do
    TestData.create_netto
  end

  let(:translator) { Polo::SqlTranslator.new([netto].to_enum, Polo::Configuration.new(adapter: :mysql)) }

  describe '#ignore_transform' do
    it 'appends the IGNORE command after INSERTs' do
      insert_netto = [%q{INSERT IGNORE INTO "chefs" ("id", "name", "email") VALUES (1, 'Netto', 'nettofarah@gmail.com')}]

      records = translator.records
      inserts = translator.inserts
      translated_sql = adapter.ignore_transform(inserts, records)
      expect(translated_sql).to eq(insert_netto)
    end
  end


  describe '#on_duplicate_key_update' do
    it 'appends ON DUPLICATE KEY UPDATE with all values to the current INSERT statement' do
      insert_netto = [
        %q{INSERT INTO "chefs" ("id", "name", "email") VALUES (1, 'Netto', 'nettofarah@gmail.com') ON DUPLICATE KEY UPDATE `id` = VALUES(`id`), `name` = VALUES(`name`), `email` = VALUES(`email`)}
      ]

      inserts = translator.inserts
      records = translator.records
      translated_sql = adapter.on_duplicate_key_update(inserts, records)
      expect(translated_sql).to eq(insert_netto)
    end
  end
end
