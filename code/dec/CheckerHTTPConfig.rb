#!/usr/bin/env ruby

#########################################################################
##
## Ruby source for #CheckerHTTPConfig class
##
## Written by DEIMOS Space S.L. (bolf)
##
## Data Exchange Component
## 
## Git: $Id: CheckerHTTPConfig.rb,v 1.11 2014/10/13 18:39:54 algs Exp $
##
#########################################################################

require 'curb'
require 'uri'
require 'net/dav'

require 'dec/InterfaceHandlerHTTP'

module DEC

class CheckerHTTPConfig

   include DEC
   
   ## ----------------------------------------------------------------

   ## Class constructor.
   ## IN (struct) Struct with all relevant field required for net_dav connections.
   def initialize(httpServerStruct, strInterfaceCaption = "", logger = nil)
      @logger      = logger
      @isDebugMode = false
      checkModuleIntegrity
      @httpElement  = httpServerStruct
      if strInterfaceCaption != "" then
         @entity = strInterfaceCaption
      else
         @entity = "Generic"
      end
      @handler = InterfaceHandlerHTTP.new(@entity, @logger)
   end
   ## ----------------------------------------------------------------
   
   ## Main method of the class which performs the check.
   ## IN (struct) Struct with all relevant field required for ftp/sftp connections.
   def check
      if @isDebugMode == true then
         showHTTPConfig(true, true)
      end
     
      retVal = checkHTTPConfig(true, true)
     
      return retVal
   end
   ## -----------------------------------------------------------
   
   def check4Send
   
      if @isDebugMode == true then
         @logger.debug("Checking Push Configuration for HTTP protocol")
      end
   
      if @isDebugMode == true then
         showHTTPConfig(true, false)
      end
   
      retVal = checkHTTPConfig(true, false)
      return retVal
   end
   ## -----------------------------------------------------------
   
   def check4Receive
   
      if @isDebugMode == true then
         puts "Checking Pull Configuration for HTTP protocol"
      end
   
      if @isDebugMode == true then
         showHTTPConfig(false, true)
      end  
      retVal = checkHTTPConfig(false, true)
      return retVal   
   end
   ## -----------------------------------------------------------
   
   ## Set debug mode on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("CheckerHTTPConfig debug mode is on")
      @handler.setDebugMode
   end
   ## -----------------------------------------------------------

private

   @isDebugMode         = false      
   @@httpElement        = nil
   @ftReadConf          = nil

   ## -----------------------------------------------------------

   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      
      if !ENV['DEC_CONFIG'] then
         puts "\nDEC_CONFIG environment variable not defined !  :-(\n\n"
         bCheckOK = false
         bDefined = false
      end
      
      if bDefined == false then
         puts "\nError in CheckerHTTPConfig::checkModuleIntegrity :-(\n\n"
         exit(99)
      end
                  
   end
   ## -----------------------------------------------------------
   
   ## It shows the HTTP Configuration.
   def showHTTPConfig(b4Send, b4Receive)
      msg = ""
      if @entity != "" then
         msg = "Configuration of #{@entity} I/F for HTTP"
      else
         msg = "Checking HTTP Configuration"
      end
      puts
      puts "============================================================="
      puts msg
      
      puts
      if @httpElement[:isSecure] == true then 
         puts "Secure conection is used (HTTPS)"
      else
         puts "NON Secure conection is used (plain HTTP)"
      end

      puts "protocol     -> #{@httpElement[:protocol]}"
      puts "hostname     -> #{@httpElement[:hostname]}"
      puts "port         -> #{@httpElement[:port]}"
      puts "user         -> #{@httpElement[:user]}"
      puts "password     -> #{@httpElement[:password]}"
      
      if b4Send == true then
      	puts "upload dir   -> #{@httpElement[:uploadDir]}"
      	puts "upload tmp   -> #{@httpElement[:uploadTemp]}"
      end
      if b4Receive == true then
         puts
         puts @httpElement
         puts
         arrDirs = @httpElement[:arrDownloadDirs]
         arrDirs.each{|element|
            puts "download dir -> #{element[:depthSearch]} | #{element[:directory]}"
         }
      end
      puts "============================================================="
      puts
   end   
   ## -------------------------------------------------------------
   
   ## -------------------------------------------------------------
   
   ## Check WebDAV configuration.
   ## It returns true if the check is successful
   ## otherwise it returns false.
   def checkHTTPConfig(bCheck4Send, bCheck4Receive)

      ret = true
      # --------------------------------
      # Check 4 Sending
      if bCheck4Send == true then
         
         retVal = @handler.getDirList(@httpElement[:uploadDir])
            
         if retVal == false then
            ret = false
         end           
      end
      # --------------------------------
      
      if bCheck4Receive == true then
         bError = false
         listOfFiles = @handler.getPullList(true)
         listOfFiles.each{|fullpath|
            @logger.debug("[DEC_XXX] I/F #{@entity}: File #{File.basename(fullpath)} is available")
         }
      end
      
      # --------------------------------
      
      return ret
      
   end
   ## -------------------------------------------------------------
   ##
   ## Check that the remote directories exists
   ##
   def checkRemoteDirectory(path, mirror=false)
      port = @httpElement[:port].to_i
      user = @httpElement[:user]
      pass = @httpElement[:password]
      host = ""
      if @httpElement[:isSecure] == false then
         host = "http://#{@httpElement[:hostname]}:#{@httpElement[:port]}/"
      else
         host = "https://#{@httpElement[:hostname]}:#{@httpElement[:port]}/"
      end
      
      ## Treat URL as a file
      if path[-1, 1] != "/" then
         
         url = "#{host}#{path}"
         
         ret = Curl::Easy.http_head(url)

