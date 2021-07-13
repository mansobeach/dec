#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #CheckerInterfaceConfig class
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === Data Exchange Component
## 
## Git: $Id: CheckerInterfaceConfig.rb,v 1.8 2010/04/09 10:12:28 algs Exp $
##
## This class is in charge of verify that the configuration
## for a given Interface defined dec_interfaces.xml, dec_incoming_files.xml 
## and dec_outgoing_files.xml is correct.
##
## ==== This class is in charge of verify that the FTP Configuration for a 
## ==== given I/F is correct. It performs tests connections to defined 
## ==== directories.
##
#########################################################################

require 'ctc/FTPClientCommands'
require 'ctc/SFTPBatchClient'

require 'ctc/CheckerFTPConfig'
require 'ctc/CheckerFTPSConfig'

require 'dec/CheckerHTTPConfig'
require 'dec/CheckerWebDAVConfig'

require 'ctc/CheckerLocalConfig'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigIncoming'
require 'dec/ReadConfigOutgoing'
require 'dec/EventManager'

module DEC

class CheckerInterfaceConfig
   
   include CTC
   include FTPClientCommands
    
   ## -----------------------------------------------------------

   ## Class constructor.
   ##
   ## IN (string) - Mnemonic of the Interface.
   ##
   ## IN (bool) [optional] - check parameters required for receiving
   ##
   ## IN (bool) [optional] - check parameters required for sending
   def initialize(entity, bCheckIncoming = true, bCheckOutgoing = true, logger = nil, isDebug = false)
      @bCheckIncoming                  = bCheckIncoming
      @bCheckOutgoing                  = bCheckOutgoing
      @logger                          = logger
      @isDebugMode                     = isDebug
      @entity                          = entity
      checkModuleIntegrity
      @inConf                          = ReadConfigIncoming.instance
      @outConf                         = ReadConfigOutgoing.instance
      @ftReadConf                      = ReadInterfaceConfig.instance
      @ftReadConf.update
      @ftpRecv                         = @ftReadConf.getFTPServer(@entity)
      @ftpSend                         = @ftReadConf.getFTPServer(@entity)
      @ftpRecv[:arrDownloadDirs]       = @inConf.getDownloadDirs(@entity)
      @ftpSend[:uploadDir]             = @outConf.getUploadDir(@entity)
      @ftpSend[:uploadTemp]            = @outConf.getUploadTemp(@entity)
            
      @check4Recv = nil
      @check4Send = nil
 
      ## -----------------------------------------
      ## Checkers for Receive / Pull      
           
      if @ftpRecv[:protocol].upcase == "WEBDAV" then
         @check4Recv                      = CheckerWebDAVConfig.new(@ftpRecv, @entity, @logger)
      end
      
      if @ftpRecv[:protocol].upcase == "FTPS" or @ftpSend[:protocol].upcase == "FTPES" then
         @check4Recv                      = CheckerFTPSConfig.new(@ftpRecv, @entity, @logger)
      end

      if @ftpRecv[:protocol].upcase == "SFTP" or @ftpRecv[:protocol].upcase == "FTP" then
         @check4Recv                      = CheckerFTPConfig.new(@ftpRecv, @entity, @logger)
      end

      if @ftpRecv[:protocol].upcase == "HTTP" then
         @check4Recv                      = CheckerHTTPConfig.new(@ftpRecv, @entity, @logger)
      end

      ## -----------------------------------------
      ## Checkers for Send / Push      
      
      if @ftpSend[:protocol].upcase == "FTPS" or @ftpSend[:protocol].upcase == "FTPES" then
         @check4Send                      = CheckerFTPSConfig.new(@ftpSend, @entity, @logger)
      end
            
      if @ftpSend[:protocol].upcase == "WEBDAV" then
         @check4Send                      = CheckerWebDAVConfig.new(@ftpSend, @entity, @logger)
      end
      
      if @ftpSend[:protocol].upcase == "HTTP" then
         @check4Send                      = CheckerHTTPConfig.new(@ftpSend, @entity, @logger)
         if @isDebugMode == true then
            @check4Send.setDebugMode
         end
      end
 
      if @ftpSend[:protocol].upcase == "FTP" or @ftpSend[:protocol].upcase == "SFTP" then
         @check4Send                      = CheckerFTPConfig.new(@ftpSend, @entity, @logger)
      end
      ## -----------------------------------------      
      
      @checkLocal4Send                 = CheckerLocalConfig.new(@ftpSend, @entity)  
      @checkLocal4Recv                 = CheckerLocalConfig.new(@ftpRecv, @entity)    
      @protocol                        = @ftReadConf.getProtocol(@entity)
            
      if @check4Recv == nil and @protocol != "LOCAL" then
         raise "No pull checker for #{@protocol}"
      end

      if @check4Send == nil and @protocol != "LOCAL" then
         raise "No push checker for #{@protocol}"
      end

   end
   ## -----------------------------------------------------------
   
   ## Main method of the class
   ## It returns a boolean True whether checks are OK. False otherwise.
   def check
      retVal = true
      if @isDebugMode == true and @protocol != "LOCAL" then
         @check4Send.setDebugMode
         @check4Recv.setDebugMode
      end
     
      if @bCheckOutgoing == true then
         if @protocol == "LOCAL" then
            retVal = @checkLocal4Send.checkLocal4Send
         else
            begin
               retVal = @check4Send.check4Send
