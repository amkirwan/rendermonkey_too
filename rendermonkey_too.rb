require 'rubygems'
require 'sinatra'
require 'haml'
require 'sinatra/respond_to'
require 'crack'

$:.unshift File.join(File.dirname(__FILE__), "lib")
require 'secure_key'
require 'pdf'
require 'models'

Sinatra::Application.register Sinatra::RespondTo
use Rack::MethodOverride 
       
configure do
  @@Login = OpenStruct.new( 
    :admin_username => "admin", 
    :admin_password => "changeme",
    :admin_cookie_key => "rendermonkey_too_admin",
    #:admin_cookie_value => SecureKey::Generate.random_generator({:length => 64}).to_s    #uncomment to deploy
    :admin_cookie_value => "abcdefg"   #comment to deploy
  ) 
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
  
  def process_xml(xml)
    xml_params = Crack::XML.parse(xml)
    xml_params = xml_params.delete("api_secure_key") if xml_params.has_key?("api_secure_key")
    params.merge!(xml_params)
  end  
  
  def protected!          
    unless request.cookies[@@Login.admin_cookie_key] == @@Login.admin_cookie_value
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
  puts @@Login.admin_cookie_value
  if params[:username] == @@Login.admin_username && params[:password] == @@Login.admin_password  
    response.set_cookie(@@Login.admin_cookie_key, @@Login.admin_cookie_value)    
    puts "here"
    redirect '/api_secure_key'
  else
    stop [ 401, 'Not authorized' ]
  end
end

get '/api_secure_key' do
  ask = ApiSecureKey.all
  halt not_found("Api Key not found") unless ask

  respond_to do |format|
    format.html { haml :show_all, :locals => { :ask => ask } }
    format.xml { ask.to_xml }
  end
end

#show
get '/api_secure_key/show/:id' do
  ask = ApiSecureKey.get(params[:id])
  halt not_found("ApiSecureKey not found") unless ask
  
  respond_to do |format|
    format.html { haml :show, :locals => { :ask => ask } }
    format.xml { ask.to_xml }
  end
end

#show_by_app_name
get '/api_secure_key/app_name/:app_name' do
  ask = ApiSecureKey.first(:app_name => params[:app_name])
  halt not_found("Api Key not found") unless ask

  respond_to do |format|
    format.html { haml :show, :locals => { :ask => ask } }
    format.xml { ask.to_xml }
  end
end

#show_by_api_key
get '/api_secure_key/api_key/:api_key' do
  ask = ApiSecureKey.first(:api_key => params[:api_key])
  halt not_found("Api Key not found") unless ask
  
  respond_to do |format|
    format.html { haml :show, :locals => { :ask => ask } }
    format.xml { ask.to_xml }
  end
end

#new
get '/api_secure_key/new' do
  haml :new
end

#create
post '/api_secure_key/create' do
  if request.content_type == "application/xml"
    process_xml(request.body.read.to_s)
  end
  
  ask = ApiSecureKey.new(:app_name => params["app_name"],
                    :api_key => SecureKey::Generate.generate_api_key,
                    :hash_key => SecureKey::Generate.generate_hash_key)
  if ask.save
    respond_to do |format|
      format.html { redirect "/api_secure_key/show/#{ask.id}"}
      format.xml do 
        status(201)
        response['Location'] = api_secure_key_url(ask)
        ask.to_xml
      end
    end
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
  if request.content_type == "application/xml"
    process_xml(request.body.read.to_s)
  end
  ask = ApiSecureKey.get(params[:id])
  ask.api_key = SecureKey::Generate.generate_api_key if params[:api_key] == "checked"
  ask.hash_key = SecureKey::Generate.generate_hash_key if params[:hash_key] == "checked"
  ask.app_name = params["app_name"]
  
  if ask.save
    respond_to do |format|
      format.html { redirect "/api_secure_key/#{ask.id}" }
      format.xml do 
        status(202)
        ask.to_xml
      end
    end
  else
    status(412)
    "Error updating Login Api"
  end
end

delete '/api_secure_key/destroy' do
  if request.content_type == "application/xml"
    process_xml(request.body.read.to_s)
  end
  ask = ApiSecureKey.get(params[:id])
  if ask.destroy
    respond_to do |format|
      format.html { redirect "/api_secure_key" }
      format.xml do
        status(200)
        "Delete succeeded"
      end
    end
  else
      status(412)
      "Error destroying Login Api"
    end
  
end


post '/generate' do
  api_secure_key = ApiSecureKey.first(:api_key => params["api_key"])

  if @sk.signature_match(api_secure_key, params)
    pdf_file = PDF::Generator.generate(params)
  
    if params["name"].nil?
      report_type = "Untitl.pdf"
    else
      report_type = params["name"] + ".pdf"
    end
  
    send_file pdf_file,
              :disposition => 'attachment',
              :filename => report_type,
              :type => 'application/pdf'
  else
    status(412)
    puts "*"*10 + @sk.error_message + "*"*10
    @sk.error_message
  end
end

private

def random_generator(opts={})
    opts = {:chars => ('0'..'9').to_a + ('A'..'F').to_a + ('a'..'f').to_a,
            :length => 8, :prefix => '', :suffix => '',
            :verify => true, :attempts => 10}.merge(opts)
    opts[:attempts].times do
        filename = ''
        opts[:length].times do
            filename << opts[:chars][rand(opts[:chars].size)]
        end
        filename = opts[:prefix] + filename + opts[:suffix]
        return filename unless opts[:verify] && File.exists?(filename)
    end
    nil
end


  
	