module AR
  class Recipe < ActiveRecord::Base
    belongs_to :chef
    has_many :recipes_ingredients
    has_many :ingredients, through: :recipes_ingredients

    serialize :metadata, JSON
  end

  class Ingredient < ActiveRecord::Base
  end

  class RecipesIngredient < ActiveRecord::Base
    belongs_to :recipe
    belongs_to :ingredient
  end

  class Restaurant < ActiveRecord::Base
    belongs_to :owner, class_name: 'Chef'
    has_one :rating
  end

  class Rating < ActiveRecord::Base
    belongs_to :restaurant
  end

  class Chef < ActiveRecord::Base
    has_many :recipes
    has_many :ingredients, through: :recipes
    has_one  :restaurant, foreign_key: 'owner_id'
  end
end
