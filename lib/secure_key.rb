require 'openssl'
require 'digest/sha2'
require 'base64'
require 'time'


module SecureKey
  
  class Digest
      
    class << self
      attr_accessor :max_time
    end
    @max_time = 300
    
    attr_accessor :params_signature, :canonical_querystring, :params_timestamp, :error_message, :hashtype 
    
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
        self.error_message = "Incorrect timestamp format should be iso8601"
        raise "Incorrect timestamp format should be iso8601"
      end
    end
    
    def canonical_querystring=(params={})
      if params["signature"]
        params.delete("signature")
      end
      @canonical_querystring = params.sort.collect do |key, value| [key.to_s, value.to_s].join('=') end.join('&')
    end
    # end setter methods
    
    def signature(hashtype, key, data)
      digest = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new(hashtype), key, data)
      Base64.encode64(digest).chomp
    end
        
    def signature_match(login_api, params={})
      self.error_message = catch :params_error do    
        process_params(login_api, params)     
      end
      
      if(self.error_message.empty?)
        if @params_signature == signature(hashtype, login_api.hash_key, @canonical_querystring)
          return true
        else
          self.error_message = "Signature failed"
          return false
        end
      else
        return false
      end
    end
     
    private
    
    def process_params(login_api, params)
      check_params_nil?(login_api, params)
      self.params_timestamp = params["timestamp"]
      self.params_signature = params["signature"]
      self.canonical_querystring = params
      timestamp_diff
      check_hashtype
      self.error_message
    end
    
    def check_params_nil?(login_api, params)
      if login_api.nil?
        throw :params_error, "api_key missing or incorrect"
      end
        
      if(params["signature"].nil? || params["api_key"].nil?|| params["timestamp"].nil? || params["page"].nil?)
        throw :params_error, "Incorrect or missing parameters"
      end
    end
    
    def check_hashtype
      if @params_signature.size == 44
    		#puts "\nUsing SHA256\n"
    		self.hashtype = 'SHA256'
    	elsif @params_signature.size == 89
    		#puts "\nUsing SHA512\n"
    		self.hashtype = 'SHA512'		
    	elsif @params_signature.size == 28
    		#puts "\nUsing SHA1\n"
    		self.hashtype = 'SHA1'		
    	else
    	  throw :params_error, "Incorrect hashtype"
    		#puts "\nWARNING: Default hash should be 40 characters long. Try setting the proper hash type.\n"
    	end
    end
    
    def timestamp_diff
      #max time diff is 300sec or 5 minutes
      time_diff = Time.now.utc - self.params_timestamp
      if time_diff > Digest.max_time
        throw :params_error, "Too much time has passed. Request will need to be regenerated"
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
      
    class << self
      
      def generate_api_key
        begin
          random = random_generator
        end while ApiSecureKey.first(:api_key => random)
        random
      end

      def generate_hash_key
        begin
          data = OpenSSL::BN.rand(512, -1, false).to_s
          digest = OpenSSL::Digest::SHA256.new(data).digest
          key = Base64.encode64(digest).chomp
        end while ApiSecureKey.first(:hash_key => key)
        key
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
    
  end
end