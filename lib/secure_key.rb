require 'openssl'
require 'digest/sha2'
require 'base64'


module SecureKey
  
  class Digest
    
    attr_accessor :params_signature, :canonical_querystring, :params_html
    
    def initialize
      @params_signature = ""
      @canonical_querystring = ""
      @params_html = ""
    end
  
    def generate_api_key
      begin
        random = random_generator
      end while LoginApi.first(:api_key => random)
      random
    end
  
    def generate_hash_key
      begin
        data = OpenSSL::BN.rand(512, -1, false).to_s
        digest = OpenSSL::Digest::SHA256.new(data).digest
        key = Base64.encode64(digest).chomp
      end while LoginApi.first(:hash_key => key)
      key
    end
    
    def signature(hashtype, key, data)
      digest = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new(hashtype), key, data)
      Base64.encode64(digest).chomp
    end
    
    def canonical_querystring=(params={})
      params.delete("signature")
      @canonical_querystring = params.sort.collect do |key, value| [key.to_s, value.to_s].join('=') end.join('&')
    end
    
    def params_signature=(signature)
      @params_signature = Base64.decode64(signature)
    end
    
    def signature_match(params={})
      login_api = LoginApi.first(:api_key => params[:api_key])
      if(login_api.nil?)
        return false
      end
      params_signature(params)
      canonical_querystring(params)
      if @params_signature.size == 64
    		put "\nUsing SHA256\n"
    		hashtype = 'SHA256'
    	elsif @params_signature.size == 128
    		put "\nUsing SHA512\n"
    		hashtype = 'SHA512'		
    	elsif @params_signature.size == 32
    		put "\nUsing MD5\n"
    		hashtype = 'MD5'		
    	else
    		puts "\nWARNING: Default hash should be 40 characters long. Try setting the proper hash type.\n"
    	end
      @params_signature == signature(hashtype, login_api.hash_key, @params_html)
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
  end
  
end