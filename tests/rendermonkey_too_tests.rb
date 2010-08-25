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
    edit_params(nil, {"timestamp" => Time.now.utc.iso8601})

    post '/generate', @params
    assert_equal url_test('/generate'), last_request.url
    assert last_response.ok?
    assert last_response.content_type, 'application/pdf'
  end
  
  ## failure tests
  def test_generate_fail_api_key
    edit_params(nil, "api_key" => "abcd")
 
    e = assert_raise(RuntimeError) { post '/generate', @params }
    assert_match /API key error: API key does not exist or is incorrect/i, e.message
  end
  
  def test_generate_fail_timestamp
    edit_params(nil, "timestamp" => "2010-08-22T00:24:46Z")
    e = assert_raise(RuntimeError) { post '/generate', @params }
    assert_match /Too much time has passed. Request will need to be regenerated/i, e.message
    
    edit_params(nil, "timestamp" => "bad-timestamp")
    e = assert_raise(RuntimeError) { post '/generate', @params }
    assert_match /Incorrect timestamp format/i, e.message
  end
  
  def test_generate_fail_wrong_signature
    edit_params("sQQTe93eWcpV4Gr5HDjKUh8vu2aNDOvn3+suH1Tc411=")
    
    e = assert_raise(RuntimeError) { post '/generate', @params }
    assert_match /An error occured max sure you are using the correct api_key and hash_key/i, e.message
  end
  
  def test_sk
    assert @sk.signature_match(@login_api, @params)
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
    signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('SHA256'), @hash_key, @params["page"])).chomp
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