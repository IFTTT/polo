require 'spec_helper'

describe Polo do

  before(:all) do
    TestData.create_netto
  end

  it '' do
    exp = Polo.explore(AR::Recipe, 2, {
      ingredients: [:vendors]
    })
    require 'byebug'
    debugger
    puts exp
    #insert = %q{INSERT INTO "people" ("ssn", "name") VALUES (1, 'John Doe')}
    #expect(exp).to include(insert)
  end
end
