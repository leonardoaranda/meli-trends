require 'mongo'

namespace :mercadolibre do
desc "Cache categories from MercadoLibre"
  task get_categories: :environment do
    ActiveRecord::Base.connection.execute("TRUNCATE categories")
  	meli = ActionController::Base::MercadolibreController.new
  	meli.process_categories('MLA',2)
  end

  desc "Get trends from MercadoLibre"
  task get_trends: :environment do
    db  = Mongo::Connection::new.db('meli_trends')
    Category.all.find_each do |category|
      meli = ActionController::Base::MercadolibreController.new
      meli_trends = meli.get_category_trends(category['category_id'],category['site_id'])
      category_trends = {
      	:site_id => category['site_id'],
      	:category_id => category['category_id'],
      	:category_name => category['category_name'],
      	:snapshot => Time.now
      }
      x=1
      trends_list = []
      if meli_trends.nil?
      	puts 'No trends for category '+category['category_id']
      else
        meli_trends.each do |trend|
          trends_list << {:keyword => trend['keyword'],:url => trend['url'],:order => x }
          x+=1
        end
        category_trends[:trends] = trends_list
        db['category_trends'].insert(category_trend)
        puts 'Category '+category['category_id']+' was succesfully processed'
      end
    end
  end

end