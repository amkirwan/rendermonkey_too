ENV['RACK_ENV'] = "production" 

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default) 

require './rendermonkey_too'
run Sinatra::Application