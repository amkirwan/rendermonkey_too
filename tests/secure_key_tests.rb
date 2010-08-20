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
    sk = SecureKey::Digest.new
    hk = sk.generate_hash_key
    data = "<b>Hello</b>, World!"
    signature = sk.signature('SHA256', hk, data)
    assert_equal Base64.decode64(signature).size, 32
  end
  
  def test_signature_equal
    sk = SecureKey::Digest.new
    hk = sk.generate_hash_key
    data = "<b>Hello</b>, World!"
    signature = sk.signature('SHA256', hk, data)
    signature2 = sk.signature('SHA256', hk, data)
    assert_equal signature, signature2
  end
  
  def test_signature_not_equal
    sk = SecureKey::Digest.new
    hk = sk.generate_hash_key
    hk2 = sk.generate_hash_key
    data = "<b>Hello</b>, World!"
    signature = sk.signature('SHA256', hk, data)
    signature2 = sk.signature('SHA256', hk2, data)
    assert_not_equal signature, signature2
  end
  
  def test_assigns_instance_variables
    params = {"html"=>"<b>Hello</b>, World!", "signature"=>"abcdefg", "id"=>"12345", "zbar" => "z"}
    sk = SecureKey::Digest.new
    sk.params_signature=(Base64.encode64(params["signature"]))
    assert sk.params_signature == "abcdefg"
    sk.canonical_querystring=(params) 
    assert sk.canonical_querystring == "html=<b>Hello</b>, World!&id=12345&zbar=z"
    sk.params_html=(params["html"])
    assert sk.params_html == "<b>Hello</b>, World!"
  end
  
  def test_signature_match
    sk = SecureKey::Digest.new
    params = {"html"=>"<b>Hello</b>, World!", "api_key"=>"835a3161dc4e71b"}
    login_api = LoginApi.new(:name => "test_valid_login_api",
                             :api_key => "835a3161dc4e71b",
                             :hash_key => "0b81d46ef348de79ea6b9a3bb841db5")
    
    assert login_api.save
    @signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('SHA256'), login_api["hash_key"], params["html"])).chomp
    assert_equal @signature, sk.signature("SHA256", login_api["hash_key"], params["html"])
    login_api.destroy
  end
  
  def test_signature_match_fail
    sk = SecureKey::Digest.new
    params = {"html"=>"<b>Hello</b>, World!", "api_key"=>"835a3161dc4e71b"}
    login_api = LoginApi.new(:name => "test_valid_login_api",
                             :api_key => "835a3161dc4e71b",
                             :hash_key => "0b81d46ef348de79ea6b9a3bb841db5")
    
    assert login_api.save
    @signature = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('SHA256'), "12345", params["html"])).chomp
    assert_not_equal @signature, sk.signature("SHA256", login_api["hash_key"], params["html"])
    login_api.destroy
  end
  
end