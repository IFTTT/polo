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

## Advanced Usage

Occasionally, you might have a dataset that you want to refresh. A production database that has data that might be useful on your local copy of the database. Polo doesn't have an opinion about your data; if you try to import data with a key that's already in your local database, Polo doesn't necessarily know how you want to handle that conflict.

Advanced users will find the `on_duplicate` option to be helpful in this context. It gives Polo instructions on how to handle collisions. *Note: This feature is currently only supported for MySQL databases. (PRs for other databases are welcome!)*

There are two possible values for the `on_duplicate` key: "ignore" and "update". Ignore keeps the old data. Update keeps the new data. If there's a collision and the on_duplicate param is not set, Polo will simpy stop importing the data.

### Ignore
A.K.A the Ostrich Approach: stick your head in the sand and pretend nothing happened.

```ruby
Polo::Traveler.collect(Chef, 1, :recipes).translate(on_duplicate: :ignore)
```

```sql
INSERT IGNORE INTO `chefs` (`id`, `name`) VALUES (1, 'Netto')
INSERT IGNORE INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`) VALUES (1, 'Turkey Sandwich', NULL, 1)
INSERT IGNORE INTO `recipes` (`id`, `title`, `num_steps`, `chef_id`) VALUES (2, 'Cheese Burger', NULL, 1)
```

### Override
Use the option `on_duplicate: :override` to override your local data with new data from your Polo script.

```ruby
Polo::Traveler.collect(Chef, 1, :recipes).translate(on_duplicate: :override)
```

```sql
INSERT INTO `chefs` (`id`, `name`) VALUES (1, 'Netto')
ON DUPLICATE KEY UPDATE id = VALUES(id), name = VALUES(name)
...
```

### Sensitive Fields
You can use the `obfuscate` option to obfuscate sensitive fields like emails or
user logins.

```ruby
Polo::Traveler.collect(AR::Chef, 1).translate(obfuscate: [:email])
```

```sql
INSERT INTO `chefs` (`id`, `name`, `email`) VALUES (1, 'Netto', 'eahorctmaagfo.nitm@l')
```

Warning: This is not a security feature. Fields can still easily be rearranged back to their original format. Polo will simply scramble the order of strings so you don't accidentaly end up causing side effects when using production data in development.

It is not a good practice to use highly sensitive data in development.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'polo'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install polo
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/polo. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

