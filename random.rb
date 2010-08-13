$LOAD_PATH << File.join(Dir.getwd, 'lib')
require 'rubgems'
require 'sinatra'

before do
	@secure_key = SecureKey.load
	end
	