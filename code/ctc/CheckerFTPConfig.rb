#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #CheckerFTPConfig class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: CheckerFTPConfig.rb,v 1.3 2006/10/19 14:07:19 decdev Exp $
#
#########################################################################

require 'net/ftp'

require "ctc/SFTPBatchClient"
require "ctc/FTPClientCommands"


module CTC

class CheckerFTPConfig

   include CTC
   include FTPClientCommands
   #--------------------------------------------------------------

   # Class constructor.
   # IN (struct) Struct with all relevant field required for ftp/sftp connections.
   def initialize(ftpServerStruct, strInterfaceCaption = "")
      @isDebugMode = false
      @ftpElement  = ftpServerStruct
      if strInterfaceCaption != "" then
         @entity = strInterfaceCaption
      else
         @entity = "Generic"
      end
      checkModuleIntegrity
   end
   #-------------------------------------------------------------
   
   # Main method of the class which performs the check.
   # IN (struct) Struct with all relevant field required for ftp/sftp connections.
   def check
      if @isDebugMode == true then
         showFTPConfig(true, true)
      end
     
      retVal = checkFTPConfig(true, true)
     
      return retVal
   end
   #-------------------------------------------------------------
   
   def check4Send
      if @isDebugMode == true then
         showFTPConfig(true, false)
      end
   
      retVal = checkFTPConfig(true, false)
      return retVal
   end
   #-------------------------------------------------------------
   
   def check4Receive
      if @isDebugMode == true then
         showFTPConfig(false, true)
      end
   
      retVal = checkFTPConfig(false, true)
      return retVal   
   end
   #-------------------------------------------------------------
   
   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "CheckerFTPConfig debug mode is on"
   end
   #-------------------------------------------------------------

