class MercadolibreController < ApplicationController

	def initialize()
		@max_depth = 1
	end

	def get_category_trends(category_id,site_id)
		request = Net::HTTP.get_response(URI.parse('https://api.mercadolibre.com/sites/'+site_id+'/trends/search?category='+category_id))
		if request.code == '200'
			return JSON.parse request.body
		else
			return nil
		end
	end

	def get_children_categories(parent_id)
		request = Net::HTTP.get(URI.parse('https://api.mercadolibre.com/categories/'+parent_id))
		categories = JSON.parse request
		return categories['children_categories']
	end

	def get_site_categories(site_id)
		request = Net::HTTP.get(URI.parse('https://api.mercadolibre.com/sites/'+site_id+'/categories'))
		categories = JSON.parse request
		return categories
	end

	def bulk_trends_processor(site_id,max_depth)
		@max_depth = max_depth
		categories = get_site_categories(site_id)
		categories.each do |category|
			level = 1
			category_trends = get_category_trends(category['id'],site_id)
			puts '#####'+category['name']+'#####'			
			tree_bound(category['id'],nil,nil,level,site_id)
		end
	end

	def tree_bound(category_id,parent_id,parent_trends,level,site_id)
		level += 1
		children_categories = get_children_categories(category_id)
		children_categories.each do |children|
			if (parent_id != nil and parent_trends == nil) or level > @max_depth
				puts 'SKIPPING '+children['id']+' '+children['name']
				next
			end
			children_category_trends = get_category_trends(children['id'],site_id)
			puts '#####'+children['name']+'#####'
			tree_bound(children['id'],category_id,children_category_trends,level,site_id)
		end
	end

	def process_categories(site_id,max_depth)
		@max_depth = max_depth
		categories = get_site_categories(site_id)
		categories.each do |category|
			level = 1
			puts level.to_s+'root '+category['name']+'-'+category['id']			
			save_category(category['id'],category['name'],site_id,nil,level)
			process_children_categories(category,level,site_id)
		end
	end

	def process_children_categories(parent,level,site_id)
		level += 1
		if level <= @max_depth
			children_categories = get_children_categories(parent['id'])
			children_categories.each do |children|
				puts level.to_s+'children '+children['name']+'-'+children['id']
				save_category(children['id'],children['name'],site_id,parent['id'],level)				
				process_children_categories(children,level,site_id)
			end
		end
	end

	def process_category_trends(category_id,site_id)
		x=1
		trends_list = []
		category_trends = get_category_trends(category_id,site_id)
		processed_category_trends = {
			:site_id => site_id,
			:category_id => category_id,
			:snapshot => Time.now
		}
		if !category_trends.nil?
			category_trends.each do |trend|
				trends_list << {:keyword => trend['keyword'],:url => trend['url'],:order => x }
				x+=1
			end
		end
		processed_category_trends[:trends] = trends_list
		return processed_category_trends
	end

	def save_category_trends(processed_category_trends)
		db  = get_mongodb_connection()
		coll = db['category_trends']
		coll.insert(processed_category_trends)
	end

	def save_category(category_id,name,site_id,parent_id,level)
		categ = Category.new
		categ.category_id = category_id
		categ.category_name = name
		categ.site_id = site_id
		categ.parent_id = parent_id
		categ.level = level
		categ.save
	end

	def get_mongodb_connection()
		db = URI.parse(ENV['MONGOHQ_URL'])
		db_name = db.path.gsub(/^\//, '')
		db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
		db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)	
		return db_connection
	end
end