require 'rubygems'
require 'sinatra'
require 'haml'

$:.unshift File.join(File.dirname(__FILE__), "lib")
require 'secure_key'
require 'models'

error do
  e = request.env['sinatra.error']
  puts "#{e.class}: #{e.message}\n#{e.backtrace.join("\n  ")}"
end

before do
	@secure_key = SecureKey.load
end

get '/' do
  haml :index
end

get '/generate' do
  haml :generate
end

get '/new' do
  haml :new
end

post '/create' do
  haml :create, :locals => {:app_name => params[:app_name]}
end
  
	