module TestData

  def self.create_netto
    AR::Chef.create(name: 'Netto', email: 'nettofarah@gmail.com').tap do |netto|
      AR::Recipe.create(title: 'Turkey Sandwich', chef: netto).tap do |r|
        r.ingredients.create(name: 'Turkey', quantity: 'a lot')
        r.ingredients.create(name: 'Cheese', quantity: '1 slice')
      end

      patty = AR::Ingredient.create(name: 'Patty', quantity: '1')
      cheese = AR::Ingredient.create(name: 'Cheese', quantity: '2 slices')

      AR::Recipe.create(title: 'Cheese Burger', chef: netto).tap do |r|
        r.ingredients << patty
        r.ingredients << cheese
        r.save!
      end

      AR::Vendor.create(name: 'Corner Store').tap do |v|
        v.ingredients << patty
        v.ingredients << cheese
        v.save!
      end

      AR::Vendor.create(name: 'Trader Joes').tap do |v|
        v.ingredients << cheese
        v.save!
      end
    end

    AR::Person.create(name: 'John Doe')
  end
end
