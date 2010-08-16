require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'

DataMapper::Logger.new($stdout, :debug)

# Database 
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/../db/secure.db")


class LoginApi
  include DataMapper::Resource
  property :id,           Serial
  property :api_key,      String, :unique => true, :required => true
  property :hash_key,     String, :unique => true, :required => true
  property :created_at,   DateTime
  property :updated_at,   DateTime
  

end

class AssociatedApi
  include DataMapper::Resource
  property :id,           Serial
  property :api_key,      String, :unique => true, :required => true
  property :hash_key,     String, :unique => true, :required => true
  property :created_at,   DateTime
  property :updated_at,   DateTime
  
  belongs_to :login_api
end

DataMapper.auto_upgrade!