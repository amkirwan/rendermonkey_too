# needs to run first
ENV['RACK_ENV'] = "test"

$LOAD_PATH << File.join(Dir.getwd, "..")
require 'rubygems'
require 'test/unit'
require 'rack/test'
require 'rendermonkey_too'

class SecureTest < Test::Unit::TestCase
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
    post '/create', {"app_name" => "Test App"}
    assert_equal url_test('/create'), last_request.url
    assert last_response.ok?
    assert last_response.body.include?("Test App")
  end
  
  def test_generate
    get '/generate'
    assert last_response.ok?
    assert_equal url_test("/generate"), last_request.url
    assert last_response.body.include?("URL")
    assert last_response.body.include?("Name")
    assert last_response.headers.include?("Content-Type")
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
  
end