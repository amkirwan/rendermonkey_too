# needs to run first
ENV['RACK_ENV'] = "test"

require File.expand_path('../test_helper', __FILE__) 

class TestRendermonkeyToo < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end   
  
  def test_login
    post '/api_secure_key/auth', {:username => "admin", :password => "test_password"}
    assert_equal last_response.status, 302 
  end    
  
  def test_logout
    get "/api_secure_key/logout"
    
    assert_equal last_response.status, 302 
  end
  
  def test_index
    login
    get '/'
    
    assert_equal url_test, last_request.url
    assert_equal last_response.status, 302
    assert_equal url_test("/api_secure_key"), last_response.headers["Location"]
  end
  
  # get by all
  def test_get_all      
    login
    get "/api_secure_key"
    
    assert last_response.ok? 
    assert_equal "text/html;charset=utf-8", last_response.content_type
  end
  
  #new 
  def test_new 
    login
    get '/api_secure_key/new'
    
    assert_equal url_test("/api_secure_key/new"), last_request.url
    assert last_response.ok?
    assert last_response.body.include?("App Name")
  end
  
  # create
  def test_create  
    login
    post '/api_secure_key/create', {"app_name" => "TestCreate"}
    
    assert_equal url_test("/api_secure_key/create"), last_request.url
    assert_equal last_response.status, 302
  end
  
 # edit
 def test_edit          
   login
   get "/api_secure_key/#{@api_secure_key.id}/edit"
   
   assert_equal url_test("/api_secure_key/#{@api_secure_key.id}/edit"), last_request.url
   assert last_response.ok?
   assert last_response.body.include?("Update")
 end
 
 
 #Update
 def test_update 
   login
   put "/api_secure_key/update", {"id" => "#{@api_secure_key.id}", "app_name" => "TestUpdate"}
   
   assert_equal url_test("/api_secure_key/update"), last_request.url
   assert_equal last_response.status, 302
   assert_equal url_test("api_secure_key/#{@api_secure_key.id}"), last_response.headers["Location"]
 end
 
 
 #Delete
 def test_delete    
   login
   delete "/api_secure_key/destroy", {"id" => "#{@api_secure_key.id}"}
   
   assert_equal url_test("/api_secure_key/destroy"), last_request.url
   assert_equal last_response.status, 302
   assert_equal url_test("api_secure_key"), last_response.headers["Location"]
 end
 
 
  # get id
  def test_get_by_id    
    login
    get "/api_secure_key/show/#{@api_secure_key.id}"
    
    assert_equal url_test("api_secure_key/show/#{@api_secure_key.id}"), last_request.url
    assert last_response.ok?
    assert_equal last_response.content_type, "text/html;charset=utf-8"
  end
  
  
  def test_get_by_id_failure 
    login
    get "/api_secure_key/show/00000"
    
    assert_equal last_response.status, 404
    assert_equal last_response.content_type, "text/html;charset=utf-8"
  end
  
  
  # get by api_key
  def test_get_by_api_key
    login
    get "/api_secure_key/api_key/#{@api_secure_key.api_key}"
    
    assert last_response.ok?
    assert_equal last_response.content_type, "text/html;charset=utf-8"
  end
  
  def test_get_by_api_key_failure 
    login
    get "/api_secure_key/api_key/000000"
    
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
  
  def test_generate_fail_api_secure_key_not_found
    @api_secure_key.destroy
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

  def setup
    @sk = SecureKey::Digest.new
    @params = {"timestamp" => "#{Time.now.utc.iso8601}", 
               "page"=>"<b>Hello</b>, World!", 
               "api_key"=>"835a3161dc4e71b", 
               "name" => "FOOBAR"}
               
    @hash_key = "sQQTe93eWcpV4Gr5HDjKUh8vu2aNDOvn3+suH1Tc4P4=" 
    @sk.canonical_querystring = @params
    signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), @hash_key, @sk.canonical_querystring)).chomp
    @params["signature"] = signature
    
    @api = {"app_name" => "test_valid_api_secure_key", 
            "api_key" => "835a3161dc4e71b", 
            "hash_key" => "sQQTe93eWcpV4Gr5HDjKUh8vu2aNDOvn3+suH1Tc4P4="}
    @api_secure_key = ApiSecureKey.new(@api)
    @api_secure_key.save     
  end
  
  def teardown
    @sk = nil
    @params = nil
    @api_secure_key.destroy
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
  
  def login
    post '/api_secure_key/auth', {:username => "admin", :password => "test_password"}
  end     
  
  def xml_request(params)     
    @xml_params = "<api_secure_key><id>#{@api_secure_key.id}</id><api_key>#{@api_secure_key.api_key}</api_key></api_secure_key>"  
    signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), @hash_key, @xml_params)).chomp
    @xml_params += "<signature>#{signature}</signature>"
  end

  def edit_params(hash_key=nil, options={})
    @params.merge!(options)
    if !hash_key.nil?
      signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), hash_key, @params["page"])).chomp
      @params["signature"] = signature
    end
    @params
  end
  
  def update_api_secure_key(options={})
    defaults = {"app_name" => "test_valid_api_secure_key", 
                "api_key" => "835a3161dc4e71b", 
                "hash_key" => "sQQTe93eWcpV4Gr5HDjKUh8vu2aNDOvn3+suH1Tc4P4="}
    defaults.merge!(options)
    @api_secure_key.update(defaults)
  end
  
end
