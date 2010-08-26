require 'openssl'
require 'digest/sha2'
require 'base64'
require 'time'


module SecureKey
  
  class Digest
    
    attr_accessor :params_signature, :canonical_querystring, :params_timestamp, :error_message
    @@max_time = 300
    
    def initialize
      @params_signature = ""
      @canonical_querystring = ""
      @params_timestamp = nil
      @error_message = ""
    end
    
    # instance setter methods    
    def params_timestamp=(timestamp)
      #timestamp format "2010-08-22T00:24:46Z"
      timestamp_match = timestamp.match(/^((\d{4})-(\d{2})-(\d{2}))(T(\d{2}):(\d{2}):(\d{2})(Z))$/)
      begin
        @params_timestamp = Time.parse(timestamp_match[0], "")
      rescue Exception => e
        raise "Incorrect timestamp format"
      end
    end
    
    def canonical_querystring=(params={})
      if params["signature"]
        params.delete("signature")
      end
      @canonical_querystring = params.sort.collect do |key, value| [key.to_s, value.to_s].join('=') end.join('&')
    end
    
    def error_message_handler(message)
      self.error_message = message
      puts self.error_message
    end
    # end setter methods
    
    def signature(hashtype, key, data)
      digest = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new(hashtype), key, data)
      Base64.encode64(digest).chomp
    end
        
    def signature_match(login_api, params={})
      begin
        check_params_nil?(params)
        
        if(login_api.nil?)
          raise "API key error: API key does not exist or is incorrect"
        end
                 
        process_params(params)
        
        if @params_signature.size == 44
      		#puts "\nUsing SHA256\n"
      		hashtype = 'SHA256'
      	elsif @params_signature.size == 89
      		#puts "\nUsing SHA512\n"
      		hashtype = 'SHA512'		
      	elsif @params_signature.size == 28
      		#puts "\nUsing SHA1\n"
      		hashtype = 'SHA1'		
      	else
      	  raise "Incorrect hashtype."
      		#puts "\nWARNING: Default hash should be 40 characters long. Try setting the proper hash type.\n"
      	end
        @params_signature == signature(hashtype, login_api.hash_key, @canonical_querystring)
      rescue => e
        error_message_handler(e.message)
      end
    end
     
    private
    
    def check_params_nil?(params)
      if(params["signature"].nil? || params["api_key"].nil? || params["timestamp"].nil? || params["page"].nil?)
        raise "Incorrect parameters"
      end
    end
    
    def process_params(params)
      self.params_timestamp = params["timestamp"]
      timestamp_diff
      self.params_signature = params["signature"]
      self.canonical_querystring = params
    end
    
    def timestamp_diff
      #max time diff is 300sec or 5 minutes
      time_diff = Time.now.utc - self.params_timestamp
      if time_diff > @@max_time
        raise "Too much time has passed. Request will need to be regenerated"
      end
    end
    
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
  
  class Generate
    
    def self.generate_api_key
      begin
        random = random_generator
      end while LoginApi.first(:api_key => random)
      random
    end
  
    def self.generate_hash_key
      begin
        data = OpenSSL::BN.rand(512, -1, false).to_s
        digest = OpenSSL::Digest::SHA256.new(data).digest
        key = Base64.encode64(digest).chomp
      end while LoginApi.first(:hash_key => key)
      key
    end
  end
  
  private
  
  def self.random_generator(opts={})
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