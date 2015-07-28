module TestData
  def self.create_tom
    AR::Chef.create(name: 'Tom').tap do |tom|
      AR::Recipe.create(title: 'Pastrami Sandwich', chef: tom).tap do |r|
        r.ingredients.create(name: 'Pastrami', quantity: 'a lot')
        r.ingredients.create(name: 'Cheese', quantity: '1 slice')
      end

      AR::Recipe.create(title: 'Belly Burger', chef: tom).tap do |r|
        r.ingredients.create(name: 'Pork Belly', quantity: 'plenty')
        r.ingredients.create(name: 'Green Apple', quantity: '2 slices')
      end

      AR::Restaurant.create(name: 'Chef Tom Belly Burgers', owner: tom) do |res|
        res.create_rating(value: '3 stars')
      end
    end
  end

  def self.create_netto
    AR::Chef.create(name: 'Netto').tap do |netto|
      AR::Recipe.create(title: 'Turkey Sandwich', chef: netto).tap do |r|
        r.ingredients.create(name: 'Turkey', quantity: 'a lot')
        r.ingredients.create(name: 'Cheese', quantity: '1 slice')
      end

      AR::Recipe.create(title: 'Cheese Burger', chef: netto).tap do |r|
        r.ingredients.create(name: 'Patty', quantity: '1')
        r.ingredients.create(name: 'Cheese', quantity: '2 slices')
      end
    end
  end
end
