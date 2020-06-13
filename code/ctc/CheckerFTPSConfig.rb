#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #CheckerFTPConfig class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Common Transfer Component
# 
# Git: $Id: CheckerFTPSConfig.rb,v 1.11 2014/10/13 18:39:54 algs Exp $
#
#########################################################################

require 'net/ftp'

module CTC

class CheckerFTPSConfig

   # --------------------------------------------------------------

   # Class constructor.
   # IN (struct) Struct with all relevant field required for ftp/sftp connections.
   def initialize(ftpServerStruct, strInterfaceCaption = "", logger = nil)
      @isDebugMode = false
      checkModuleIntegrity
      @ftpElement  = ftpServerStruct
      if strInterfaceCaption != "" then
         @entity = strInterfaceCaption
      else
         @entity = "Generic"
      end
      @logger = logger
   end
   # -------------------------------------------------------------
   
   # Main method of the class which performs the check.
   # IN (struct) Struct with all relevant field required for ftp/sftp connections.
   def check
      if @isDebugMode == true then
         showFTPConfig(true, true)
      end
     
      retVal = checkFTPConfig(true, true)
     
      return retVal
   end
   # -------------------------------------------------------------
   
   def check4Send
      if @isDebugMode == true then
         showFTPConfig(true, false)
      end
   
      retVal = checkFTPConfig(true, false)
      return retVal
   end
   # -------------------------------------------------------------
   
   def check4Receive
      if @isDebugMode == true then
         showFTPConfig(false, true)
      end  
      retVal = checkFTPConfig(false, true)
      return retVal   
   end
   # -------------------------------------------------------------
   
   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "CheckerFTPSConfig debug mode is on"
   end
   # -------------------------------------------------------------

