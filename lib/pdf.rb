
module PDF
  
  class Generator
    
    def self.generate(page)
      location = File.join(Dir.getwd, "../", "tmp/")
      # if the file exists keep looping until we find one that doesn't exist
      begin
        time_string = Time.now.strftime("H%M%S").to_s
        random = random_generator
        fName = random + time_string
        f_path_html = location + fName + '.html'
        f_path_pdf = location + fName + '.pdf'
      end while FileTest.exist?(f_path_pdf)

  
      begin
        f = File.open(f_path_html, "w")
        f.write(page)
      rescue Errno::ENOENT => e
        puts e.messaage
        puts "Could not open file"
      rescue IOError => e
        puts e.messaage
        puts "Could not write to file"
      ensure
        f.close unless f.nil?
      end
  
      system("/usr/local/bin/wkhtmltopdf #{f_path_html} #{f_path_pdf}")
      f_path_pdf
    end
  end
end