$LOAD_PATH << File.join(Dir.getwd, "..")

require 'rubygems'
require 'test/unit'
require 'rack/test'
require 'secure'

ENV['RACK_ENV'] = 'test'

class SecureTest < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  def test_get
    get '/'
    assert last_response.ok?
    assert_equal url, last_request.url
    assert last_response.body.include?("Name:")
    assert last_response.headers.include?("Content-Type")
  end
  
  def test_new
    get '/new'
    assert_equal url("/new"), last_request.url
    assert last_response.ok?
    assert last_response.body.include?("App Name:")
  end
  
  def test_create
    post '/create', {"app_name" => "Test App"}
    assert_equal url('/create'), last_request.url
    assert last_response.ok?
    assert last_response.body.include?("Test App")
  end
    
  private 
  
  def url(path=nil)
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