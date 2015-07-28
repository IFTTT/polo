require 'spec_helper'

describe Polo do

  before(:all) do
    TestData.create_netto
  end

  it 'generates an insert query for the base object' do
    exp = Polo.explorer(AR::Chef, 1)
    insert = "INSERT INTO `chefs` (`id`, `name`) VALUES (1, 'Netto')"
    expect(exp.run).to include(insert)
  end

  it 'generates insert queries for dependencies' do
    exp = Polo.explorer(AR::Chef, 1, [:recipes])

    turkey_insert        = "INSERT INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`) VALUES (1, 'Turkey Sandwich', NULL, 1)"
    cheese_burger_insert = "INSERT INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`) VALUES (2, 'Cheese Burger', NULL, 1)"

    inserts = exp.run

    expect(inserts).to include(turkey_insert)
    expect(inserts).to include(cheese_burger_insert)
  end

  it 'generates queries for nested dependencies' do
    exp = Polo.explorer(AR::Chef, 1, :recipes => :ingredients)

    patty       = "INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (3, 'Patty', '1')"
    turkey      = "INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (1, 'Turkey', 'a lot')"
    one_cheese  = "INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (2, 'Cheese', '1 slice')"
    two_cheeses = "INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (4, 'Cheese', '2 slices')"

    inserts = exp.run

    expect(inserts).to include(patty)
    expect(inserts).to include(turkey)
    expect(inserts).to include(one_cheese)
    expect(inserts).to include(two_cheeses)
  end

  it 'generates insersts for many to many relationships' do
    exp = Polo.explorer(AR::Chef, 1, :recipes => :ingredients)

    many_to_many_inserts = [
      "INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (1, 1, 1)",
      "INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (2, 1, 2)",
      "INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (3, 2, 3)",
      "INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (4, 2, 4)",
    ]

    inserts = exp.run
    many_to_many_inserts.each do |many_to_many_insert|
      expect(inserts).to include(many_to_many_insert)
    end
  end
end
