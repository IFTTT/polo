require 'spec_helper'

describe Polo do

  before(:all) do
    TestData.create_netto
  end

  it 'generates an insert query for the base object' do
    exp = Polo.explorer(AR::Chef, 1)
    insert = ["INSERT INTO `chefs` (`id`, `name`) VALUES (1, 'Netto')"]
    expect(exp.run).to eq(insert)
  end

  it 'works with dependencies' do
    exp = Polo.explorer(AR::Chef, 1, [:recipes])

    inserts = [
      "INSERT INTO `chefs` (`id`, `name`) VALUES (1, 'Netto')",
      "INSERT INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`) VALUES (1, 'Turkey Sandwich', NULL, 1)",
      "INSERT INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`) VALUES (2, 'Cheese Burger', NULL, 1)"
    ]

    expect(exp.run).to eq(inserts)
  end

  it 'works with nested dependencies' do
    exp = Polo.explorer(AR::Chef, 1, :recipes => :ingredients)

    inserts = [
      "INSERT INTO `chefs` (`id`, `name`) VALUES (1, 'Netto')",
      "INSERT INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`) VALUES (1, 'Turkey Sandwich', NULL, 1)",
      "INSERT INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`) VALUES (2, 'Cheese Burger', NULL, 1)",
      "INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (1, 1, 1)",
      "INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (2, 1, 2)",
      "INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (3, 2, 3)",
      "INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (4, 2, 4)",
      "INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (1, 'Turkey', 'a lot')",
      "INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (2, 'Cheese', '1 slice')",
      "INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (3, 'Patty', '1')",
      "INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (4, 'Cheese', '2 slices')"
    ]

    expect(exp.run).to eq(inserts)
  end
end
