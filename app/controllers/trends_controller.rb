class TrendsController < ApplicationController
	#Needs refactor. Decouple.
	def index_trends()
		db = get_mongodb_connection()
		coll = db['category_trends']
		trends_to_index = coll.find({:status => nil})
		trends_to_index.each do |category_trends|
			puts 'Trying to index category '+category_trends['category_id']
			ids_to_update = []
			documents = []
			category_trends['trends'].each do |trend|
				document = {
					:object_id => category_trends['_id'],
					:category_id => category_trends['category_id'],
					:category_name => category_trends['category_name'],
					:site_id => category_trends['site_id'],
					:snapshot => category_trends['snapshot'],
					:keyword => trend['keyword'],
					:url => trend['url'],
					:order => trend['order'],
					:_type => 'trend'
				}
				ids_to_update << category_trends['_id']
				documents << document
			end
			index_elasticsearch_document(documents) unless documents.length < 1
			puts 'Category '+category_trends['category_id']+' was succesfully indexed'
			coll.update({'_id' => {'$in' => ids_to_update}},{'$set'=>{'status'=>'indexed'}})
			puts 'Category flagged as indexed'
		end
	end

	def get_mongodb_connection()
		db = URI.parse(ENV['MONGOHQ_URL'])
		db_name = db.path.gsub(/^\//, '')
		db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
		db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)	
		return db_connection
	end	

	def get_elasticsearch_client()
		elasticsearch_url = ENV['ELASTICSEARCH_URL']
		client = Stretcher::Server.new('http://'+elasticsearch_url)
		return client
	end

	def index_elasticsearch_document(documents)
		puts 'ok index'
		client = get_elasticsearch_client()
		client.index(:meli_trends).bulk_index(documents)
	end

	def trend_map_processor()
		map = Hash.new
		db = get_mongodb_connection()
		coll_tl = db['trends_timeline']
		coll_tl.drop()
		coll = db['category_trends']
		coll.find().batch_size(100).each do |category_trends|
			category_trends['trends'].each do |trend|
				keyword = trend['keyword'].gsub(' ','_')
				id_categ = category_trends['category_id'].to_s+'_'+keyword
				if !map.has_key?(id_categ)
					map[id_categ] = Hash.new
					map[id_categ]['history'] = Array.new
				end
				map[id_categ]['history'] << {
					:order => trend['order'],
					:snapshot => category_trends['snapshot']
				}
			end
		end
		documents = []
		map.to_a.each do |t|
			document = {
				:trend => t[0],
				:history => t[1]['history']
			}
			documents << document
		end
		coll_tl.insert(documents)
	end

	def trend_reduce_processor()
		db = get_mongodb_connection()
		coll = db['trends_timeline']
		trend_slope = nil
		last_history = nil
		trends_slope = []
		coll.find().batch_size(100).each do |trend|
			history = trend['history']
			history = history.sort_by {|vn| vn[:snapshot]}.reverse!
			x=1
			sum_x=0
			sum_y=0
			sum_xy=0
			xx = 0
			sum_xx = 0
			history.each do |h|
				y = h['order'].to_i
				#puts 'compute trend '+trend['trend']
				#puts h['snapshot']
				#puts 'x='+x.to_s
				#puts 'y='+y.to_s				
				xy = x*y
				sum_y += y 
				sum_x += x
				sum_xy += xy
				sum_xx += x*x
				x+=1
			end
			n=x-1
			#puts '----do calculation'
			#puts 'N='+n.to_s
			#puts 'sum_xy='+sum_xy.to_s
			#puts 'sum_x='+sum_x.to_s
			#puts 'sum_y='+sum_y.to_s
			#puts 'sum_xx='+sum_xx.to_s
			if n > 1
				trend_slope = (n*sum_xy-sum_x*sum_y)/(n*sum_xx-sum_x*sum_x) 
			end
			category_id = trend['trend'].split('_')[0]
			trend_keyword = trend['trend'].gsub(category_id,' ').gsub('_',' ')
			trends_slope << {
				:category_id => category_id,
				:trend => trend_keyword,
				:data => n,
				:slope => trend_slope,
				:compute_timestamp => Time.now
			}
		end
		coll = db['trends_slope']
		coll.drop()
		coll.insert(trends_slope)
	end
end