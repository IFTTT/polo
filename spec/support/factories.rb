module TestData

  def self.create_netto
    AR::Chef.create(name: 'Netto', email: 'nettofarah@gmail.com').tap do |netto|
      AR::Recipe.create(title: 'Turkey Sandwich', chef: netto).tap do |r|
        r.ingredients.create(name: 'Turkey', quantity: 'a lot')
        r.ingredients.create(name: 'Cheese', quantity: '1 slice')
      end

      AR::Recipe.create(title: 'Cheese Burger', chef: netto).tap do |r|
        r.ingredients.create(name: 'Patty', quantity: '1')
        r.ingredients.create(name: 'Cheese', quantity: '2 slices')
      end
    end

    AR::Person.create(name: 'John Doe')
  end
end
