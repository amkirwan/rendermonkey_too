ENV['RACK_ENV'] = "production" 

require 'rendermonkey_too'
run Sinatra::Application