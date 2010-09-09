ENV['RACK_ENV'] = "production" 
ENV['DATABASE_URL'] = "sqlite3://#{Dir.pwd}/db/secure_pdf.sqlite3"

require 'rendermonkey_too'
run Sinatra::Application