private

   @isDebugMode       = false      
   @@ftpElement       = nil
   @sftpClient        = nil
   @ftReadConf        = nil

   ## -------------------------------------------------------------
   ##
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      
      if !ENV['DEC_CONFIG'] then
         puts "\nDEC_CONFIG | DCC_CONFIG environment variable not defined !  :-(\n\n"
         bCheckOK = false
         bDefined = false
      end
      
      if !ENV['DEC_TMP'] then
         raise "Error in CheckerFTPSConfig::checkModuleIntegrity :-("
      end
                  
      tmpDir = %Q{#{ENV['DEC_TMP']}}  
         
      time   = Time.new
      time.utc
      @batchFile = %Q{#{tmpDir}/.#{time.to_f.to_s}}
   end
   ## -------------------------------------------------------------
   
   # It shows the FTP Configuration.
   def showFTPConfig(b4Send, b4Receive)
      msg = ""
      if @entity != "" then
         msg = "Configuration of #{@entity} I/F"
      else
         msg = "Checking FTP Configuration"
      end
      puts
      puts "============================================================="
      puts msg
      
      puts "hostname       -> #{@ftpElement[:hostname]}"
      puts "port           -> #{@ftpElement[:port]}"
      puts "user           -> #{@ftpElement[:user]}"
      puts "password       -> #{@ftpElement[:password]}"
      puts "peer SSL check -> #{@ftpElement[:verifyPeerSSL]}"
      
      if b4Send == true then
      	puts "upload dir   -> #{@ftpElement[:uploadDir]}"
      	puts "upload tmp   -> #{@ftpElement[:uploadTemp]}"
      end

      if b4Receive == true then
         puts
         puts @ftpElement
         puts
         arrDirs = @ftpElement[:arrDownloadDirs]
         arrDirs.each{|element|
            puts "download dir -> #{element[:depthSearch]} | #{element[:directory]}"
         }
      end
      puts "============================================================="
      puts
   end   
   # -------------------------------------------------------------
   
   # -------------------------------------------------------------
   
   # Check FTP params.
   # It returns true if the check is successful
   # otherwise it returns false.
   def checkFTPConfig(bCheck4Send, bCheck4Receive)

      mirror=false
#      if @ftpElement[:FTPServerMirror] != nil then
#         mirror=true
#      end

      ret = true
      
      if @ftpElement[:port].to_i == 22 and @ftpElement[:isSecure] == false then
         puts "\nWarning: #{@ftpElement[:mnemonic]} you may experience problems with NON Secure Mode and Port 22 :-|\n\n"
         puts "Check your configuration \n" 
      end      

      # Check 4 Sending
      if bCheck4Send == true then

         if @ftpElement[:uploadDir] == "" then
            puts "\nError: in #{@entity} I/F: UploadDir configuration element cannot be void :-(\n"
            ret = false         
         end

         if @ftpElement[:uploadTemp] == "" then
            puts "\nError: in #{@entity} I/F: UploadTemp configuration element cannot be void :-(\n"
            ret = false         
         end
         
#         if @ftpElement[:uploadTemp] == @ftpElement[:uploadDir] then
#            puts "\nError: in #{@entity} I/F: Upload directory and UploadTemp cannot be the same directory :-(\n"            
#            ret = false
#         end

   #dynamic directories
         dir=@ftpElement[:uploadDir]
         if dir.include?('[') then #it has dynamic uploadDirs
            puts "\nWarning: #{@entity} is using dynamic directories. Only checking directory before the expression !"
            dir= dir.slice(0,dir.index('['))
         end
   ###  
         retVal = checkRemoteDirectory(dir)
         if retVal == false then
            puts "\nError: in #{@entity} I/F: Unable to access to remote dir #{dir} :-(\n"
            ret = false
         end

         retVal = checkRemoteDirectory(@ftpElement[:uploadTemp])
         if retVal == false then
            puts "\nError: in #{@entity} I/F: Unable to access to remote dir #{@ftpElement[:uploadTemp]} :-(\n"
            ret = false
         end

         if @ftpElement[:isSecure] == false then
            retVal = checkWriteRemoteDirectoryNonSecure(@ftpElement[:uploadTemp])

            if retVal == false then
               puts "\nError: in #{@entity} I/F: Unable to write into remote dir uploadTemp #{@ftpElement[:uploadTemp]} :-(\n"
               ret = false
            end
         end

         if @ftpElement[:isSecure] == false then
            retVal = checkWriteRemoteDirectoryNonSecure(@ftpElement[:uploadDir])

            if retVal == false then
               puts "\nError: in #{@entity} I/F: Unable to write into remote dir uploadDir #{@ftpElement[:uploadDir]} :-(\n"
               ret = false
            end
         end
      
      end

      ## Check Pull
      ## We set as a configuration error when ALL download directories are un-reachable
      if bCheck4Receive == true then   
         arrElements = @ftpElement[:arrDownloadDirs]
#         bNoError = false
#         bWarning = false
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
      
      return ret
      
   end
   
   ## -----------------------------------------------------------
   ##
   ## Check that the remote directories exists
   def checkRemoteDirectory(dir)
      host     = @ftpElement[:hostname]
      port     = @ftpElement[:port].to_i
      user     = @ftpElement[:user]
      pass     = @ftpElement[:password]
      passive  = @ftpElement[:isPassive]
      chkSSL   = @ftpElement[:verifyPeerSSL]
      ftps     = nil
            
      begin
         if chkSSL == true then
            hOptions = Hash.new
            hOptions[:ssl] = true
            ftps = Net::FTP.new(host,hOptions)
         else
            ftps = Net::FTP.new(host, ssl: {:verify_mode => OpenSSL::SSL::VERIFY_NONE})
         end
      rescue Exception => e
         if @isDebugMode == true then
            puts
            puts e.backtrace
            puts
         end
         raise "[DEC_611] I/F #{@entity}: #{e.to_s}"
      end


      begin
         ftps.login(user, pass)      
      rescue Exception => e
         raise "[DEC_611] I/F #{@entity}: #{e.to_s}"
      end
      
      begin
         ftps.chdir(dir)
         
         if passive == true then
            ftps.passive = true
         else
            ftps.passive = false
         end
         
         items = ftps.list
      rescue Exception => e
         raise e
      end            
      
      return true      
   end
   ## -----------------------------------------------------------

   def checkWriteRemoteDirectoryNonSecure(dir, mirror=false)
      retVal  = true
      prevDir = Dir.pwd

      if @ftpElement[:isSecure] == true then
         puts "Error in CheckerFTPConfig::checkWriteRemoteDirectory"
         puts "Method not supported yet for secure protocol ! :-("
         puts
         return true
      end
   
      Dir.chdir(ENV['DEC_TMP'])
   
      file     = "satansaldemi.txt"
      system("echo \'satan sal de mi\' > #{file}")   
      
      host     = @ftpElement[:hostname]
      port     = @ftpElement[:port].to_i
      user     = @ftpElement[:user]
      pass     = @ftpElement[:password]
      passive  = @ftpElement[:isPassive]

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


