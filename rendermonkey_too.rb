require 'rubygems'
require 'sinatra'
require 'haml'

$:.unshift File.join(File.dirname(__FILE__), "lib")
require 'secure_key'
require 'models'

error do
  e = request.env['sinatra.error']
  puts "#{e.class}: #{e.message}\n#{e.backtrace.join("\n  ")}"
end

before do
	@secure_key = SecureKey::Digest.new
end

get '/' do
  haml :index
end

get '/new' do
  haml :new
end

post '/create' do
  haml :create, :locals => { :app_name => params[:app_name]}
end

post '/generate' do
  location = '/Users/akirwan/code/rendermonkey_too/tmp/'
  # if the file exists keep looping until we find one that doesn't exist
  begin
    time_string = Time.now.strftime("H%M%S").to_s
    random = random_generator
    fName = random + time_string
    f_path_html = location + fName + '.html'
    f_path_pdf = location + fName + '.pdf'
  end while FileTest.exist?(f_path_pdf)
  
  File.open(f_path_html, 'w') { |f| f.write(params[:page]) }
  
  system("/usr/local/bin/wkhtmltopdf #{f_path_html} #{f_path_pdf}")
  
  if params[:name].nil?
    report_type = "report.pdf"
  else
    report_type = params[:name] + ".pdf"
  end
  
  send_file f_path_pdf,
            :disposition => 'attachment',
            :filename => report_type,
            :type => 'application/pdf'
end

private

def random_generator(opts={})
    opts = {:chars => ('0'..'9').to_a + ('A'..'F').to_a + ('a'..'f').to_a,
            :length => 8, :prefix => '', :suffix => '',
            :verify => true, :attempts => 10}.merge(opts)
    opts[:attempts].times do
        filename = ''
        opts[:length].times do
            filename << opts[:chars][rand(opts[:chars].size)]
        end
        filename = opts[:prefix] + filename + opts[:suffix]
        return filename unless opts[:verify] && File.exists?(filename)
    end
    nil
end


  
	