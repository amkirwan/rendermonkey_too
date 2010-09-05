# needs to run first
ENV['RACK_ENV'] = "test"

$LOAD_PATH << File.join(Dir.getwd, "..")
require 'rubygems'
require 'test/unit'
require 'rack/test'
require 'rendermonkey_too'

class RendermonkeyTooTests < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  def test_index
    get '/'
    
    assert_equal url_test, last_request.url
    assert last_response, 302
    assert_equal "/login_api", last_response.headers["Location"]
  end
  
  # get by all
  def test_get_all
    get "/login_api"
    
    assert last_response.ok?
    assert_equal last_response.content_type, "text/html;charset=utf-8"
  end
  
  def test_get_by_api_key_xml
    get "/login_api/all.xml"
    
    assert last_response.ok?
    assert_equal last_response.content_type, "application/xml;charset=utf-8"
  end
  
  #new 
  def test_new
    get '/login_api/new'
    
    assert_equal url_test("/login_api/new"), last_request.url
    assert last_response.ok?
    assert last_response.body.include?("App Name")
  end
  
  # create
  def test_create
    post '/login_api/create', {"app_name" => "TestCreate"}
    
    assert_equal url_test("/login_api/create"), last_request.url
    assert last_response, 302
  end
  
  def test_create_xml
    header 'Content-Type', 'application/xml'
    post '/login_api/create.xml', '<login_api><app_name>another app</app_name></login_api>'
    
    assert last_response, 201
    assert_equal "application/xml;charset=utf-8", last_response.headers["Content-Type"]
  end
  
 # edit
 def test_edit
   get "/login_api/#{@login_api.id}/edit"
   
   assert_equal url_test("/login_api/#{@login_api.id}/edit"), last_request.url
   assert last_response.ok?
   assert last_response.body.include?("Update")
 end
 
 
 #Update
 def test_update
   put "/login_api/update", {"id" => "#{@login_api.id}", "app_name" => "TestUpdate"}
   
   assert_equal url_test("/login_api/update"), last_request.url
   assert last_response, 302
   assert_equal "/login_api/#{@login_api.id}", last_response.headers["Location"]
 end
 
 def test_update_xml
   header 'Content-Type', 'application/xml'
   put "/login_api/update.xml", "<login_api><id type='integer'>#{@login_api.id}</id><app_name>new app</app_name></login_api>"
   
   assert_equal url_test("/login_api/update"), last_request.url
   assert last_response, 202
   assert_equal "application/xml;charset=utf-8", last_response.headers["Content-Type"]
 end
 
 #Delete
 def test_delete
   delete "/login_api/destroy", {"id" => "#{@login_api.id}"}
   
   assert_equal url_test("/login_api/destroy"), last_request.url
   assert last_response, 302
   assert_equal "/login_api", last_response.headers["Location"]
 end
 
 def test_update_xml
   header 'Content-Type', 'application/xml'
   put "/login_api/destroy.xml", "<login_api><id type='integer'>#{@login_api.id}</id></login_api>"
   assert_equal url_test("/login_api/destroy"), last_request.url
   assert last_response, 200
   assert_equal "application/xml;charset=utf-8", last_response.headers["Content-Type"]
 end

 
 
  # get id
  def test_get_by_id
    get "/login_api/show/#{@login_api.id}"
    
    assert_equal url_test("/login_api/show/#{@login_api.id}"), last_request.url
    assert last_response.ok?
    assert_equal last_response.content_type, "text/html;charset=utf-8"
  end
  
  def test_get_by_id_xml
    get "/login_api/show/#{@login_api.id}.xml"
    
    assert last_response.ok?
    assert_equal last_response.content_type, "application/xml;charset=utf-8"
  end
  
  def test_get_by_id_failure
    get "/login_api/show/00000"
    
    assert_equal last_response.status, 404
    assert_equal last_response.content_type, "text/html;charset=utf-8"
  end
  
  # get by app_name
  def test_get_by_app_name
    get "/login_api/app_name/#{@login_api.app_name}"
    
    assert last_response.ok?
    assert_equal last_response.content_type, "text/html;charset=utf-8"
  end
  
  def test_get_by_api_name_xml
    get "/login_api/app_name/#{@login_api.app_name}.xml"
    
    assert last_response.ok?
    assert_equal last_response.content_type, "application/xml;charset=utf-8"
  end
  
  def test_get_by_app_name_failure
    get "/login_api/app_name/shouldnotexist"
    
    assert_equal last_response.status, 404
    assert_equal last_response.content_type, "text/html;charset=utf-8"
  end
  
  # get by api_key
  def test_get_by_api_key
    get "/login_api/api_key/#{@login_api.api_key}"
    
    assert last_response.ok?
    assert_equal last_response.content_type, "text/html;charset=utf-8"
  end
  
  def test_get_by_api_key_xml
    get "/login_api/api_key/#{@login_api.api_key}.xml"
    
    assert last_response.ok?
    assert_equal last_response.content_type, "application/xml;charset=utf-8"
  end
  
  def test_get_by_api_key_failure
    get "/login_api/api_key/000000"
    
    assert_equal last_response.status, 404
    assert_equal last_response.content_type, "text/html;charset=utf-8"
  end
  
  
  ### Test Generate
  def test_generate_pass
    edit_params(nil, "timestamp" => Time.now.utc.iso8601)
    post '/generate', @params
    
    assert_equal url_test('/generate'), last_request.url
    assert last_response.ok?
    assert_equal last_response.content_type, 'application/pdf'
  end
  
  ## Test Generate Failures
  def test_generate_fail_authentication
    sig = @params["signature"]
    sig.gsub!(/\d/, 'A')
    edit_params(nil, 'signature' => sig)
    post '/generate', @params
    
    assert_equal last_response.status, 412
    assert_equal last_response.content_type, "text/html;charset=utf-8"
    assert_equal last_response.body, "Signature failed"
  end
  
  def test_generate_fail_login_api_not_found
    @login_api.destroy
    post '/generate', @params
    
    assert_equal last_response.status, 412
    assert_equal last_response.content_type, "text/html;charset=utf-8"
    assert_equal last_response.body, "api_key missing or incorrect"
  end

  def test_generate_fail_missing_param
    @params.delete("page")
    post '/generate', @params
    
    assert_equal last_response.status, 412
    assert_equal last_response.content_type, "text/html;charset=utf-8"
    assert_equal last_response.body, "Incorrect or missing parameters"
  end
  
  def test_generate_fail_hashtype
    edit_params(nil, "signature" => "abcdefg")
    post '/generate', @params
    
    assert_equal last_response.status, 412
    assert_equal last_response.content_type, "text/html;charset=utf-8"
    assert_equal last_response.body, "Incorrect hashtype"
  end
  
  def test_generate_time_diff
    edit_params(nil, "timestamp" => "2010-08-22T00:24:46Z")
    post '/generate', @params
    
    assert_equal last_response.status, 412
    assert_equal last_response.content_type, "text/html;charset=utf-8"
    assert_equal last_response.body, "Too much time has passed. Request will need to be regenerated"
  end

    
  private 
  
  def url_test(path=nil)
    site = "http://example.org"
    if path.nil?
      site + "/"
    elsif /^\//.match(path)
      site + path
    else
      site + '/' + path
    end
  end
  
  def setup
    @sk = SecureKey::Digest.new
    @params = {"timestamp" => "#{Time.now.utc.iso8601}", 
               "page"=>"<b>Hello</b>, World!", 
               "api_key"=>"835a3161dc4e71b"}
               
    @hash_key = "sQQTe93eWcpV4Gr5HDjKUh8vu2aNDOvn3+suH1Tc4P4=" 
    @sk.canonical_querystring = @params
    signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('SHA256'), @hash_key, @sk.canonical_querystring)).chomp
    @params["signature"] = signature
    
    @api = {"app_name" => "test_valid_login_api", 
            "api_key" => "835a3161dc4e71b", 
            "hash_key" => "sQQTe93eWcpV4Gr5HDjKUh8vu2aNDOvn3+suH1Tc4P4="}
    @login_api = LoginApi.new(@api)
    @login_api.save
  end
  
  def teardown
    @sk = nil
    @params = nil
    @login_api.destroy
  end
  
  private

  def edit_params(hash_key=nil, options={})
    @params.merge!(options)
    if !hash_key.nil?
      signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('SHA256'), hash_key, @params["page"])).chomp
      @params["signature"] = signature
    end
    @params
  end
  
  def update_login_api(options={})
    defaults = {"app_name" => "test_valid_login_api", 
                "api_key" => "835a3161dc4e71b", 
                "hash_key" => "sQQTe93eWcpV4Gr5HDjKUh8vu2aNDOvn3+suH1Tc4P4="}
    defaults.merge!(options)
    @login_api.update(defaults)
  end
  
end