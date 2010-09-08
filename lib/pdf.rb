
module PDF
  class Generator
    
    class << self 
      def generate(params)
        if ENV['RACK_ENV'] == "test"
          location = File.join(Dir.getwd, "../", "tmp")
          puts location
        else
          location = File.join(Dir.getwd, "tmp")
        end
        # if the file exists keep looping until we find one that doesn't exist
        begin
          time_string = Time.now.strftime("H%M%S").to_s
          random = random_generator
          fName = random + time_string
          f_path_html =  location + "/" + fName + '.html'
          f_path_pdf = location + "/" + fName + '.pdf'
        end while FileTest.exist?(f_path_pdf)

        f = File.open(f_path_html, "w")
        begin
          f.write(params["page"])
        rescue Errno::ENOENT => e
          puts e
          puts "Could not open file"
        rescue IOError => e
          puts e
          puts "Could not write to file"
        ensure
          f.close unless f.nil?
        end

        opts = self.process_options(params)
        
        puts "*"*10 + opts
        system("/usr/local/bin/wkhtmltopdf #{f_path_html} #{f_path_pdf} #{opts}")
        f_path_pdf
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