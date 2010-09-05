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

error do
  e = request.env['sinatra.error']
  puts "#{e.class}: #{e.message}\n#{e.backtrace.join("\n  ")}"
end

before do
  if (request.path_info == '/generate' || request.path_info == 'create')
    @sk = SecureKey::Digest.new
  end
end

helpers do
  
  def base_url
    if Sinatra::Application.port == 80
      "http://#{Sinatra::Application.bind}/"
    else
      "http://#{Sinatra::Application.bind}:#{Sinatra::Application.port}/"
    end
  end
  
  def login_api_url(lp)
    "#{base_url}login_api/#{lp.id}"
  end
  
  def process_xml(xml)
    xml_params = Crack::XML.parse(xml)
    xml_params = xml_params.delete("login_api") if xml_params.has_key?("login_api")
    params.merge!(xml_params)
  end
  
end

get '/' do
  redirect '/login_api'
end

get '/login_api' do
  la = LoginApi.all
  halt [ 404, "Api Key not found" ] unless la

  respond_to do |format|
    format.html { haml :show_all, :locals => { :la => la } }
    format.xml { la.to_xml }
  end
end

#show
get '/login_api/show/:id' do
  la = LoginApi.get(params[:id])
  halt [ 404, "LoginApi not found" ] unless la
  
  respond_to do |format|
    format.html { haml :show, :locals => { :la => la } }
    format.xml { la.to_xml }
  end
end

#show_by_app_name
get '/login_api/app_name/:app_name' do
  la = LoginApi.first(:app_name => params[:app_name])
  halt [ 404, "Api Key not found" ] unless la

  respond_to do |format|
    format.html { haml :show, :locals => { :la => la } }
    format.xml { la.to_xml }
  end
end

#show_by_api_key
get '/login_api/api_key/:api_key' do
  la = LoginApi.first(:api_key => params[:api_key])
  halt [ 404, "Api Key not found" ] unless la
  
  respond_to do |format|
    format.html { haml :show, :locals => { :la => la } }
    format.xml { la.to_xml }
  end
end

#new
get '/login_api/new' do
  haml :new
end

#create
post '/login_api/create' do
  if request.content_type == "application/xml"
    process_xml(request.body.read.to_s)
  end
  
  la = LoginApi.new(:app_name => params["app_name"],
                    :api_key => SecureKey::Generate.generate_api_key,
                    :hash_key => SecureKey::Generate.generate_hash_key)
  if la.save
    respond_to do |format|
      format.html { redirect "/login_api/show/#{la.id}"}
      format.xml do 
        status(201)
        response['Location'] = login_api_url(la)
        la.to_xml
      end
    end
  else
    status(412)
    "Error: Creating Login API Key: #{la.errors.on(:app_name)}"
  end
end 

# edit /login_api/1/edit
get '/login_api/:id/edit' do
    la = LoginApi.get(params["id"])
    haml :edit, :locals => { :la => la }
end


# udpate /login_api/update
put '/login_api/update' do
  if request.content_type == "application/xml"
    process_xml(request.body.read.to_s)
  end
  la = LoginApi.get(params[:id])
  la.api_key = SecureKey::Generate.generate_api_key if params[:api_key] == "checked"
  la.hash_key = SecureKey::Generate.generate_hash_key if params[:hash_key] == "checked"
  la.app_name = params["app_name"]
  
  if la.save
    respond_to do |format|
      format.html { redirect "/login_api/#{la.id}" }
      format.xml do 
        status(202)
        la.to_xml
      end
    end
  else
    status(412)
    "Error updating Login Api"
  end
end

delete '/login_api/destroy' do
  if request.content_type == "application/xml"
    process_xml(request.body.read.to_s)
  end
  la = LoginApi.get(params[:id])
  if la.destroy
    respond_to do |format|
      format.html { redirect "/login_api" }
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
  login_api = LoginApi.first(:api_key => params["api_key"])

  if @sk.signature_match(login_api, params)
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


  
	