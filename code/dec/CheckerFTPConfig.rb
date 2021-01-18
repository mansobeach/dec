#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #CheckerFTPConfig class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Common Transfer Component
# 
# Git: $Id: CheckerFTPConfig.rb,v 1.11 2014/10/13 18:39:54 algs Exp $
#
#########################################################################

require 'net/ftp'

require 'ctc/SFTPBatchClient'
require 'ctc/FTPClientCommands'


module CTC

class CheckerFTPConfig

   include CTC
   include FTPClientCommands
   # --------------------------------------------------------------

   # Class constructor.
   # IN (struct) Struct with all relevant field required for ftp/sftp connections.
   def initialize(ftpServerStruct, strInterfaceCaption = "", logger = nil)
      @logger        = logger
      @isDebugMode   = false
      checkModuleIntegrity
      @ftpElement    = ftpServerStruct
      if strInterfaceCaption != "" then
         @entity = strInterfaceCaption
      else
         @entity = "Generic"
      end
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
      puts "CheckerFTPConfig debug mode is on"
   end
   # -------------------------------------------------------------

private

   @isDebugMode       = false      
   @@ftpElement       = nil
   @sftpClient        = nil
   @ftReadConf        = nil

   ## -----------------------------------------------------------

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
         
      if ENV['DEC_TMP'] then
         tmpDir         = %Q{#{ENV['DEC_TMP']}}  
      else
         tmpDir         = "/tmp"  
      end

      time   = Time.new
      time.utc
      @batchFile = %Q{#{tmpDir}/.#{time.to_f.to_s}}
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
      puts "hostname     -> #{@ftpElement[:hostname]}"
      puts "port         -> #{@ftpElement[:port]}"
      puts "user         -> #{@ftpElement[:user]}"
      puts "password     -> #{@ftpElement[:password]}"
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
      if @ftpElement[:port].to_i == 21 and @ftpElement[:isSecure] == true then
         puts "\nWarning: you may experience problems with Secure Mode and Port 21 :-|\n\n"
         puts "Check your configuration \n" 
      end
      if @ftpElement[:port].to_i == 22 and @ftpElement[:isSecure] == false then
         puts "\nWarning: #{@ftpElement[:mnemonic]} you may experience problems with NON Secure Mode and Port 22 :-|\n\n"
         puts "Check your configuration \n" 
      end      

      # 
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
         retVal = checkRemoteDirectory(dir, false)
         if retVal == false then
            if @logger != nil then
               @logger.error("[DEC_612] I/F #{@entity}: Cannot reach #{dir} directory")
            else 
               puts "\nError: in #{@entity} I/F: Unable to access to remote dir #{dir} :-(\n"
            end
            ret = false
         end

         retVal = checkRemoteDirectory(@ftpElement[:uploadTemp], false)
         if retVal == false then
            if @logger != nil then
               @logger.error("[DEC_612] I/F #{@entity}: Cannot reach #{@ftpElement[:uploadTemp]} directory")
            else 
               puts "\nError: in #{@entity} I/F: Unable to access to remote dir #{@ftpElement[:uploadTemp]} :-(\n"
            end
            ret = false
         end

         if @ftpElement[:isSecure] == false then
            retVal = checkWriteRemoteDirectoryNonSecure(@ftpElement[:uploadTemp])

            if retVal == false then
               if @logger != nil then
                  @logger.error("[DEC_712] I/F #{@entity}: Cannot reach #{@ftpElement[:uploadTemp]} directory")
               else
                  puts "\nError: in #{@entity} I/F: Unable to write into remote dir uploadTemp #{@ftpElement[:uploadTemp]} :-(\n"
               end
               ret = false
            end
         end

         if @ftpElement[:isSecure] == false then
            retVal = checkWriteRemoteDirectoryNonSecure(@ftpElement[:uploadDir])

            if retVal == false then
               if @logger != nil then
                  @logger.error("[DEC_712] I/F #{@entity}: Cannot reach #{@ftpElement[:uploadDir]} directory")
               else
                  puts "\nError: in #{@entity} I/F: Unable to write into remote dir #{@ftpElement[:uploadDir]} :-(\n"
               end
               ret = false
            end
         end

#         #mirror server check
#         if mirror then
#            retVal = checkRemoteDirectory(dir, true)
#            if retVal == false then
#               puts "\nError: in #{@entity} I/F: (Mirror Server) Unable to access to remote dir #{dir} :-(\n"
#               ret = false
#            end
#            retVal = checkRemoteDirectory(@ftpElement[:uploadTemp], true)
#            if retVal == false then
#               puts "\nError: in #{@entity} I/F: (Mirror Server) Unable to access to remote dir #{@ftpElement[:uploadTemp]} :-(\n"
#               ret = false
#            end
#         end
      
      end

      # Check 4 Receive
      # We set as a configuration error when ALL download directories are un-reachable
      if bCheck4Receive == true then   
         arrElements = @ftpElement[:arrDownloadDirs]
#         bNoError = false
#         bWarning = false
         bError = false
         arrElements.each{|element|
            dir = element[:directory]
            retVal = checkRemoteDirectory(dir)
            if retVal == false then
               @logger.error("[DEC_612] I/F #{@entity}: Cannot reach #{element[:directory]} directory")
               bError = true
            end
         }
         if mirror then
            arrElements.each{|element|
               dir = element[:directory]
               retVal = checkRemoteDirectory(dir, true)
               if retVal == false then
                  puts "\nError: #{@entity} I/F: (Mirror Server) Unable to access to remote dir #{element[:directory]} :-(\n"
                  bError = true
               end
            }
         end
#         if bNoError == true and bWarning == true then
#            puts
#            puts "Warning: some of configured Download dirs are not reachable !  :-|"
#         end
         if ret == true then
            ret = !bError
         end
      end
      
      return ret
      
   end
   # -------------------------------------------------------------
   
   # Check that the remote directories exists
   def checkRemoteDirectory(dir, mirror=false)
      if mirror then
         host = @ftpElement[:FTPServerMirror][:hostname]
         port = @ftpElement[:FTPServerMirror][:port].to_i
         user = @ftpElement[:FTPServerMirror][:user]
         pass = @ftpElement[:FTPServerMirror][:password]         
      else
         host = @ftpElement[:hostname]
         port = @ftpElement[:port].to_i
         user = @ftpElement[:user]
         pass = @ftpElement[:password]
      end

      if @ftpElement[:isSecure] == false then
         begin
            @ftp = Net::FTP.new(host)
            @ftp.login(user, pass)
            @ftp.passive = true
            @ftp.chdir(dir)
         rescue Exception => e
            @logger.error("[DEC_613] I/F #{@entity}: #{e.to_s}")
            if @isDebugMode == true then
               @logger.debug(e.backtrace)
            end
            return false
         end
         return true
      end

      if @ftpElement[:isSecure] == true then
         sftpClient = SFTPBatchClient.new(host, port, user, @batchFile)
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
   # -------------------------------------------------------------

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


