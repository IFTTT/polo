require 'spec_helper'

describe Polo::SqlTranslator do

  let(:netto) do
    AR::Chef.where(name: 'Netto').first
  end

  before(:all) do
    TestData.create_netto
  end

  it 'translates records to inserts' do
    insert_netto = [%q{INSERT INTO "chefs" ("id", "name", "email") VALUES (1, 'Netto', 'nettofarah@gmail.com')}]
    netto_to_sql = Polo::SqlTranslator.new([netto].to_enum).to_sql
    expect(netto_to_sql).to eq(insert_netto)
  end

  it 'encodes serialized fields correctly' do
    recipe = AR::Recipe.create(title: 'Polenta', metadata: { quality: 'ok' })
    recipe_to_sql = Polo::SqlTranslator.new([recipe].to_enum).to_sql.first
    expect(recipe_to_sql).to include(%q{'{"quality":"ok"}'}) # JSON, not YAML
  end

  it 'encodes attributes not backed by a database column correctly' do
    if Gem.loaded_specs["activerecord"].version < Gem::Version.new("4.2.1")
      skip "the attributes API was included in rails starting in 4.2.1"
    elsif Gem.loaded_specs["activerecord"].version >= Gem::Version.new("4.2.1") &&
        Gem.loaded_specs["activerecord"].version < Gem::Version.new("5.0.0")
      class Employee < ActiveRecord::Base
        attribute :on_vacation, Type::Boolean.new
      end
    else
      class Employee < ActiveRecord::Base
        attribute :on_vacation, :boolean
      end
    end

    employee = Employee.create(name: 'John Doe', on_vacation: true)
    employee_to_sql = Polo::SqlTranslator.new([employee].to_enum).to_sql.first
    expect(employee_to_sql).to_not include('on_vacation')
  end
end
