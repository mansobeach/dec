#!/usr/bin/env ruby

#########################################################################
##
## Ruby source for #CheckerWebDAVConfig class
##
## Written by DEIMOS Space S.L. (bolf)
##
## Data Exchange Component -> Common Transfer Component
## 
## Git: $Id: CheckerWebDAVConfig.rb,v 1.11 2014/10/13 18:39:54 algs Exp $
##
#########################################################################

require 'net/dav'

require 'dec/InterfaceHandlerWebDAV'

module DEC

class CheckerWebDAVConfig

   include DEC

   ## ----------------------------------------------------------------

   ## Class constructor.
   ## IN (struct) Struct with all relevant field required for net_dav connections.
   def initialize(davServerStruct, strInterfaceCaption = "", logger = nil)
      @logger      = logger
      @isDebugMode = false
      checkModuleIntegrity
      @davElement  = davServerStruct
      if strInterfaceCaption != "" then
         @entity = strInterfaceCaption
      else
         @entity = "Generic"
      end
      @handler = InterfaceHandlerWebDAV.new(@entity, @logger)
   end
   ## ----------------------------------------------------------------
   
   ## Main method of the class which performs the check.
   ## IN (struct) Struct with all relevant field required for ftp/sftp connections.
   def check(bPush, bPull)
      if @isDebugMode == true then
         showDAVConfig(true, true)
      end
     
      retVal = checkDAVConfig(bPush, bPull)
     
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
      @logger.debug("CheckerWebDAVConfig debug mode is on")
   end
   # -------------------------------------------------------------

private

   @isDebugMode       = false      
   @@davElement       = nil
   @sftpClient        = nil
   @ftReadConf        = nil

   ## -----------------------------------------------------------

   ## Check that everything needed by the class is present.
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

   end
   ## -----------------------------------------------------------
   
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
      
         retVal = @handler.getDirList(@davElement[:uploadDir])
            
         if retVal == false then
            @logger.error("#{'1F480'.hex.chr('UTF-8')} CheckerWebDAV::checkDAVConfig Sending mode is not supported")
            raise
         else
            return true
         end
      end
      # --------------------------------
      
      if bCheck4Receive == true then
         if @isDebugMode == true then
            puts "Checking Pull Configuration for WebDAV protocol"
         end
         arrElements = @davElement[:arrDownloadDirs]
         bError = false
         arrElements.each{|element|
            dir = element[:directory]
            retVal = @handler.getDirList(dir)
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

   # -------------------------------------------------------------

end # end class


end # module


