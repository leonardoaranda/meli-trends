class MercadolibreController < ApplicationController

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

	def main_categories(site_id)
		categories = get_site_categories(site_id)
		categories.each do |category|
			category_trends = get_category_trends(category['id'],site_id)
			puts '#####'+category['name']+'#####'			
			puts category_trends
			build_tree(category['id'],nil,nil)
		end
	end

	def build_tree(category_id,parent_id,parent_trends)
		children_categories = get_children_categories(category_id)
		children_categories.each do |children|
			if parent_id != nil and parent_trends == nil
				puts 'SKIPPING '+children['id']+' '+children['name']
				next
			end
			children_category_trends = get_category_trends(children['id'],'MLA')
			puts '#####'+children['name']+'#####'
			puts children_category_trends
			build_tree(children['id'],category_id,children_category_trends)
		end
	end

end
