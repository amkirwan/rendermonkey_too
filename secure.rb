require 'rubygems'
require 'sinatra'
require 'haml'

$:.unshift File.join(File.dirname(__FILE__), "lib")
require 'secure_key'
require 'models'

before do
	@secure_key = SecureKey.load
end

get '/' do
  haml :index
end

get '/new' do
  haml :new
end

post '/create' do
  haml :create, :locals => {:app_name => params[:app_name]}
end
  
	