private

   @isDebugMode       = false      
   @@ftpElement       = nil
   @sftpClient        = nil
   @ftReadConf        = nil

   #-------------------------------------------------------------

   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      
      if !ENV['DCC_TMP'] and !ENV['DEC_TMP'] then
         puts "\nDCC_TMP environment variable not defined !\n"
         bDefined = false
      end
      
      if bDefined == false then
         puts "\nError in CheckerFTPConfig::checkModuleIntegrity :-(\n\n"
         exit(99)
      end
                  
      if ENV['DEC_TMP'] then
         @tmpDir         = %Q{#{ENV['DEC_TMP']}}  
      else
         @tmpDir         = %Q{#{ENV['DCC_TMP']}}  
      end        

      time   = Time.new
      time.utc
      @batchFile = %Q{#{@tmpDir}/.checker.#{@entity}.#{time.to_f.to_s}.#{Random.new.rand(1.5)}}
   end
   #-------------------------------------------------------------
   
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
      
      puts
      if @ftpElement[:isSecure] == true then 
         puts "Secure conection is used (sftp)"
      else
         puts "NON Secure conection is used (ftp)"
      end
      if @ftpElement[:isSecure] == true and @ftpElement[:isCompressed] == true then 
        puts "Communication data is compressed (sftp)"
      end
      puts "protocol     -> #{@ftpElement[:protocol]}"
      puts "hostname     -> #{@ftpElement[:hostname]}"
      puts "port         -> #{@ftpElement[:port]}"
      puts "user         -> #{@ftpElement[:user]}"
      puts "password     -> #{@ftpElement[:password]}"
      if b4Send == true then
      	puts "upload dir   -> #{@ftpElement[:uploadDir]}"
      	puts "upload tmp   -> #{@ftpElement[:uploadTemp]}"
      end
      if b4Receive == true then
         arrDirs = @ftpElement[:arrDownloadDirs]
         arrDirs.each{|element|
            puts "download dir -> #{element[:depthSearch]} | #{element[:directory]}"
         }
      end
      puts "============================================================="
      puts
   end   
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   # Check FTP params.
   # It returns true if the check is successful
   # otherwise it returns false.
   def checkFTPConfig(bCheck4Send, bCheck4Receive)

      ret = true
      
      if @ftpElement[:port].to_i == 21 and @ftpElement[:isSecure] == true then
         puts "\nWARNING: you may experience problems with Secure Mode and Port 21 \n\n"
         puts "Check your configuration \n" 
      end
      if @ftpElement[:port].to_i == 22 and @ftpElement[:isSecure] == false then
         puts "\nWARNING: you may experience problems with NON Secure Mode and Port 22 \n\n"
         puts "Check your configuration \n" 
      end      

      # Check 4 Sending
      if bCheck4Send == true then

         if @ftpElement[:uploadDir] == "" then
            puts "\nConfiguration Error in #{@entity} I/F"
            puts "UploadDir configuration element cannot be void\n"
            ret = false         
         end

         if @ftpElement[:uploadTemp] == "" then
            puts "\nConfiguration Error in #{@entity} I/F"
            puts "UploadTemp configuration element cannot be void\n"
            ret = false         
         end
   
         retVal = checkRemoteDirectory(@ftpElement[:uploadDir])
         if retVal == false then
            puts "\nConfiguration Error in #{@entity} I/F"
            puts "Unable to access to remote dir #{@ftpElement[:uploadDir]}\n"
            ret = false
         end
      
         retVal = checkRemoteDirectory(@ftpElement[:uploadTemp])
         if retVal == false then
            puts "\nConfiguration Error in #{@entity} I/F"
            puts "Unable to access to remote dir #{@ftpElement[:uploadTemp]}\n"
            ret = false
         end
         
         if @ftpElement[:uploadTemp] == @ftpElement[:uploadDir] then
            puts "\nConfiguration Error in #{@entity} I/F"
            puts "Upload directory and UploadTemp cannot be the same directory\n"            
            ret = false
         end
      end

      # Check 4 Receive
      # We set as a configuration error when ALL download directories are un-reachable
      if bCheck4Receive == true then   
         arrElements = @ftpElement[:arrDownloadDirs]
         bNoError = false
         bWarning = false
         arrElements.each{|element|
            dir = element[:directory]
            retVal = checkRemoteDirectory(dir)
            if retVal == false then
#               puts "\nConfiguration Error in #{@entity} I/F"
               puts
               puts "#{@entity} I/F: Unable to access to remote dir #{element[:directory]}\n"
               bWarning = true
            else
               bNoError = true
            end
         }
         if bNoError == true and bWarning == true then
            puts
            puts "Warning: some of configured Download dirs are not reachable !  :-|"
         end
         if ret == true then
            ret = bNoError
         end
      end
      
      return ret
      
   end
   #-------------------------------------------------------------
   
   # Check that the remote directories exists
   def checkRemoteDirectory(dir)
      
      host = @ftpElement[:hostname]
      port = @ftpElement[:port].to_i
      user = @ftpElement[:user]
      pass = @ftpElement[:password]

      if @ftpElement[:isSecure] == false then
         begin
            @ftp = Net::FTP.new(host)
            @ftp.login(user, pass)
         rescue Exception
            puts
            puts "Error login at #{host} with #{user} / #{pass}"
            return false
         end

         begin
#             @ftp = Net::FTP.new(host)
#             @ftp.login(user, pass)
            @ftp.passive = true
            @ftp.chdir(dir)
         rescue Exception => e
         
            puts "Directory => #{dir}"
            puts
            puts
            puts e.to_s
            puts
            exit
         
            # ---------------------
            # 20140923 - BL
            # If remote directory does not exist
            # it is then created
            
            @ftp = Net::FTP.new(host)
            @ftp.login(user, pass)
            @ftp.mkdir(dir)
            # ---------------------
            return false
         end
         return true
      end

      if @ftpElement[:isSecure] == true then
         sftpClient = SFTPBatchClient.new(@ftpElement[:hostname],
                                             @ftpElement[:port],
                                             @ftpElement[:user],
                                             @batchFile)
         if @isDebugMode == true then
            sftpClient.setDebugMode
         end

         sftpClient.addCommand("cd #{dir}",
                                  nil,
                                  nil)
                                  
         sftpClient.addCommand("pwd",
                                nil,
                                nil)                         
   
         retVal = sftpClient.executeAll
         return retVal
      end
      
   end
   #-------------------------------------------------------------

end # end class


end # module