#            rescue Exception => e
#               if @isDebugMode == true then
#                  puts e.backtrace
#               end
#               @logger.error(e.to_s)
#               retVal = false
            end
         end
      end

      if @bCheckIncoming == true then
         if retVal == true then
            if @protocol == "LOCAL" then
               retVal = @checkLocal4Recv.checkLocal4Receive
            else
               retVal = @check4Recv.check4Receive
            end
         else
            if @protocol == "LOCAL" then
               @checkLocal4Recv.checkLocal4Receive
            else
               @check4Recv.check4Receive
            end
         end
      end

      if retVal == true then
         retVal = checkTXRXParams
      else
         checkTXRXParams
      end
     
      if retVal == true
         retVal = checkEntityFlags
      else
         checkEntityFlags
      end

      if retVal == true then
         retVal = checkNotifyParams
      else
         checkNotifyParams
      end

      if retVal == true then
         retVal = checkEvents
      else
         checkEvents
      end

      return retVal
   end
   ## -----------------------------------------------------------

   ## Set debug mode on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("CheckerInterfaceConfig debug mode is on")
   end
   ## -----------------------------------------------------------

private

   @isDebugMode       = false      
   @ftpConfig         = nil
   @sftpClient        = nil
   @ftReadConf        = nil

   ## -----------------------------------------------------------

   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      
      if !ENV['DEC_TMP'] then
         puts "\nDEC_TMP variable not defined !  :-(\n\n"
         bCheckOK = false
         bDefined = false
      end
      
      if bDefined == false then
         puts "\nError in CheckerInterfaceConfig::checkModuleIntegrity :-(\n\n"
         exit(99)
      end

      tmpDir = nil
         
      if ENV['DEC_TMP'] then
         tmpDir         = %Q{#{ENV['DEC_TMP']}}  
      end

      time   = Time.new
      time.utc
      @batchFile = %Q{#{tmpDir}/.#{time.to_f.to_s}}
   end
   ## -----------------------------------------------------------

   def check4Receive
      if @isDebugMode == true then
         @check4Recv.setDebugMode
      end

      retVal = @check4Recv.check4Receive

      if retVal == true then
         retVal = checkTXRXParams
      else
         checkTXRXParams
      end
     
      if retVal == true
         retVal = checkEntityFlags 
      else
         checkEntityFlags
      end
     
      if retVal == true then
         retVal = checkNotifyParams
      else
         checkNotifyParams
      end
      
      if retVal == true then
         retVal = checkEvents
      else
         checkEvents
      end

      return retVal   
   end
   ## -----------------------------------------------------------
   
   def check4Send
      if @isDebugMode == true then
         @check4Send.setDebugMode
      end

      retVal = @check4Send.check4Send

      checkDeliveryMailAddresses

      if retVal == true then
         retVal = checkTXRXParams
      else
         checkTXRXParams
      end

      if retVal == true
         retVal = checkEntityFlags 
      else
         checkEntityFlags
      end
     
      if retVal == true then
         retVal = checkNotifyParams
      else
         checkNotifyParams
      end
      
      return retVal
   
   end
   ## -----------------------------------------------------------
   
   ## Check that all Flags have proper values, this is true or false
   def checkEntityFlags
      bRet = true
      
      valFlag = @ftReadConf.registerDirContent?(@entity)
      
      if valFlag != true and valFlag != false then
         puts "\nError: in #{@entity} I/F for Server.RegisterDirContent ! :-("
         puts "Accepted values for this field are true|false"
         bRet = false
      end

      valFlag = @ftReadConf.retrieveDirContent?(@entity)
      
      if valFlag != true and valFlag != false then
         puts "\nError: in #{@entity} I/F for Server.RetrieveDirContent ! :-("
         puts "Accepted values for this field are true|false"
         bRet = false
      end
      return bRet
   end
   ## -----------------------------------------------------------
   
   ## Check the integrity of different TXRX Params.
   ## It returns true if the check is successful 
   ## otherwise it returns false.
   def checkTXRXParams
      
      ret = true
      
      txrx = @ftReadConf.getTXRXParams(@entity)
      
      return ret
   end
   ## -----------------------------------------------------------
      
   def checkNotifyParams
         
      notifyParams = @ftReadConf.getNotifyParams(@entity)
      retVal = true
      
      if (notifyParams[:sendNotification].to_s.downcase == "true") then
         if notifyParams[:arrNotifyTo].length < 1 then
            puts "Error: Notify -> To  should have a list of email addresses :-("
            retVal = false
         end
      end
      return retVal
   end
   ## -----------------------------------------------------------

   def checkDeliveryMailAddresses
      listAddresses = @ftReadConf.getMailList(@entity)

      if listAddresses == nil then
         puts
         puts "Warning: DeliverByMailTo configuration for #{@entity} is not present  :-|"
         return false
      end

      if listAddresses.length == 0 then
         puts
         puts "Warning: DeliverByMailTo configuration for #{@entity} is empty  :-|"
      end
   end
   ## -----------------------------------------------------------

   def checkEvents
      events = @ftReadConf.getEvents(@entity)
      if events == nil then
         puts
         puts "Warning: Events configuration for #{@entity} is not present  :-|"
         puts
         return true
      end
      retVal         = true
      bAllowedEvent  = true
      arrEvents = events[:arrEvents]
      arrEvents.each{|event|
         if Events.include?(event["name"]) == false then
            puts "#{event["name"]} is not an allowed Event"
            retVal         = false
            bAllowedEvent  = false
         end
         cmd = event["cmd"].split(" ")[0]
         STDERR.reopen "/dev/null"
         ret = `which #{cmd}`
         if ret[0,1] != "/" then
            puts
            puts "Error: #{@entity} #{cmd} triggered by #{event["name"]} not in PATH ! :-("
            retVal = false
         end
      }
      STDERR.reopen(STDOUT)
      if bAllowedEvent == false then
         puts
         puts "Configuration allowed Events Name are "
         Events.each{|x| print x, " "}
         puts
      end
#       if retVal == false then
#          puts "Events"
#       end
      return retVal
   end
   ## -----------------------------------------------------------

end # class

end # module

