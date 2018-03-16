#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'ftools'

require 'cuc/DirUtils'
require 'arc/MINARC_API.rb'
require 'arc/MINARC_ConfigDevelopment.rb'

include CUC::DirUtils
include FileUtils::Verbose
include ARC

# POST GET PUT DELETE

# C R U D 

@minarc_version = "01.00.00"


# ----------------------------------------------------------
#
# GENERAL configuration
#
#

class MINARC_Server < Sinatra::Base

   configure do
      
      puts "Loading general configuration"
      
      # set :bind, '0.0.0.0'
      
      set :root, '/Users/borja/Sandbox/minarc_root'
      set :public_folder, '/Users/borja/Sandbox/minarc_root/load'
   
      # Racks environment variable
      ENV['TMPDIR']                 = '/Users/borja/Sandbox/minarc_root/load'
   
      puts "CONFIGURE :root                        => #{settings.root}"
      puts "CONFIGURE :public_folder               => #{settings.public_folder}"
      puts "CONFIGURE ENV['TMPDIR']                => #{ENV['TMPDIR']}"      
   end

   # ----------------------------------------------------------

   configure :production do
      # production configuration
   end
   # ----------------------------------------------------------

   configure :development do
      # development configuration
      puts
      puts "Loading development configuration"
      puts
   
      load_config_development
         
      checkDirectory(ENV['MINARC_ARCHIVE_ROOT'])
      checkDirectory(ENV['MINARC_ARCHIVE_ERROR'])
      checkDirectory("#{ENV['HOME']}/Sandbox/minarc/inv")
   
      puts "========================================"
      print_environment
      puts "========================================"
      puts
      puts

   end
   # ----------------------------------------------------------

   configure :test do
      # test configuration
   end
   # ----------------------------------------------------------

   #
   # GET version
   #
   # curl -X GET http://localhost:4567/dec/arc/version

   get ARC::API_URL_VERSION do
      puts "minarc version: #{ENV['MINARC_VERSION']}"
      "#{ENV['MINARC_VERSION']}"
   end

   # ----------------------------------------------------------

   # ----------------------------------------------------------
   #
   # Upload with POST multipart/form-data
   #
   # curl -X POST -F 'field1=value1' -F 'field2=value2' -F file=@/tmp/1.plist http://localhost:4567/dec/arc/minArcStore

   post ARC::API_URL_STORE do
   
      logger.info "POST #{ARC::API_URL_STORE}"
   
   #   if true then
   #      puts JSON.pretty_generate(request.env)
   #      puts request.port
   #      puts request.request_method
   #      puts request.query_string
   #   end
   
   
      if request.form_data? == false then
         logger.error("Missing form parameters for request")
      end
   
      # ---------------------------------------------
      # rename file into the original name
      filename = params[:file][:filename] 
      tempfile = params[:file][:tempfile]
      mv(tempfile.path, filename)   
      # ---------------------------------------------
      #
      # Process the form parameters
         
      cmd = "#{ENV['MINARC_BASE']}/code/arc/minArcStore"
   
      cmd = "#{cmd} -D -f #{Dir.pwd}/#{filename}"
   
      params.each{|param|
         if param[0].slice(0,1) != "-" then
            next
         end
         cmd = "#{cmd} #{param[0]} #{param[1]} "   
      }
   
      puts cmd
   
      retVal = true
   
      retVal = system(cmd)

      if retVal == false then
         status 500
      end

   
      # retVal = %x["#{cmd}"]
   
   
      puts retVal
   
      puts "PEDO"
   
      #
      # ---------------------------------------------
   
      puts
   

   end

   # ----------------------------------------------------------

   get "#{API_URL_RETRIEVE}/:filename" do |filename|
   
      # #{params[:filename]}
   
      puts "==================================================="  
      puts 
      puts "MINARC_Server #{API_URL_RETRIEVE} => #{params[:filename]}"
   
      cmd = "#{ENV['MINARC_BASE']}/code/arc/minArcRetrieve -f #{params[:filename]}"
   
      puts cmd
   
      system(cmd)
   
      theFile = Dir["#{params[:filename]}*"]
   
      puts theFile
   
      send_file(theFile[0], :filename => theFile[0]) ########, :disposition => :attachment)
   
      rm(theFile[0])
      
   end
   # ----------------------------------------------------------

   not_found do
   "driverSinatra: page not found"
   end

   # ----------------------------------------------------------

   get '/fake-error' do
      status 500
      "There is nothing wrong really :-p"
   end

   # curl -d "param1=value1&param2=value2" -X POST http://localhost:4567/posting

   post '/posting' do
      puts params
      # redirect to "/hello"
   end

   # ----------------------------------------------------------
   
   # curl -X DELETE http://localhost:4567/delete/:id

   delete '/delete/:id' do
      puts "deleting #{params[:id]}"
   end

   # curl -X PUT http://localhost:4567/update/:id
   # ----------------------------------------------------------
   
   put '/update/:id' do
      puts "updating #{params[:id]}"
      "updating #{params[:id]}\n"
   end

   # ----------------------------------------------------------
   
   get '/' do
      erb :home
   end
   
   # ----------------------------------------------------------
   
   get '/hello' do
      "Hello Blimey !"
   end

   # ----------------------------------------------------------
   # list files

   get '/list' do
      list = Dir.glob("./*.*").map{|f| f.split('/').last}
      puts list
      "#{list}"
      # render list here
   end

   # ----------------------------------------------------------
   #
   # Upload with PUT <formless>

   # curl --upload-file /tmp/1.plist http://localhost:4567/uploadFile/

   put '/uploadFile/:filename' do
   
      logger.info "PUT /uploadFile/#{params[:filename]}"

      if true then
         puts
         puts JSON.pretty_generate(request.env)
         puts
      end
   
      File.open(params[:filename], 'w+') do |file|
         request.body.rewind
         file.write(request.body.read)
      end
   
   end



   # ----------------------------------------------------------
   
   get '/:name' do
      name = params[:name]
      "Hi there #{name}!"
   end

   # ----------------------------------------------------------
   
   get '/:param1/:param2/:param3' do
      "List of params \n#{params[:param1]}\n#{params[:param2]}\n#{params[:param3]}\n"
   end

   # ----------------------------------------------------------

   run! if __FILE__ == $0

end # class
