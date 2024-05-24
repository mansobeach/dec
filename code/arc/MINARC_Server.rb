#!/usr/bin/env ruby

require 'rack/ssl'
require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' # if development?
require 'sinatra/custom_logger'
require 'active_record'
require 'bcrypt'
require 'byebug'
require 'logger'
require 'json'
require 'ftools'
#require "bundler/setup"

require 'cuc/DirUtils'
require 'cuc/Log4rLoggerFactory'

require 'ctc/API_MINARC_OData'

require 'arc/MINARC_API'

require 'arc/MINARC_Environment'
require 'arc/MINARC_Status'
require 'arc/MINARC_DatabaseModel'
require 'arc/FileStatus'
require 'arc/ReadMinarcConfig'
require 'arc/SinatraHelperMINARC.rb'
require 'arc/SinatraControllerODataProductDownload'
require 'arc/SinatraControllerODataProductQuery'


include CUC::DirUtils
include FileUtils::Verbose
include ARC
include ARC_ODATA

## ----------------------------------------------------------
##
## GENERAL configuration
##
##

class MINARC_Server < Sinatra::Base

   helpers Sinatra::CustomLogger
   helpers ARC::ApplicationHelper

   configure do

      # set :bind, '0.0.0.0'
      set :server, :thin
      # set :server, :puma
      set :threaded, false
      set :root,              "#{ENV['MINARC_ARCHIVE_ROOT']}"
      set :public_folder,     "#{ENV['MINARC_ARCHIVE_ROOT']}"
      set :isDebugMode,       true
      @isDebugMode   = true
      @@isDebugMode  = true
      set :environment, :production

      # set :logger, Logger.new(STDOUT)


      ## ------------------------------------------------------
      ##
      ## Log configuration

      @minArcConfigDir       = ENV['MINARC_CONFIG']

      ## initialise the logger
      loggerFactory = CUC::Log4rLoggerFactory.new("ArcServer", "#{@minArcConfigDir}/minarc_log_config.xml")

      if settings.isDebugMode then
         loggerFactory.setDebugMode
      end

      @@logger = loggerFactory.getLogger
      # @logger = Logger.new(STDOUT)

      if @@logger == nil then
         puts
		   puts "Could not initialize logging system !  :-("
         puts "Check minARC logs configuration under \"#{@minArcConfigDir}/minarc_log_config.xml\""
		   exit(99)
      end

      @@logger.info("MINARC_Server: Loading general configuration / debug = #{@@isDebugMode}")

      ## ------------------------------------------------------

      @@inTray = ARC::ReadMinarcConfig.instance.getArchiveIntray
      @@tmpDir = ARC::ReadMinarcConfig.instance.getTempDir
      @@node   = ARC::ReadMinarcConfig.instance.getNode

      @@logger.debug("Intray: #{@@inTray}")
      @@logger.debug("TmpDir: #{@@tmpDir}")
      ## ------------------------------------------------------

      # Racks environment variable
      if !ENV['MINARC_TMP'] then
         raise "MINARC_TMP environment variable is needed"
      end

      if settings.isDebugMode then
         puts "CONFIGURE ENV['HOME']                  => #{ENV['HOME']}"
         puts "CONFIGURE :root                        => #{settings.root}"
         puts "CONFIGURE :public_folder               => #{settings.public_folder}"
         puts "CONFIGURE :isDebugMode                 => #{settings.isDebugMode}"
         puts "CONFIGURE ENV['MINARC_TMP']            => #{ENV['MINARC_TMP']}"
      end
   end

   ## -----------------------------------------------------------

   configure :production do
      @@logger.debug("Loading production configuration")
      if settings.isDebugMode == true then
         puts ""
         puts "========================================"
         puts "Production Environment:"
         print_environment
         puts "========================================"
         puts
         puts
      end
      @@logger.debug("checking directories")
      check_environment_dirs

    @@logger.debug("require rack/ssl-enforcer")
    require 'rack/ssl-enforcer'
    use Rack::SslEnforcer


   end
   ## ----------------------------------------------------------

   configure :development do
      @@logger.debug("Loading development configuration")

      load_config_development

      if settings.isDebugMode == true then
         puts "========================================"
         puts "Development Environment:"
         print_environment
         puts "========================================"
         puts
         puts
      end

      check_environment_dirs

      Dir.chdir(ENV['MINARC_TMP'])
   end
   ## ----------------------------------------------------------

   configure :test do
      # test configuration
   end
   # ----------------------------------------------------------

   ## =================================================================

   ## Enforce basic authentication for the complete API
   ##
   ## Need to log the failures

