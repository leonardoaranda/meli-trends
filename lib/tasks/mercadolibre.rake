namespace :mercadolibre do
  desc "Cache categories from MercadoLibre"
  task get_categories: :environment do
    ActiveRecord::Base.connection.execute("TRUNCATE categories")
  	meli = ActionController::Base::MercadolibreController.new
  	meli.process_categories('MLA',2)
  end

  desc "Get trends from MercadoLibre"
  task get_trends: :environment do
    Category.all.find_each do |category|
      meli = ActionController::Base::MercadolibreController.new
      processed_category_trends = meli.process_category_trends(category['category_id'],category['site_id'])
      processed_category_trends[:category_name] = category['category_name']
      meli.save_category_trends(processed_category_trends)
      puts 'Category '+category['category_id']+' was succesfully processed'
    end
  end

  desc "Trends to ElasticSearch"
  task index_trends: :environment do
    trends = ActionController::Base::TrendsController.new
    trends.index_trends()
  end

  desc "Trends Map Processor"
  task trends_map_processor: :environment do
    trends = ActionController::Base::TrendsController.new
    trends.trend_map_processor()
  end

  desc "Trends Reduce Processor"
  task trends_reduce_processor: :environment do
    trends = ActionController::Base::TrendsController.new
    trends.trend_reduce_processor()
  end
end