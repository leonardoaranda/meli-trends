class TrendsController < ApplicationController
	#Needs refactor. Decouple.
	def index_trends()
		document = {}
		db = get_mongodb_connection()
		coll = db['category_trends']
		trends_to_index = coll.find({:status => nil})
		trends_to_index.each do |category_trends|
			documents = []
			ids_to_update = []
			category_trends['trends'].each do |trend|
				document = {
					:object_id => category_trends['_id'],
					:category_id => category_trends['category_id'],
					:category_name => category_trends['category_name'],
					:site_id => category_trends['site_id'],
					:snapshot => category_trends['snapshot'],
					:keyword => trend['keyword'],
					:url => trend['url'],
					:order => trend['order']
				}
				ids_to_update << category_trends['_id']
				documents << document
			end
			documents_to_index = {
				:data => documents
			}
			index_elasticsearch_document(documents_to_index)
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
		client = Elasticsearch::Client.new host: elasticsearch_url
		return client
	end

	def index_elasticsearch_document(documents_to_index)
		client = get_elasticsearch_client()
		client.index index: 'meli_trends', type: 'trend', body: documents_to_index
	end

end
