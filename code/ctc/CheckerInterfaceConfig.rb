#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #CheckerInterfaceConfig class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: CheckerInterfaceConfig.rb,v 1.6 2007/12/19 06:08:03 decdev Exp $
#
# === module Common Transfer Component (CTC)
# This class is in charge of verify that the configuration
# for a given Interface defined interfaces.xml is correct.
#
# ==== This class is in charge of verify that the FTP Configuration for a 
# ==== given I/F is correct. It performs tests connections to defined 
# ==== directories.
#
#########################################################################

require 'ctc/FTPClientCommands'
require 'ctc/SFTPBatchClient'
require 'ctc/ReadInterfaceConfig'
require 'ctc/CheckerFTPConfig'
require 'ctc/CheckerLocalConfig'
require 'ctc/EventManager'

module CTC


class CheckerInterfaceConfig
   
   include CTC
   include FTPClientCommands
    
   #--------------------------------------------------------------

   # Class constructor.
   #
   # IN (string) - Mnemonic of the Interface.
   #
   # IN (bool) [optional] - check parameters required for receiving
   #
   # IN (bool) [optional] - check parameters required for sending
   def initialize(entity, bCheckDCC=true, bCheckDDC=true)
      @bCheckDCC        = bCheckDCC
      @bCheckDDC        = bCheckDDC
      @isDebugMode      = false
      @entity           = entity
      checkModuleIntegrity
      @ftReadConf       = ReadInterfaceConfig.instance
      @ftReadConf.update
      @ftpRecv          = @ftReadConf.getFTPServer(@entity)
      @ftpSend          = @ftReadConf.getFTPServer(@entity)
      @check4Send       = CheckerFTPConfig.new(@ftpSend, @entity)
      @check4Recv       = CheckerFTPConfig.new(@ftpRecv, @entity)
      @checkLocal4Send  = CheckerLocalConfig.new(@ftpSend, @entity)  
      @checkLocal4Recv  = CheckerLocalConfig.new(@ftpRecv, @entity)    
      @protocol         = @ftReadConf.getProtocol(@entity)
   end
   #-------------------------------------------------------------
   
   # ==== Main method of the class
   # ==== It returns a boolean True whether checks are OK. False otherwise.
   def check
      retVal = true
      if @isDebugMode == true then
         @check4Send.setDebugMode
         @check4Recv.setDebugMode
         @checkLocal4Send.setDebugMode
         @checkLocal4Recv.setDebugMode
      end
     
      if @bCheckDDC == true then
         if @protocol == "LOCAL" then
            retVal = @checkLocal4Send.checkLocal4Send
         else
            retVal = @check4Send.check4Send
         end
      end     

      if @bCheckDCC == true then
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
   #-------------------------------------------------------------

   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "CheckerInterfaceConfig debug mode is on"
   end
   #-------------------------------------------------------------

private

   @isDebugMode       = false      
   @ftpConfig         = nil
   @sftpClient        = nil
   @ftReadConf        = nil

   #-------------------------------------------------------------

   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      
      if !ENV['DCC_TMP'] then
         puts "\nDCC_TMP environment variable not defined !\n"
         bDefined = false
      end
      
      if bDefined == false then
         puts "\nError in CheckerInterfaceConfig::checkModuleIntegrity :-(\n\n"
         exit(99)
      end
                  
      tmpDir = ENV['DCC_TMP']  
      time   = Time.new
      time.utc
      @batchFile = %Q{#{tmpDir}/.#{time.to_f.to_s}}
   end
   #-------------------------------------------------------------

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
   #-------------------------------------------------------------
   
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
   #-------------------------------------------------------------
   
   # Check that all Flags have proper values, this is true or false
   def checkEntityFlags
      bRet = true
      
      valFlag = @ftReadConf.registerDirContent?(@entity)
      
      if valFlag != true and valFlag != false then
         puts "\nConfiguration Error in #{@entity} I/F for Server.RegisterDirContent !"
         puts "Accepted values for this field are true|false"
         bRet = false
      end

      valFlag = @ftReadConf.retrieveDirContent?(@entity)
      
      if valFlag != true and valFlag != false then
         puts "\nConfiguration Error in #{@entity} I/F for Server.RetrieveDirContent !"
         puts "Accepted values for this field are true|false"
         bRet = false
      end
      return bRet
   end
   #-------------------------------------------------------------
   
   # Check the integrity of different TXRX Params.
   # It returns true if the check is successful 
   # otherwise it returns false.
   def checkTXRXParams
      
      ret = true
      
      txrx = @ftReadConf.getTXRXParams(@entity)
      
      return ret
   end
   #-------------------------------------------------------------
      
   def checkNotifyParams
         
      notifyParams = @ftReadConf.getNotifyParams(@entity)
      retVal = true
      
      if (notifyParams[:sendNotification].to_s.downcase == "true") then
         if notifyParams[:arrNotifyTo].length < 1 then
            puts "Notify -> To  should have a list of email addresses"
            retVal = false
         end
      end
      return retVal
   end
   #-------------------------------------------------------------

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
   #-------------------------------------------------------------

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
            puts "Error #{@entity} #{cmd} triggered by #{event["name"]} not in PATH ! :-("
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
   #-------------------------------------------------------------

end # class

end # module

