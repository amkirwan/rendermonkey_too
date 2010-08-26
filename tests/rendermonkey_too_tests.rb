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
    assert last_response.ok?
  end
   
  def test_new
    get '/new'
    assert_equal url_test("/new"), last_request.url
    assert last_response.ok?
    assert last_response.body.include?("App Name")
  end
  
  def test_create
    post '/create', {"app_name" => "TestCreate"}
    assert_equal url_test("/create"), last_request.url
    assert last_response.ok?
    assert last_response.body.include?("TestCreate")
  end
  
  ### Test Generate
  def test_generate_pass
    edit_params(nil, "timestamp" => Time.now.utc.iso8601)

    post '/generate', @params
    assert_equal url_test('/generate'), last_request.url
    assert last_response.ok?
    assert_equal last_response.content_type, 'application/pdf'
  end
  
  ## failure tests
  def test_generate_fail_login_api_not_found
    @login_api.destroy
 
    post '/generate', @params
    assert_equal url_test('/generate'), last_request.url
    assert last_response.ok?
    assert_equal last_response.content_type, "text/html"
    assert_equal last_response.body, "API key error: API key does not exist or is incorrect"
  end
  
  def test_generate_missing_param
    @params.delete("timestamp")
 
    post '/generate', @params
    assert_equal url_test('/generate'), last_request.url
    assert last_response.ok?
    assert_equal last_response.content_type, "text/html"
    assert_equal last_response.body, "Incorrect parameters"
  end
  
  def test_generate_timestamp_too_old
    edit_params(nil, "timestamp" => "2010-08-22T00:24:46Z")
 
    post '/generate', @params
    assert_equal url_test('/generate'), last_request.url
    assert last_response.ok?
    assert_equal last_response.content_type, "text/html"
    assert_equal last_response.body, "Too much time has passed. Request will need to be regenerated"
  end
  
  def test_generate_timestamp_incorrect_format
    edit_params(nil, "timestamp" => "bad-format")
 
    post '/generate', @params
    assert_equal url_test('/generate'), last_request.url
    assert last_response.ok?
    assert_equal last_response.content_type, "text/html"
    assert_equal last_response.body, "Incorrect timestamp format"
  end
  
  #def test_generate_missing_param
  #  @params.delete("signature")
 
  #  post '/generate', @params
  #  assert_equal url_test('/generate'), last_request.url
  #  assert last_response.ok?
  #  assert_equal last_response.content_type, "text/html"
  #  assert_equal last_response.body, "Incorrect parameters"
  #end
    
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
    
    @api = {"name" => "test_valid_login_api", 
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
    defaults = {"name" => "test_valid_login_api", 
                "api_key" => "835a3161dc4e71b", 
                "hash_key" => "sQQTe93eWcpV4Gr5HDjKUh8vu2aNDOvn3+suH1Tc4P4="}
    defaults.merge!(options)
    @login_api.update(defaults)
  end
  
end