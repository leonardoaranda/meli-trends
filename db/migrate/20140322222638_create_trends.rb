class CreateTrends < ActiveRecord::Migration
  def change
    create_table :trends do |t|
      t.string :name
      t.string :site_id
      t.integer :category_id
      t.string :category_name
      t.timestamps
    end
  end
end