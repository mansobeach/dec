#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/reloader' # if development?
require 'sinatra/custom_logger'
require 'logger'
require 'json'
require 'ftools'

require 'cuc/DirUtils'
require 'arc/MINARC_API'
require 'arc/MINARC_Environment'
require 'arc/MINARC_Status'
require 'arc/FileStatus'

include CUC::DirUtils
include FileUtils::Verbose
include ARC

# POST GET PUT DELETE

# C R U D 

# ----------------------------------------------------------
#
# GENERAL configuration
#
#

class MINARC_Server < Sinatra::Base

   helpers Sinatra::CustomLogger

   configure do
      
      # Parent exists, child continue
      # exit!(0) if fork
      # Become session leader without a controlling TTY
      # Process.setsid
      
      puts "Loading general configuration"
      
      # set :bind, '0.0.0.0'
      
      set :server, :thin
      set :threaded, true
      set :root,              "#{ENV['MINARC_ARCHIVE_ROOT']}"
      set :public_folder,     "#{ENV['MINARC_ARCHIVE_ROOT']}"
      set :isDebugMode,       true
      set :logger, Logger.new(STDOUT)
   
      # Racks environment variable
      if !ENV['TMPDIR'] then
         ENV['TMPDIR'] = "#{ENV['MINARC_TMP']}"
      end
   
      if settings.isDebugMode then
         puts "CONFIGURE ENV['HOME']                  => #{ENV['HOME']}"
         puts "CONFIGURE :root                        => #{settings.root}"
         puts "CONFIGURE :public_folder               => #{settings.public_folder}"
         puts "CONFIGURE :isDebugMode                 => #{settings.isDebugMode}"
         puts "CONFIGURE ENV['TMPDIR']                => #{ENV['TMPDIR']}" 
      end
   end

   # ----------------------------------------------------------

   configure :production do
      puts
      puts "Loading production configuration"
      puts
      
      puts ""
      puts "========================================"
      puts "Production Environment:"
      print_environment
      puts "========================================"
      puts
      puts
      
      check_environment_dirs      
   end
   # ----------------------------------------------------------

   configure :development do
      puts
      puts "Loading development configuration"
      puts
      
      load_config_development
               
      puts "========================================"
      puts "Development Environment:"
      print_environment
      puts "========================================"
      puts
      puts

      check_environment_dirs
      
      Dir.chdir(ENV['TMPDIR'])
   end
   # ----------------------------------------------------------

   configure :test do
      # test configuration
   end
   # ----------------------------------------------------------

   after do
      ActiveRecord::Base.clear_active_connections!
   end

   # =================================================================

   # Get all filetypes archived
   
   get ARC::API_URL_GET_FILETYPES do
      msg = "GET #{ARC::API_URL_GET_FILETYPES} : get archived filetypes"
      logger.info msg
      
      if settings.isDebugMode == true then
         puts msg
      end
      "#{ARC.class_variable_get(:@@version)}"
      
      cmd = "minArcRetrieve -T --noserver"
      
      listTypes = `#{cmd}`

      if $? == 0 then
         "#{listTypes}"
      else
         logger.error "failure of #{cmd}"
         status API_RESOURCE_NOT_FOUND
      end

   end
       
   # =================================================================
   
   #
   # GET version
   #
   # curl -X GET http://localhost:4567/dec/arc/version

   get ARC::API_URL_VERSION do
      msg = "GET #{ARC::API_URL_VERSION} : minarc version: #{ARC.class_variable_get(:@@version)}"
      logger.info msg
      
      if settings.isDebugMode == true then
         puts msg
      end
      "#{ARC.class_variable_get(:@@version)}"
   end
   # =================================================================
   #
   # minArcRetrieve_LIST
   #
   get "#{API_URL_LIST}/:filename" do |filename|
      cmd = "minArcRetrieve -f #{params[:filename]} --noserver -l"
            
      if settings.isDebugMode == true then 
         puts "GET #{API_URL_LIST}/#{params[:filename]}"
         puts "MINARC_Server::#{cmd}"
      end

      listFiles = `#{cmd}`

      # "#{`#{cmd}`}"
      
      if $? == 0 then
         "#{listFiles}"
      else
         logger.info "#{params[:filename]} / files not found"
         status API_RESOURCE_NOT_FOUND
      end
   end
   # ----------------------------------------------------------


   # ----------------------------------------------------------
   #
   # Upload with POST multipart/form-data
   #
   # curl -X POST -F 'field1=value1' -F 'field2=value2' -F file=@/tmp/1.plist http://localhost:4567/dec/arc/minArcStore

   post ARC::API_URL_STORE do
   
      logger.info "POST #{ARC::API_URL_STORE}/#{params[:file][:filename]}"
   
   #   if true then
   #      puts JSON.pretty_generate(request.env)
   #      puts request.port
   #      puts request.request_method
   #      puts request.query_string
   #   end
   

      prevDir  = Dir.pwd
      reqDir   = "minArcStore_#{Time.now.to_f}.#{Random.new.rand(1.5)}"   
      FileUtils.mkdir(reqDir)
      Dir.chdir(reqDir)

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
         
      cmd = "minArcStore"
   
      cmd = "#{cmd} -D -f #{Dir.pwd}/#{filename} --noserver"
   
      params.each{|param|
         if param[0].slice(0,1) != "-" then
            next
         end
         cmd = "#{cmd} #{param[0]} #{param[1]} "   
      }
   
      if settings.isDebugMode == true then
         puts "MINARC_Server::#{cmd}"
      end
   
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

      Dir.chdir(prevDir)
      FileUtils.rm_rf(reqDir)
   

   end

   # =================================================================
   
   #
   # minArcDelete
   #
   get "#{API_URL_DELETE}/:filename" do |filename|
      puts "==================================================="  
      puts 
      puts "MINARC_Server #{API_URL_DELETE} => #{params[:filename]}"

      cmd = "minArcDelete -f #{params[:filename]} --noserver -D"

      if settings.isDebugMode == true then
         msg = "GET #{API_URL_DELETE}/#{params[:filename]}"
         logger.info msg
         msg = "MINARC_Server::#{cmd}"
         logger.info msg
      end

      ret = system(cmd)
   
      if ret == false then
         puts "file #{params[:filename]} not found"
         status API_RESOURCE_NOT_FOUND      
      end

   end
   # ----------------------------------------------------------


   # =================================================================
   # ----------------------------------------------------------
   #
   # minArcRetrieve
   #
   get "#{API_URL_RETRIEVE}/:filename" do |filename|
   
