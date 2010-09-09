require 'secure_key' 

module PDF
  class Generator   
    
    class << self   
      
      def generate(params)    
        opts = self.process_options(params)
        cmd = "/usr/local/bin/wkhtmltopdf -q - -"
          
        pdf = nil
        IO.popen(cmd, 'w+') do |subprocess|
          subprocess.write(params[:page])
          subprocess.close_write
          pdf = subprocess.read
        end
        return pdf 
      end
 
      def process_options(params)
        opts = ""
        params.each do |key, value|
          if key != "page" && key != "api_key" && key != "signature" && key != "timestamp" && key != "name"
            if key.size == 1 && value != "false"
              key_temp = key.sub(/_/, '-')
            elsif value != "false"
              key_temp = key.sub(/_/, '-')
            else
              next
            end
            
            opts += key_temp.insert(0, "--") + " "
            opts += "'#{value}' " unless value == "true"
          end
        end
        return opts
      end
          
    end
    
  end
end