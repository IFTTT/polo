require 'spec_helper'

describe Polo do

  before(:all) do
    TestData.create_netto
  end

  it 'generates an insert query for the base object' do
    exp = Polo.explore(AR::Chef, 1)
    insert = %q{INSERT INTO "chefs" ("id", "name", "email") VALUES (1, 'Netto', 'nettofarah@gmail.com')}
    expect(exp).to include(insert)
  end

  it 'generates an insert query for the objects with non-standard primary keys' do
    exp = Polo.explore(AR::Person, 1)
    insert = %q{INSERT INTO "people" ("ssn", "name") VALUES (1, 'John Doe')}
    expect(exp).to include(insert)
  end

  it 'generates insert queries for dependencies' do
    if ActiveRecord::VERSION::STRING.start_with?('4.2')
      serialized_nil = "NULL"
    else
      serialized_nil = "'null'"
    end

    turkey_insert        = %Q{INSERT INTO "recipes" ("id", "title", "num_steps", "chef_id", "metadata") VALUES (1, 'Turkey Sandwich', NULL, 1, #{serialized_nil})}
    cheese_burger_insert = %Q{INSERT INTO "recipes" ("id", "title", "num_steps", "chef_id", "metadata") VALUES (2, 'Cheese Burger', NULL, 1, #{serialized_nil})}

    inserts = Polo.explore(AR::Chef, 1, [:recipes])

    expect(inserts).to include(turkey_insert)
    expect(inserts).to include(cheese_burger_insert)
  end

  it 'generates queries for nested dependencies' do
    patty       = %q{INSERT INTO "ingredients" ("id", "name", "quantity") VALUES (3, 'Patty', '1')}
    turkey      = %q{INSERT INTO "ingredients" ("id", "name", "quantity") VALUES (1, 'Turkey', 'a lot')}
    one_cheese  = %q{INSERT INTO "ingredients" ("id", "name", "quantity") VALUES (2, 'Cheese', '1 slice')}
    two_cheeses = %q{INSERT INTO "ingredients" ("id", "name", "quantity") VALUES (4, 'Cheese', '2 slices')}

    inserts = Polo.explore(AR::Chef, 1, :recipes => :ingredients)

    expect(inserts).to include(patty)
    expect(inserts).to include(turkey)
    expect(inserts).to include(one_cheese)
    expect(inserts).to include(two_cheeses)
  end

  it 'generates inserts for many to many relationships' do
    many_to_many_inserts = [
      %q{INSERT INTO "recipes_ingredients" ("id", "recipe_id", "ingredient_id") VALUES (1, 1, 1)},
      %q{INSERT INTO "recipes_ingredients" ("id", "recipe_id", "ingredient_id") VALUES (2, 1, 2)},
      %q{INSERT INTO "recipes_ingredients" ("id", "recipe_id", "ingredient_id") VALUES (3, 2, 3)},
      %q{INSERT INTO "recipes_ingredients" ("id", "recipe_id", "ingredient_id") VALUES (4, 2, 4)},
    ]

    inserts = Polo.explore(AR::Chef, 1, :recipes => :ingredients)

    many_to_many_inserts.each do |many_to_many_insert|
      expect(inserts).to include(many_to_many_insert)
    end
  end

  describe "Advanced Options" do
    describe 'obfuscate: [fields]' do

      it 'scrambles a predefined field' do
        Polo.configure do
          obfuscate(:email)
        end

        exp = Polo.explore(AR::Chef, 1)
        insert = /INSERT INTO "chefs" \("id", "name", "email"\) VALUES \(1, 'Netto', (.+)\)/
        scrambled_email = insert.match(exp.first)[1]

        expect(scrambled_email).to_not eq('nettofarah@gmail.com')
        expect(insert).to match(exp.first)
      end

      it 'can apply custom strategies' do
        Polo.configure do
          obfuscate(email: lambda { |_| 'changeme' })
        end

        inserts = Polo.explore(AR::Chef, 1)

        expect(inserts).to eq [ %q{INSERT INTO "chefs" ("id", "name", "email") VALUES (1, 'Netto', 'changeme')} ]
      end

      it 'only scrambles instances with the obfuscate field defined' do
        Polo.configure do
          obfuscate :name,
                    email: ->(e) { "#{e.split("@")[0]}_test@example.com" },
                    title: ->(t) { t.chars.reverse!.join }
        end

        exp = Polo.explore(AR::Chef, 1, :recipes)

        explore_statement = exp.join(';')
        expect(explore_statement).to_not match('nettofarah@gmail.com')
        expect(explore_statement).to_not match('Netto')
      end

      it 'can target a specific field in a table' do
        Polo.configure do
          obfuscate 'ingredients.name' => -> (i) { "Secret" }
        end

        exp = Polo.explore(AR::Chef, 1, recipes: :ingredients)

        explore_statement = exp.join(';')
        expect(explore_statement).to match('Netto')
        expect(explore_statement).to match('Secret')
      end
    end

    describe 'on_duplicate' do
      it 'applies the on_duplicate strategy' do
        Polo.configure do
          on_duplicate(:ignore)
        end

        exp = Polo.explore(AR::Chef, 1)
        insert = /INSERT IGNORE INTO "chefs" \("id", "name", "email"\) VALUES \(1, 'Netto', (.+)\)/
        expect(insert).to match(exp.first)
      end
    end
  end
end