#   use Rack::Auth::Basic, "Check User credentials" do |username, password|
#      User.find_by name: username and User.find_by(name: username).authenticate(password)
#   end

   ## =================================================================

   ### ODATA API START

   ## =================================================================

   ## https://<service-root-uri>/odata/v1/Products?$filter=startswith(Name,'S2')

   get ARC_ODATA::API_URL_PRODUCT_QUERY_COUNT do
      if authenticate() == false then
         @@logger.error("[ARC_600] User #{request.env["REMOTE_USER"]} [#{request.ip}]: Authentication failed")
         halt 401
      end

      if settings.isDebugMode == true then
         @@logger.debug("MINARC_Server route #{ARC_ODATA::API_URL_PRODUCT_QUERY_COUNT}")
      end

      ret = ARC_ODATA::ControllerODataProductQuery.new(self, \
                        @@logger, \
                        settings.isDebugMode).query
      content_type :json
      body ret
   end

   ## =================================================================

   ## =================================================================

   ## https://<service-root-uri>/odata/v1/Products?$filter=startswith(Name,'S2')

   get ARC_ODATA::API_URL_PRODUCT_QUERY do
      if authenticate() == false then
         @@logger.error("[ARC_600] User #{request.env["REMOTE_USER"]} [#{request.ip}]: Authentication failed")
         halt 401
      end

      if settings.isDebugMode == true then
         @@logger.debug("MINARC_Server route #{ARC_ODATA::API_URL_PRODUCT_QUERY}")
      end

      before   = DateTime.now
      ret      = ARC_ODATA::ControllerODataProductQuery.new(self, \
                        @@logger, \
                        settings.isDebugMode).query

      after    = DateTime.now
      elapsed  = ((after - before) * 24 * 60 * 60).to_f

      ARC_ODATA::ControllerODataProductQuery.new(self, @@logger, settings.isDebugMode).generateReport(ret, elapsed)

      content_type :json
      body ret
   end

   ## =================================================================

   after ARC_ODATA::API_URL_PRODUCT_QUERY do
      @@logger.info("SINATRA::AFTER BLOCK ARC_ODATA::API_URL_PRODUCT_QUERY")
   end

   ## =================================================================

   ## https://<service-root-uri>/odata/v1/Products(Id)/$value

   get ARC_ODATA::API_URL_PRODUCT_DOWNLOAD do
      @@logger.info("START ARC_ODATA::API_URL_PRODUCT_DOWNLOAD")

      if authenticate() == false then
         @@logger.error("[ARC_600] User #{request.env["REMOTE_USER"]} [#{request.ip}]: Authentication failed")
         halt 401
      end

      if settings.isDebugMode == true then
         @@logger.debug("MINARC_Server route #{ARC_ODATA::API_URL_PRODUCT_DOWNLOAD}")
      end

      ARC_ODATA::ControllerODataProductDownload.new(self, \
                        @@logger, \
                        settings.isDebugMode).download
      puts "never arrives here"
      @@logger.info("END ARC_ODATA::API_URL_PRODUCT_DOWNLOAD")
   end
   ## =================================================================

   after ARC_ODATA::API_URL_PRODUCT_DOWNLOAD do
      @@logger.info("SINATRA::AFTER BLOCK ARC_ODATA::API_URL_PRODUCT_DOWNLOAD")
   end


   ### ODATA API END

   ### =================================================================

   ## =================================================================
   ##

   get "#{API_URL_RETRIEVE_CONTENT}/:filename" do |filename|
      @@logger.info("[ARC_200] Requested: #{params[:filename]} (Content)")

      if settings.isDebugMode == true then
         @@logger.debug("MINARC_Server #{API_URL_RETRIEVE} => #{params[:filename]}")
      end

      aFile = nil
      aFile = ArchivedFile.where(name: filename)

      if aFile.size != 0 then
         theFile = aFile.to_a[0]

         if @@isDebugMode == true
            @@logger.info("found #{theFile.filename}")
            puts "---------------------------------------------"
            theFile.print_introspection
            puts "---------------------------------------------"
            puts "Reading file #{theFile.path}/#{theFile.filename}"
            puts
         end

         if File.extname(theFile.filename) == ".7z" then
            prevDir = Dir.pwd
            Dir.chdir(@@tmpDir)
            ## enforces overwritting
            cmd = "7z x #{theFile.path}/#{theFile.filename} -aoa -bsp0 -bso0"
            ## avoids overwritting existing files
            cmd = "7z x #{theFile.path}/#{theFile.filename} -aos -bsp0 -bso0"
            ## -----------------------------------
            if @@isDebugMode == true
               @@logger.debug(cmd)
            end
            ## -----------------------------------
            ret = system(cmd)
            arr = Dir["#{File.basename(theFile.filename, ".*")}*"]
            @@logger.info("[ARC_200] Retrieved: #{arr[0]}")
            send_file(arr[0])
            Dir.chdir(prevDir)
         end

         send_file("#{theFile.path}/#{theFile.filename}", :filename => theFile.filename) ########, :disposition => :attachment)

