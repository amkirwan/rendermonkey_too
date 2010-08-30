require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'

DataMapper::Logger.new($stdout, :debug)

configure :development do 
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/secure_pdf_development.sqlite3")
end

configure :test do
  DataMapper.setup(:default, 'sqlite3::memory:')
  DataMapper.auto_migrate!
end

class LoginApi
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String, :unique => true, :required => true
  property :api_key,      String, :unique => true, :required => true
  property :hash_key,     String, :unique => true, :required => true
  property :created_at,   DateTime
  property :updated_at,   DateTime
  
  validates_format_of :name, :with => /[\w\s\d]+/
  validates_format_of :api_key, :with => /^[\w\d]+$/
  validates_format_of :hash_key, :with => /^[\w\d\/+]+=$/

end

DataMapper.auto_upgrade!