#         if @isDebugMode == true then
#            @logger.debug("#{url} => #{ret.status}")
#         end
            
         if ret.status.include?("200") == true then      
            if @isDebugMode == true then
               @logger.debug("Found #{File.basename(url)}")
            end
            return true
         else
            puts "#{ret.status} / #{url}"
            return false
         end

      end      
      
      dav  = Net::DAV.new(host, :curl => false)
      
      ## -------------------------------
      ## new configuration item VerifyPeerSSL is needed
      # dav.verify_server = true
      dav.verify_server = false
      ## -------------------------------

      ## -------------------------------
      ## if credentials are not empty in the configuration file
      if user != "" or (pass != "" and pass != nil) then
         if @isDebugMode == true then
            puts "Passing Credentials #{user} #{pass} to HTTP server"
         end
         dav.credentials(user, pass)
      end
      ## -------------------------------

      begin
         options  = ''
         props    = dav.propfind(path, options)
         
         if @isDebugMode == true then
            puts
            puts "WebDAV : #{host} => #{path}"
            puts props
            puts 
         end
      rescue Exception => e
         @logger.error("[DEC_613] I/F #{@entity}: #{e.to_s}")
         if @isDebugMode == true then
            @logger.debug(e.backtrace)
         end

         return false
      end
      return true
   end
   ## -------------------------------------------------------------

   def checkWriteRemoteDirectoryNonSecure(dir, mirror=false)
      retVal  = true
      prevDir = Dir.pwd

      if @httpElement[:isSecure] == true then
         puts "Error in CheckerFTPConfig::checkWriteRemoteDirectory"
         puts "Method not supported yet for secure protocol ! :-("
         puts
         return true
      end
   
      Dir.chdir(ENV['DEC_TMP'])
   
      file     = "satansaldemi.txt"
      system("echo \'satan sal de mi\' > #{file}")   
      
      host     = @httpElement[:hostname]
      port     = @httpElement[:port].to_i
      user     = @httpElement[:user]
      pass     = @httpElement[:password]
      passive  = @httpElement[:isPassive]

      cmd = self.createNcFtpPut(host,  \
                                port, \
                                user, \
                                pass, \
                                dir, \
                                dir, \
                                file, \
                                [], \
                                @isDebugMode, \
                                passive \
                               )

      ret = system(cmd)   

      if ret == false then
         retVal = false
      end

      system("rm -f #{file}")

      cmd = self.createNcFtpGet( host,  \
                                 port, \
                                 user, \
                                 pass, \
                                 dir, \
                                 file, \
                                 true, \
                                 @isDebugMode \
                                )

      if @isDebugMode == true then
         puts cmd
      end

      ret = system(cmd)   

      if ret == false then
         retVal = false
      end

      system("rm -f #{file}")

      Dir.chdir(prevDir)

      return retVal

   end
   ## -------------------------------------------------------------

   def putTestFile
      port  = @httpElement[:port].to_i
      user  = @httpElement[:user]
      pass  = @httpElement[:password]
      url   = ""
      
      if @httpElement[:uploadDir][0, 1] == "/" then
         url = "#{@httpElement[:hostname]}:#{@httpElement[:port]}#{@httpElement[:uploadDir]}"
      else
         url = "#{@httpElement[:hostname]}:#{@httpElement[:port]}/#{@httpElement[:uploadDir]}"
      end
      
      if @httpElement[:isSecure] == false then
         url = "http://#{url}"
      else
         url = "https://#{url}/"
      end
      
      system("echo \'test1.txt\' > ./test1.txt")
      
      if @isDebugMode == true then
         puts "#{url} / ./test1.txt"
      end
      
      ret = putFileSilent(url, user, pass, "./test1.txt", @isDebugMode)
      
      deleteFile(url, user, pass, "test1.txt", @isDebugMode)
               
   end
   ## -------------------------------------------------------------

   def postTestFile
   
   end
   ## -------------------------------------------------------------

end # end class


end # module