#         content = File.read("#{theFile.path}/#{theFile.filename}")
#         response.headers['filename']     = theFile.filename
#         response.headers['Content-Type'] = "application/octet-stream"
#         attachment(theFile.filename)
      else
         @@logger.error("[ARC_610] #{params[:filename]} not present in the archive")
         status API_RESOURCE_NOT_FOUND
      end
   end

   ## =================================================================
   ##
   get "#{API_URL_RETRIEVE}/:filename" do |filename|
      msg = "GET #{API_URL_RETRIEVE} : get #{params[:filename]}"
      @@logger.info("[ARC_200] Requested: #{params[:filename]}")

      if settings.isDebugMode == true then
         @@logger.debug("MINARC_Server #{API_URL_RETRIEVE} => #{params[:filename]}")
      end

      aFile = nil
      aFile = ArchivedFile.where(name: filename)

      if aFile.size != 0 then
         theFile = aFile.to_a[0]

         if settings.isDebugMode == true
            @@logger.info("found #{theFile.filename}")
            puts "---------------------------------------------"
            theFile.print_introspection
            puts "---------------------------------------------"
            puts "Reading file #{theFile.path}/#{theFile.filename}"
            puts
         end

         @@logger.info("[ARC_201] Served: #{theFile.filename}")
         ########, :disposition => :attachment)
         send_file("#{theFile.path}/#{theFile.filename}", :filename => theFile.filename)
         @@logger.info("[ARC_202] Served: #{theFile.filename}")
      else
         @@logger.error("[ARC_610] #{params[:filename]} not present in the archive")
         status API_RESOURCE_NOT_FOUND
      end
   end

   ## =================================================================
   ##
   ## Request Archive from the Intray
   ##
   ## GET API_URL_REQUEST_ARCHIVE?name=S2__OPER_REP_ARC____EPA
   ##
   get ARC::API_URL_REQUEST_ARCHIVE do
