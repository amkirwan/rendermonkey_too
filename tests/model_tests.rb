# needs to run first
ENV['RACK_ENV'] = "test"

$LOAD_PATH << File.join(Dir.getwd, "..")
require 'rubygems'
require 'test/unit'
require 'rack/test'
require 'rendermonkey_too'

class ModelTests < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  # LoginApi Tests
  def test_invalid_name
    api_secure_key = ApiSecureKey.new(:app_name => "adf   **")
    assert !api_secure_key.valid?
    assert_equal dm_default_message(:invalid, :app_name), api_secure_key.errors.on(:app_name).first
  end
  
  def test_blank_name
    api_secure_key = ApiSecureKey.new
    assert !api_secure_key.valid?
    assert dm_default_message(:blank, :app_name), api_secure_key.errors.on(:app_name).first
  end
  
  def test_unique_name_required
    api_secure_key = ApiSecureKey.new(:app_name => "test_unique_name_required",
                             :api_key => "835a3161dc4e71b7",
                             :hash_key => "0b81d46ef348de79ea6b9a3bb841db35=")
    assert api_secure_key.valid?
    assert api_secure_key.save
    api_secure_key2 = ApiSecureKey.new(:app_name => "test_unique_name_required",
                             :api_key => "1234",
                             :hash_key => "12345")
    assert !api_secure_key2.valid?
    assert !api_secure_key2.save
    assert dm_default_message(:blank, :app_name), api_secure_key2.errors.on(:app_name).first
  end
  
  def test_invalid_api_secure_key
    api_secure_key = ApiSecureKey.new
    assert !api_secure_key.valid?
    assert api_secure_key.errors.on(:api_key)
    assert api_secure_key.errors.on(:hash_key)
  end
  
  def test_blank_api_key
    api_secure_key = ApiSecureKey.new
    assert !api_secure_key.valid?
    assert_equal dm_default_message(:blank, :api_key), api_secure_key.errors.on(:api_key).first 
  end
  
  def test_blank_hash_key
    api_secure_key = ApiSecureKey.new
    assert !api_secure_key.valid?
    assert_equal dm_default_message(:blank, :hash_key), api_secure_key.errors.on(:hash_key).first
  end
  
  def test_invalid_api_key
    api_secure_key = ApiSecureKey.new(:api_key => "****8")
    assert !api_secure_key.valid?
    assert_equal dm_default_message(:invalid, :api_key), api_secure_key.errors.on(:api_key).first 
  end
  
  def test_invalid_hash_key
    api_secure_key = ApiSecureKey.new(:hash_key => "****8")
    assert !api_secure_key.valid?
    assert_equal dm_default_message(:invalid, :hash_key), api_secure_key.errors.on(:hash_key).first
  end
  
  def test_valid_api_secure_key
    api_secure_key = ApiSecureKey.new(:app_name => "test_valid_api_secure_key",
                             :api_key => "835a3161dc4e71b",
                             :hash_key => "0b81d46ef348de79ea6b9a3bb841db5=")
    
    assert api_secure_key.save
  end
  
  private
  
  def dm_default_message key, field
    DataMapper::Validations::ValidationErrors.default_error_message(key, field)
  end
end

