class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :category_id
      t.string :name
      t.string :parent_id
      t.string :site_id

      t.timestamps
    end
  end
end