#      @@logger.info("sleep start")
#      sleep(3.0)
#      @@logger.info("sleep stop")
      wildcard = params['name']
      plugin   = ENV['MINARC_PLUGIN']
      cmd      = "minArcStore -t #{plugin} -f \"#{@@inTray}/#{wildcard}\" --noserver -m -M"
      if settings.isDebugMode == true then
         @@logger.debug(request.url)
         @@logger.debug(cmd)
      end
      @@logger.info("[ARC_075] Request to archive from Intray #{@@inTray}/#{wildcard}")
      pid = spawn(cmd)
      Process.detach(pid)
      status API_RESOURCE_FOUND
   end

   ## =================================================================
   ##
   ## Get all filetypes archived

   get ARC::API_URL_GET_FILETYPES do
      msg = "GET #{ARC::API_URL_GET_FILETYPES} : get archived filetypes"
      logger.info msg

      "#{ARC::VERSION}"

      cmd = "minArcRetrieve -T --noserver"

      if settings.isDebugMode == true then
         logger.debug cmd
      end

      listTypes = `#{cmd}`

      if $?.exitstatus == 0 then
         "#{listTypes}"
      else
         logger.error "failure of #{cmd}"
         status API_RESOURCE_NOT_FOUND
      end
   end

   ## =================================================================
   ##
   ## GET version
   ##
   ## curl -X GET http://localhost:4567/dec/arc/version

   get ARC::API_URL_VERSION do
      msg = "GET #{ARC::API_URL_VERSION} : minarc version: #{ARC::VERSION}"
      @@logger.info(msg)
      "#{@@node} : #{ARC::VERSION}"
   end

   ## =================================================================
   ##
   ## minArcRetrieve_LIST FILENAMES
   ##
   get "#{API_URL_LIST_FILENAME}/:filename" do |filename|
      msg = "GET #{API_URL_LIST_FILENAME}/#{params[:filename]}"
      @@logger.info("[ARC_205] Search: #{params[:filename]}")

      cmd = "minArcRetrieve -f \'#{params[:filename]}\' --noserver -l"

      if settings.isDebugMode == true then
         msg = "MINARC_Server::#{cmd}"
         @@logger.debug(msg)
      end

      listFiles = `#{cmd}`

