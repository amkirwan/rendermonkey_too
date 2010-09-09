require 'rubygems'
require 'dm-core'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-serializer' 
require 'dm-sqlite-adapter'

DataMapper::Logger.new($stdout, :debug)  

configure :production do 
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/secure_pdf.sqlite3")
end

configure :development do 
  DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/secure_pdf_development.sqlite3")
end

configure :test do
  DataMapper.setup(:default, 'sqlite3::memory:')
  DataMapper.auto_migrate!
end

class ApiSecureKey
  include DataMapper::Resource
  property :id,           Serial
  property :app_name,     String, :unique => true, :required => true
  property :api_key,      String, :unique => true, :required => true
  property :hash_key,     String, :unique => true, :required => true
  property :created_at,   DateTime
  property :created_on,   Date
  
  property :updated_at,   DateTime
  property :updated_on,   Date
  
  validates_format_of :app_name, :with => /^[\w\s\d]+$/
  validates_format_of :api_key, :with => /^[\w\d]+$/
  validates_format_of :hash_key, :with => /^[\w\d\/+]+=$/

end

DataMapper.auto_upgrade!