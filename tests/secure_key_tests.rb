ENV['RACK_ENV'] = "test"

$LOAD_PATH << File.join(Dir.getwd, "..")
require 'rubygems'
require 'test/unit'
require 'rack/test'
require 'rendermonkey_too'


class SecureKeyTests < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  def test_generate_api_key_not_equal
    sk = SecureKey::Digest.new.generate_api_key
    sk2 = SecureKey::Digest.new.generate_api_key 
    
    assert_not_equal sk, sk2
  end
  
  def test_generate_api_key_length
    sk = SecureKey::Digest.new.generate_api_key
    
    assert_equal sk.length, 8
  end
  
  def test_generate_hash_key_not_equal
    hk = SecureKey::Digest.new.generate_hash_key
    hk2 = SecureKey::Digest.new.generate_hash_key 
    
    assert_not_equal hk, hk2
  end
  
  def test_generate_hash_key_length
    hk = SecureKey::Digest.new.generate_hash_key
    
    assert_equal Base64.decode64(hk).size, 32
  end
  
  def test_signature_SHA256
    hk = @sk.generate_hash_key
    
    signature = @sk.signature('SHA256', hk, @params["page"])
    assert_equal Base64.decode64(signature).size, 32
  end
  
  def test_signature_equal
    hk = @sk.generate_hash_key
    
    signature = @sk.signature('SHA256', hk, @params["page"])
    signature2 = @sk.signature('SHA256', hk, @params["page"])
    assert_equal signature, signature2
  end
  
  def test_signature_not_equal
    hk = @sk.generate_hash_key
    hk2 = @sk.generate_hash_key
    
    signature = @sk.signature('SHA256', hk, @params["page"])
    signature2 = @sk.signature('SHA256', hk2, @params["page"])
    assert_not_equal signature, signature2
  end
  
  def test_assigns_instance_variables
    edit_params(nil, {"timestamp" => "2010-08-22T00:24:46Z", "signature" => "abcdefg"})
    
    @sk.params_signature = @params["signature"]
    assert_equal @sk.params_signature, @params["signature"]
    
    @sk.canonical_querystring = @params
    assert_equal @sk.canonical_querystring, "api_key=835a3161dc4e71b&page=<b>Hello</b>, World!&timestamp=2010-08-22T00:24:46Z".chomp
  end
  
  def test_bad_signature
    @sk.params_signature = @params["signature"]
    assert_not_equal @sk.params_signature, "abc"
  end
  
  def test_assigns_timestamp
    @sk.params_timestamp = @params["timestamp"]
    
    assert_kind_of Time, @sk.params_timestamp
    assert_equal Time.parse(@params["timestamp"]), @sk.params_timestamp
 end
 
  def test_timestamp_raised_bad_format
    edit_params(nil, {"timestamp" => "bad-timestamp"})
    
    e = assert_raise(RuntimeError) { @sk.params_timestamp = @params["timestamp"] }
    assert_match /Incorrect timestamp format/i, e.message
 end
 
  def test_timestamp_raise_time_diff_too_great
   edit_params(nil, {"timestamp" => "2010-08-22T00:24:46Z"})
  
   e = assert_raise(RuntimeError) { @sk.signature_match(@login_api, @params) }
   assert_match /Too much time has passed. Request will need to be regenerated/i, e.message
 end
  
  def test_signature_match 
    assert_equal @params["signature"], @sk.signature("SHA256", @login_api["hash_key"], @params["page"])
  end
  
  def test_signature_match_fail
    edit_params("abcdefg", {})

    assert_not_equal @params["signature"], @sk.signature("SHA256", @login_api["hash_key"], @params["page"])
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