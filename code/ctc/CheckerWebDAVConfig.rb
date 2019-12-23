#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #CheckerWebDAVConfig class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: CheckerWebDAVConfig.rb,v 1.11 2014/10/13 18:39:54 algs Exp $
#
#########################################################################

require 'net/dav'

module CTC

class CheckerWebDAVConfig

   include CTC

   ## ----------------------------------------------------------------

   ## Class constructor.
   ## IN (struct) Struct with all relevant field required for net_dav connections.
   def initialize(davServerStruct, strInterfaceCaption = "")
      @isDebugMode = false
      checkModuleIntegrity
      @davElement  = davServerStruct
      if strInterfaceCaption != "" then
         @entity = strInterfaceCaption
      else
         @entity = "Generic"
      end
   end
   ## ----------------------------------------------------------------
   
   ## Main method of the class which performs the check.
   ## IN (struct) Struct with all relevant field required for ftp/sftp connections.
   def check
      if @isDebugMode == true then
         showDAVConfig(true, true)
      end
     
      retVal = checkDAVConfig(true, true)
     
      return retVal
   end
   ## ---------------------------------------------------------------
   
   def check4Send
      if @isDebugMode == true then
         showDAVConfig(true, false)
      end
   
      retVal = checkDAVConfig(true, false)
      return retVal
   end
   # -------------------------------------------------------------
   
   def check4Receive
      if @isDebugMode == true then
         showDAVConfig(false, true)
      end  
      retVal = checkDAVConfig(false, true)
      return retVal   
   end
   # -------------------------------------------------------------
   
   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "CheckerWebDAVConfig debug mode is on"
   end
   # -------------------------------------------------------------

private

   @isDebugMode       = false      
   @@davElement       = nil
   @sftpClient        = nil
   @ftReadConf        = nil

   #-------------------------------------------------------------

   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      
      if !ENV['DCC_CONFIG'] and !ENV['DEC_CONFIG'] then
         puts "\nDEC_CONFIG | DCC_CONFIG environment variable not defined !  :-(\n\n"
         bCheckOK = false
         bDefined = false
      end
      
      if bDefined == false then
         puts "\nError in CheckerFTPConfig::checkModuleIntegrity :-(\n\n"
         exit(99)
      end
                  
      tmpDir = nil
         
      if ENV['DEC_CONFIG'] then
         tmpDir         = %Q{#{ENV['DEC_CONFIG']}}  
      else
         tmpDir         = %Q{#{ENV['DCC_CONFIG']}}  
      end

      time   = Time.new
      time.utc
      @batchFile = %Q{#{tmpDir}/.#{time.to_f.to_s}}
   end
   #-------------------------------------------------------------
   
   # It shows the DAV Configuration.
   def showDAVConfig(b4Send, b4Receive)
      msg = ""
      if @entity != "" then
         msg = "Configuration of #{@entity} I/F"
      else
         msg = "Checking WebDAV Configuration"
      end
      puts
      puts "============================================================="
      puts msg
      
      puts
      if @davElement[:isSecure] == true then 
        puts "Secure conection is used (HTTPS)"
      else
        puts "NON Secure conection is used (plain HTTP)"
      end
      if @davElement[:isSecure] == true and @davElement[:isCompressed] == true then 
        puts "Communication data is compressed (sftp)"
      end
      puts "hostname     -> #{@davElement[:hostname]}"
      puts "port         -> #{@davElement[:port]}"
      puts "user         -> #{@davElement[:user]}"
      puts "password     -> #{@davElement[:password]}"
      if b4Send == true then
      	puts "upload dir   -> #{@davElement[:uploadDir]}"
      	puts "upload tmp   -> #{@davElement[:uploadTemp]}"
      end
      if b4Receive == true then
         puts
         puts @davElement
         puts
         arrDirs = @davElement[:arrDownloadDirs]
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
   def checkDAVConfig(bCheck4Send, bCheck4Receive)

      ret = true
      # --------------------------------
      # Check 4 Sending
      if bCheck4Send == true then
         puts "CheckerWebDAV::checkDAVConfig Sending mode is not supported"
         exit(99)      
      end
      # --------------------------------
      
      if bCheck4Receive == true then   
         arrElements = @davElement[:arrDownloadDirs]
         bError = false
         arrElements.each{|element|
            dir = element[:directory]
            retVal = checkRemoteDirectory(dir)
            if retVal == false then
               puts "Error: #{@entity} I/F: Unable to access to remote dir #{element[:directory]} :-(\n\n"
               bError = true
            end
         }
         if ret == true then
            ret = !bError
         end
      end
      
      # --------------------------------
      
      return ret
      
   end
   ## -------------------------------------------------------------
   ##
   ## Check that the remote directories exists
   ##
   def checkRemoteDirectory(path, mirror=false)
      port = @davElement[:port].to_i
      user = @davElement[:user]
      pass = @davElement[:password]
      host = "http://#{@davElement[:hostname]}:#{@davElement[:port]}/"
      dav  = Net::DAV.new(host, :curl => false)
      dav.verify_server = true

      begin
         options  = ''
         props    = dav.propfind(path, options)
         
         if props != nil and @isDebugMode == true then
            puts
            puts "WebDAV checked OK: #{host} => #{path}"
            puts 
         end
      rescue Exception => e
         puts "Failed PROPFIND request to #{host}#{path}"
         puts
         puts e.to_s
         puts
         if @isDebugMode == true then
            puts e.backtrace
            puts
         end
         return false
      end
      return true
   end
   ## -------------------------------------------------------------

   def checkWriteRemoteDirectoryNonSecure(dir, mirror=false)
      retVal  = true
      prevDir = Dir.pwd

      if @davElement[:isSecure] == true then
         puts "Error in CheckerFTPConfig::checkWriteRemoteDirectory"
         puts "Method not supported yet for secure protocol ! :-("
         puts
         return true
      end
   
      Dir.chdir(ENV['DEC_TMP'])
   
      file     = "satansaldemi.txt"
      system("echo \'satan sal de mi\' > #{file}")   
      
      host     = @davElement[:hostname]
      port     = @davElement[:port].to_i
      user     = @davElement[:user]
      pass     = @davElement[:password]
      passive  = @davElement[:isPassive]

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
   # -------------------------------------------------------------

end # end class


end # module


