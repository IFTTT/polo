ActiveRecord::Schema.define do
  create_table :recipes, force: true do |t|
    t.column :title, :string
    t.column :num_steps, :integer
    t.column :chef_id, :integer
    t.column :metadata, :text
  end

  create_table :ingredients, force: true do |t|
    t.column :name, :string
    t.column :quantity, :string
  end

  create_table :vendors, force: true do |t|
    t.column :name, :string
  end

  create_table :ingredients_vendors, force: true do |t|
    t.column :ingredient_id, :integer
    t.column :vendor_id, :integer
  end

  create_table :recipes_ingredients, force: true do |t|
    t.column :recipe_id, :integer
    t.column :ingredient_id, :integer
  end

  create_table :chefs, force: true do |t|
    t.column :name, :string
    t.column :email, :string
  end

  create_table :restaurants, force: true do |t|
    t.column :name, :string
    t.column :owner_id, :integer
    t.column :current_customer_count, :integer
  end

  create_table :ratings, force: true do |t|
    t.column :value, :string
    t.column :restaurant_id, :integer
  end

  create_table :people, primary_key: :ssn, force: true do |t|
    t.column :name, :string
  end
end
