require 'secure_key' 

module PDF
  class Generator   
    
    class << self   
                    
      def generate(wkhtmltopdf_cmd, params)                          
        cmd = "#{self.cmd_path(wkhtmltopdf_cmd)} -q #{self.process_options(params)} - -"
                                                                                          
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
        puts "%"*10 + opts
        return opts
      end 
      
      def cmd_path(type)
        if type == "darwin-x86"
          File.join(File.dirname(__FILE__), "..", "vendor", "wkhtmltopdf-darwin-x86") 
        elsif type == "linux-amd64"
          File.join(File.dirname(__FILE__), "..", "vendor", "wkhtmltopdf-linux-amd64")
        elsif type == "linux"
          File.join(File.dirname(__FILE__), "..", "vendor", "wkhtmltopdf-linux-x86") 
        end
      end
          
    end 
        
  end
end