=begin
      puts "==================================================="  
      puts
      puts "MINARC_Server #{API_URL_RETRIEVE} => #{params[:filename]}"
      puts
      puts
=end   
      reqDir   = "retrieve_#{Time.now.to_f}.#{Random.new.rand(1.9)}.#{self.object_id}"      
      Dir.chdir(settings.public_folder)
      FileUtils.mkdir(reqDir)
      Dir.chdir(reqDir)
   
#       puts "xxxxxxxxxxxxxxx"
#       puts "MINARC_Server::RETRIEVE_DIR(#{Process.pid}/#{self.object_id}) => #{Dir.pwd} / #{reqDir}"
#       puts "xxxxxxxxxxxxxxx"
   
      # Retrieval from archive is a hard-link
      cmd      = "minArcRetrieve -f #{params[:filename]} --noserver -H"
   
      if settings.isDebugMode == true then 
         puts "MINARC_Server::#{cmd}"
      end
   
      ret      = system(cmd)
   
      if ret == true then
         Dir.chdir(settings.public_folder)
         Dir.chdir(reqDir)
      
         theFile = Dir["#{params[:filename]}*"]
         
         if theFile.empty? then
            puts "Problems come to me ! :-("
            puts Dir.pwd
            puts "#{params[:filename]}*"
            puts
         end
         
         content = File.read(theFile[0])         
                  
         response.headers['filename']     = theFile[0]
         response.headers['Content-Type'] = "application/octet-stream"
         # response.headers['Content-Disposition']   = "attachment;filename=#{theFile[0]}"
         attachment(theFile[0])

         # puts "BEFORE SEND_FILE"
         # send_file(theFile[0], :filename => theFile[0]) ########, :disposition => :attachment)
         # puts "AFTER SEND_FILE"
         
         rm(theFile[0])
         Dir.chdir(settings.public_folder)
         FileUtils.rm_rf(reqDir)

         response.write(content)

      else
         puts "file #{params[:filename]} not found"
         Dir.chdir(settings.public_folder)
         FileUtils.rm_rf(reqDir)
         status API_RESOURCE_NOT_FOUND
      end
            
=begin
      puts
      puts "MINARC_Server::#{API_URL_RETRIEVE} EXIT"
      puts 
      puts "==========================================="

=end      
   end


   # =================================================================
   
   #
   # minArcStatus by file-type
   #
   get "#{API_URL_STAT_FILETYPES}/:filetype" do |filetype|
      fileStatus = ARC::FileStatus.new(nil)

      if settings.isDebugMode == true then
         fileStatus.setDebugMode
      end
     
      ret = fileStatus.statusType("#{params[:filetype]}")
      
      if settings.isDebugMode == true then
         puts ret
      end

      content_type :json 
      ret.to_json
   end

   # =================================================================

   #
   # minArcStatus global
   #

   get ARC::API_URL_STAT_GLOBAL do
   
      arcStatus = ARC::MINARC_Status.new(nil)

      if settings.isDebugMode == true then
         arcStatus.setDebugMode
      end
     
      ret = arcStatus.statusGlobal
      
      if settings.isDebugMode == true then
         puts ret
      end

      content_type :json 
      ret.to_json
   end
   # =================================================================

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
