json.array!(@categories) do |category|
  json.extract! category, :id, :category_id, :name, :parent_id, :site_id
  json.url category_url(category, format: :json)
end
