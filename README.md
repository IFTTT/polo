# Polo
Polo travels through your database and creates sample snapshots so you can work with real world data in any environment.

Polo takes an `ActiveRecord::Base` seed object and traverses every white listed `ActiveRecord::Association` generating SQL `INSERTs` along the way.

You can then save those SQL `INSERTS` to .sql file and import the data to your favorite environment.

## Usage
Given the following data model:
```ruby
class Chef < ActiveRecord::Base
  has_many :recipes
  has_many :ingredients, through: :recipes
end

class Recipe < ActiveRecord::Base
  has_many :recipes_ingredients
  has_many :ingredients, through: :recipes_ingredients
end

class Ingredient < ActiveRecord::Base
end

class RecipesIngredient < ActiveRecord::Base
  belongs_to :recipe
  belongs_to :ingredient
end
```

### Simple ActiveRecord Objects
```ruby
inserts = Polo.explore(Chef, 1)
```
```sql
INSERT INTO `chefs` (`id`, `name`) VALUES (1, 'Netto')
```

### Simple Associations
```ruby
inserts = Polo.explore(Chef, 1, :recipes)
```
```sql
INSERT INTO `chefs` (`id`, `name`) VALUES (1, 'Netto')
INSERT INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`) VALUES (1, 'Turkey Sandwich', NULL, 1)
INSERT INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`) VALUES (2, 'Cheese Burger', NULL, 1)
```

### Complex nested associations
```ruby
inserts = Polo.explore(Chef, 1, :recipes => :ingredients)
```

```sql
INSERT INTO `chefs` (`id`, `name`) VALUES (1, 'Netto')
INSERT INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`) VALUES (1, 'Turkey Sandwich', NULL, 1)
INSERT INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`) VALUES (2, 'Cheese Burger', NULL, 1)
INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (1, 1, 1)
INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (2, 1, 2)
INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (3, 2, 3)
INSERT INTO `recipes_ingredients` (`id`, `recipe_id`, `ingredient_id`) VALUES (4, 2, 4)
INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (1, 'Turkey', 'a lot')
INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (2, 'Cheese', '1 slice')
INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (3, 'Patty', '1')
INSERT INTO `ingredients` (`id`, `name`, `quantity`) VALUES (4, 'Cheese', '2 slices')
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'polo'
```

And then execute:

  $ bundle

Or install it yourself as:

  $ gem install polo

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/polo. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