#      puts
#      puts $?.exitstatus
#      puts

      if settings.isDebugMode == true then
         logger.debug listFiles
      end

      if $?.exitstatus == 0 then
         "#{listFiles}"
      else
         logger.info "#{params[:filename]} / files not found"
         status API_RESOURCE_NOT_FOUND
      end
   end

   ## =================================================================
   ##
   ## minArcStatus by filename
   ##
   get "#{API_URL_STAT_FILENAME}/:filename" do |filename|
      if settings.isDebugMode == true then
         msg = "GET #{API_URL_STAT_FILENAME} : get #{params[:filename]}"
         @@logger.debug(msg)
      end

      fileStatus = ARC::FileStatus.new(params[:filename], true)

      if settings.isDebugMode == true then
         fileStatus.setDebugMode
      end

      ret = fileStatus.statusFileName("#{params[:filename]}")

      if settings.isDebugMode == true then
         puts "----------------------------------"
         puts ret
         puts "----------------------------------"
      end

      @@logger.info("[ARC_204] Status: #{params[:filename]}")

      content_type :json
      ret
   end

   ## =================================================================
   ##
   ## minArcRetrieve_LIST FILETYPES
   ##
   get "#{API_URL_LIST_FILETYPE}/:filetype" do |filetype|
      cmd = "minArcRetrieve -t #{params[:filetype]} --noserver -l"

      if settings.isDebugMode == true then
         puts "GET #{API_URL_LIST_FILETYPE}/#{params[:filetype]}"
         puts "MINARC_Server::#{cmd}"
      end

      listFiles = `#{cmd}`

      if $?.exitstatus == 0 then
         "#{listFiles}"
      else
         logger.info "#{params[:filename]} / files not found"
         status API_RESOURCE_NOT_FOUND
      end
   end

   ## ----------------------------------------------------------
   ##
   ## Upload with POST multipart/form-data
   ##
   ## curl -X POST -F 'field1=value1' -F 'field2=value2' -F file=@/tmp/1.plist http://localhost:4567/dec/arc/minArcStore
   ##
   post ARC::API_URL_STORE do

      @@logger.info "POST #{ARC::API_URL_STORE}/#{params[:file][:filename]}"

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
      FileUtils.mv(tempfile.path, filename)

      # ---------------------------------------------
      #
      # Process the form parameters

      cmd = "minArcStore"

      cmd = "#{cmd} -f #{Dir.pwd}/#{filename} --noserver"

      params.each{|param|
         if param[0].slice(0,1) != "-" then
            next
         end
         cmd = "#{cmd} #{param[0]} #{param[1]} "
      }

      if settings.isDebugMode == true then
         @@logger.debug("MINARC_Server::API_URL_STORE => #{cmd}")
      end

      retStr = `#{cmd}`

      if $?.exitstatus != 0 then
         @@logger.error("#{retStr}")
         "#{retStr}"
         status API_RESOURCE_ERROR
      else
         @@logger.info("[ARC_203] Archived: #{retStr.split("Archived: ")[1].chop}")
         response.headers['filename'] = retStr.split("Archived: ")[1]
         status API_RESOURCE_CREATED
      end

      #
      # ---------------------------------------------

      Dir.chdir(prevDir)
      FileUtils.rm_rf(reqDir)

   end

   ## ================================================================
   ##
   ##
   ## minArcDelete
   ##
   get "#{API_URL_DELETE}/:filename" do |filename|

      if settings.isDebugMode == true then
         msg = "GET #{API_URL_DELETE} : get #{params[:filename]}"
         @@logger.debug(msg)
      end

      cmd = "minArcDelete -f #{params[:filename]} --noserver"

      if settings.isDebugMode == true then
         @@logger.debug(cmd)
      end

      ret = system(cmd)

      if ret == false then
         @@logger.error("[ARC_610] #{params[:filename]} not present in the archive")
         status API_RESOURCE_NOT_FOUND
      else
         @@logger.info("[ARC_205] Deleted : #{params[:filename]}")
         status API_RESOURCE_DELETED
      end

   end
   ## ----------------------------------------------------------

   # ----------------------------------------------------------
   #
   # minArcRetrieve
   #
   get "/kaka/#{API_URL_RETRIEVE}/:filename" do |filename|

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
         puts "----------------------------------"
         puts ret
         puts "----------------------------------"
      end

      content_type :json
      ret.to_json
   end

   ## ================================================================
   ##
   ## minArcStatus global
   ##

   get ARC::API_URL_STAT_GLOBAL do
      @@logger.info("[ARC_230] Requested Status Global")
      cmd = "minArcStatus -g --noserver"
      if settings.isDebugMode == true then
         @@logger.debug(cmd)
      end
      ret = `#{cmd}`
      content_type :json
      ret.to_json
   end
   ## ================================================================

   not_found do
      "MINARC_Server unexpected: page #{request.path_info} not found\n"
   end

   ## ----------------------------------------------------------

   get '/fake-error' do
      status 500
      "There is nothing wrong really :-p"
   end

   ## -----------------------------------------------------------

   get '/' do
      user = request.env["REMOTE_USER"]
      puts
      puts user
      puts
      puts params[:name]
      puts
      code = "<%= Time.now %>"
      erb code
   end

   ## -----------------------------------------------------------

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

   ## -----------------------------------------------------------


   ## -----------------------------------------------------------
   ##
   ## Release the activerecord connection upon every request

   after do
      @@logger.info("SINATRA::AFTER BLOCK")
      ActiveRecord::Base.connection.close
   end

   ## -----------------------------------------------------------

   ## ================================================================

   def self.run!
      puts
      puts "MINARC_Server::run!"
      puts
      super do |server|
         puts "making SSL true"
         server.ssl = true
         server.ssl_options = {
            :cert_chain_file  => File.join(File.dirname(File.expand_path(__FILE__)), "../../config") + "/cert.pem",
            :private_key_file => File.join(File.dirname(File.expand_path(__FILE__)), "../../config") + "/key.pem",
            :verify_peer      => true
         }
      end
   end

   ## ================================================================
   ## MAIN
   run! if __FILE__ == $0
   ## ================================================================

end # class
