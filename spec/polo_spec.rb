require 'spec_helper'

describe Polo do

  before(:all) do
    TestData.create_netto
  end

  it 'generates an insert query for the base object' do
    exp = Polo.explore(AR::Chef, 1)
    insert = "INSERT INTO `chefs` (`id`, `name`, `email`) VALUES (1, 'Netto', 'nettofarah@gmail.com')"
    expect(exp).to include(insert)
  end

  it 'generates an insert query for the objects with non-standard primary keys' do
    exp = Polo.explore(AR::Person, 1)
    insert = "INSERT INTO `people` (`ssn`, `name`) VALUES (1, 'John Doe')"
    expect(exp).to include(insert)
  end

  it 'generates insert queries for dependencies' do
    if ActiveRecord::VERSION::STRING.start_with?('4.2')
      serialized_nil = "NULL"
    else
      serialized_nil = "'null'"
    end

    turkey_insert        = "INSERT INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`, `metadata`) VALUES (1, 'Turkey Sandwich', NULL, 1, #{serialized_nil})"
    cheese_burger_insert = "INSERT INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`, `metadata`) VALUES (2, 'Cheese Burger', NULL, 1, #{serialized_nil})"

    inserts = Polo.explore(AR::Chef, 1, [:recipes])

    expect(inserts).to include(turkey_insert)
    expect(inserts).to include(cheese_burger_insert)
  end

  it 'generates queries for nested dependencies' do
    patty       = "INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (3, 'Patty', '1')"
    turkey      = "INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (1, 'Turkey', 'a lot')"
    one_cheese  = "INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (2, 'Cheese', '1 slice')"
    two_cheeses = "INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (4, 'Cheese', '2 slices')"

    inserts = Polo.explore(AR::Chef, 1, :recipes => :ingredients)

    expect(inserts).to include(patty)
    expect(inserts).to include(turkey)
    expect(inserts).to include(one_cheese)
    expect(inserts).to include(two_cheeses)
  end

  it 'generates inserts for many to many relationships' do
    many_to_many_inserts = [
      "INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (1, 1, 1)",
      "INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (2, 1, 2)",
      "INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (3, 2, 3)",
      "INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (4, 2, 4)",
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
        insert = /INSERT INTO `chefs` \(`id`, `name`, `email`\) VALUES \(1, 'Netto', (.+)\)/
        scrambled_email = insert.match(exp.first)[1]

        expect(scrambled_email).to_not eq('nettofarah@gmail.com')
        expect(insert).to match(exp.first)
      end
    end

    describe 'on_duplicate' do
      it 'applies the on_duplicate strategy' do
        Polo.configure do
          on_duplicate(:ignore)
        end

        exp = Polo.explore(AR::Chef, 1)
        insert = /INSERT IGNORE INTO `chefs` \(`id`, `name`, `email`\) VALUES \(1, 'Netto', (.+)\)/
        expect(insert).to match(exp.first)
      end
    end
  end
end
