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
    login_api = LoginApi.new(:name => "adf   **")
    assert !login_api.valid?
    assert_equal dm_default_message(:invalid, :name), login_api.errors.on(:name).first
  end
  
  def test_blank_name
    login_api = LoginApi.new
    assert !login_api.valid?
    assert dm_default_message(:blank, :name), login_api.errors.on(:name).first
  end
  
  def test_unique_name_required
    login_api = LoginApi.new(:name => "test_unique_name_required",
                             :api_key => "835a3161dc4e71b7",
                             :hash_key => "0b81d46ef348de79ea6b9a3bb841db35")
    assert login_api.valid?
    assert login_api.save
    login_api2 = LoginApi.new(:name => "test_unique_name_required",
                             :api_key => "1234",
                             :hash_key => "12345")
    assert !login_api2.valid?
    assert !login_api2.save
    assert dm_default_message(:blank, :name), login_api2.errors.on(:name).first
  end
  
  def test_invalid_login_api
    login_api = LoginApi.new
    assert !login_api.valid?
    assert login_api.errors.on(:api_key)
    assert login_api.errors.on(:hash_key)
  end
  
  def test_blank_api_key
    login_api = LoginApi.new
    assert !login_api.valid?
    assert_equal dm_default_message(:blank, :api_key), login_api.errors.on(:api_key).first 
  end
  
  def test_blank_hash_key
    login_api = LoginApi.new
    assert !login_api.valid?
    assert_equal dm_default_message(:blank, :hash_key), login_api.errors.on(:hash_key).first
  end
  
  def test_invalid_api_key
    login_api = LoginApi.new(:api_key => "****8")
    assert !login_api.valid?
    assert_equal dm_default_message(:invalid, :api_key), login_api.errors.on(:api_key).first 
  end
  
  def test_invalid_hash_key
    login_api = LoginApi.new(:hash_key => "****8")
    assert !login_api.valid?
    assert_equal dm_default_message(:invalid, :hash_key), login_api.errors.on(:hash_key).first
  end
  
  def test_valid_login_api
    login_api = LoginApi.new(:name => "test_valid_login_api",
                             :api_key => "835a3161dc4e71b",
                             :hash_key => "0b81d46ef348de79ea6b9a3bb841db5")
    
    assert login_api.save
  end
  
  private
  
  def dm_default_message key, field
    DataMapper::Validations::ValidationErrors.default_error_message(key, field)
  end
end

