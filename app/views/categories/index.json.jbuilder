json.array!(@categories) do |category|
  json.extract! category, :id, :category_id, :category_name, :parent_id, :site_id, :level
  json.url category_url(category, format: :json)
end
