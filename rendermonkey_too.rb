require 'rubygems'
require 'sinatra'
require 'haml'

$:.unshift File.join(File.dirname(__FILE__), "lib")
require 'secure_key'
require 'pdf'
require 'models'

error do
  e = request.env['sinatra.error']
  puts "#{e.class}: #{e.message}\n#{e.backtrace.join("\n  ")}"
end

before do
  if (request.path_info == '/generate' || request.path_info == 'create')
    @sk = SecureKey::Digest.new
  end
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
  login_api = LoginApi.first(:api_key => params["api_key"])

  if @sk.signature_match(login_api, params)
    pdf_file = PDF::Generator.generate(params["page"])
  
    if params["name"].nil?
      report_type = "Untitl.pdf"
    else
      report_type = params["name"] + ".pdf"
    end
  
    send_file pdf_file,
              :disposition => 'attachment',
              :filename => report_type,
              :type => 'application/pdf'
  else
    status(412)
    @sk.error_message
  end
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


  
	