require 'rubygems'
require 'sinatra'
require 'haml'
require 'pry'

$:.unshift File.join(File.dirname(__FILE__), "lib")
require 'secure_key'
require 'pdf'
require 'models'

use Rack::MethodOverride   

enable :sessions

configure do 
  set :login, OpenStruct.new( 
    :admin_username => "admin", 
    #:admin_password => "Enter Deploy Password",
    :admin_cookie_key => "rendermonkey_too_admin",
    :admin_cookie_value => SecureKey::Generate.random_generator({:length => 64}).to_s  #uncomment to deploy
  ) 

  if ENV['RACK_ENV'] == 'test'
    settings.login.admin_password = 'test_password'
  else
    settings.login.admin_password = 'password'
  end
  
  set :session_secret, '51d3e1cf7aa1a3d3'
  set :views, File.dirname(__FILE__) + '/views'
  set :wkhtmltopdf_cmd, "i386" #"amd64"
end 

error do
  e = request.env['sinatra.error']
  puts "#{e.class}: #{e.message}\n#{e.backtrace.join("\n  ")}"
end    

before do
  if request.path_info == '/generate' || request.path_info == 'create'
    @sk = SecureKey::Digest.new
  end 
  
  protected! unless request.path_info == '/generate' || request.path_info == '/api_secure_key/auth'
end

helpers do
  def base_url
    if Sinatra::Application.port == 80
      "http://#{Sinatra::Application.bind}/"
    else
      "http://#{Sinatra::Application.bind}:#{Sinatra::Application.port}/"
    end
  end
  
  def api_secure_key_url(lp)
    "#{base_url}api_secure_key/#{lp.id}"
  end
  
  def protected!         
    unless session[settings.login.admin_cookie_key] == settings.login.admin_cookie_value
      redirect '/api_secure_key/auth'
    end
  end   
end

get '/' do
  redirect '/api_secure_key'
end    

get '/api_secure_key/auth' do
  haml :auth
end

post '/api_secure_key/auth' do     
  if params[:username] == settings.login.admin_username && params[:password] == settings.login.admin_password      
    session[settings.login.admin_cookie_key] = settings.login.admin_cookie_value  
    redirect '/api_secure_key'
  else
    halt 401, 'Not authorized'
  end
end   


get '/api_secure_key/logout' do
  session.clear
  redirect '/api_secure_key/auth'
end

get '/api_secure_key' do
  ask = ApiSecureKey.all
  halt not_found("Api Key not found") unless ask
  
  haml :show_all, :locals => { :ask => ask }
end

#show
get '/api_secure_key/show/:id' do
  ask = ApiSecureKey.get(params[:id])
  halt not_found("ApiSecureKey not found") unless ask
  
  haml :show, :locals => { :ask => ask }
end

#show_by_api_key
get '/api_secure_key/api_key/:api_key' do
  ask = ApiSecureKey.first(:api_key => params[:api_key])
  halt not_found("Api Key not found") unless ask

  haml :show, :locals => { :ask => ask }
end

#new
get '/api_secure_key/new' do
  haml :new
end

#create
post '/api_secure_key/create' do
  ask = ApiSecureKey.new(:app_name => params["app_name"],
                    :api_key => SecureKey::Generate.generate_api_key,
                    :hash_key => SecureKey::Generate.generate_hash_key)
  if ask.save
    redirect "/api_secure_key/show/#{ask.id}"
  else
    status(412)
    "Error: Creating Login API Key: #{ask.errors.on(:app_name)}"
  end
end 

# edit /api_secure_key/1/edit
get '/api_secure_key/:id/edit' do
    ask = ApiSecureKey.get(params["id"])
    haml :edit, :locals => { :ask => ask }
end


# udpate /api_secure_key/update
put '/api_secure_key/update' do
  ask = ApiSecureKey.get(params[:id])
  ask.api_key = SecureKey::Generate.generate_api_key if params[:api_key] == "checked"
  ask.hash_key = SecureKey::Generate.generate_hash_key if params[:hash_key] == "checked"
  ask.app_name = params["app_name"]
  
  if ask.save
    redirect "/api_secure_key/#{ask.id}"
  else
    status(412)
    "Error updating Login Api"
  end
end

delete '/api_secure_key/destroy' do
  ask = ApiSecureKey.get(params[:id])
  if ask.destroy
    redirect "/api_secure_key"
  else
    status(412)
    "Error destroying Login Api"
  end   
end


post '/generate' do
  api_secure_key = ApiSecureKey.first(:api_key => params["api_key"])

  if @sk.signature_match(api_secure_key, params)    
    report_type = (params["name"].nil? && 'Untitled.pdf') || params["name"] + ".pdf"
    
    pdf = PDF::Generator.generate(settings.wkhtmltopdf_cmd, params)
    response["Content-Type"] = "application/pdf"
    response["Content-Disposition"] = "attachment; filename=#{report_type}"
    response["Content-Length"] = pdf.size.to_s
    response["Content-Transfer-Encoding"] = "binary"
    halt 200, pdf
  else
    status(412)
    puts "*"*10 + @sk.error_message + "*"*10
    @sk.error_message
  end
end
  
	
