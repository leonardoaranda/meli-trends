class AddOrderToTrends < ActiveRecord::Migration
  def change
  	add_column :trends, :order, :integer
  end
end