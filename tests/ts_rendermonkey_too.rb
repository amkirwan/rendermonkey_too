# needs to run first 
ENV['RACK_ENV'] = "test"

require File.expand_path('../test_model', __FILE__)
require File.expand_path('../test_rendermonkey_too', __FILE__)
require File.expand_path('../test_secure_key', __FILE__)