json.array!(@trends) do |trend|
  json.extract! trend, :id, :name, :site_id, :category_id, :category_name, :created_at
  json.url trend_url(trend, format: :json)
end
