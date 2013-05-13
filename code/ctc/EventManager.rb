#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #EventManager class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: EventManager.rb,v 1.4 2007/03/21 08:43:44 decdev Exp $
#
# === Module: Common Transfer Component // Class EventManager
#
# This class is in charge of processing different Events.
#
#########################################################################

require 'ctc/FTPClientCommands'
require 'ctc/SFTPBatchClient'
require 'ctc/ReadInterfaceConfig'
require 'ctc/CheckerFTPConfig'

module CTC

Events = ["ONSENDOK", "ONSENDNEWFILESOK", "ONSENDERROR", "ONRECEIVEOK", "ONRECEIVENEWFILESOK", "ONRECEIVEERROR", "ONTRACKOK" ]

class EventManager
   
   include CTC
   include FTPClientCommands
    
   #--------------------------------------------------------------

   # Class constructor.
   # IN (string) Mnemonic of the Entity.
   def initialize
      @isDebugMode = false
      checkModuleIntegrity
      @ftReadConf = ReadInterfaceConfig.instance
   end
   #-------------------------------------------------------------
   
   def trigger(interface, eventName)
      eventMgr  = @ftReadConf.getEvents(interface)
      if eventMgr == nil then
         return
      end
      events = eventMgr[:arrEvents]
      events.each{|event|
         if eventName == event["name"] then
            cmd = event["cmd"]
            # Escape special XML characters.
            # At least '&' required for background execution
            anewCmd = cmd.sub!("&amp;", "&")
            if anewCmd != nil then
               cmd = anewCmd
            end
            retVal = system(cmd)
            if @isDebugMode == true then
               puts "Event #{eventName} Triggered for #{interface}"
               puts "Executing command #{cmd}" 
            end
            if retVal == false then
               puts "Error when executing #{cmd}"
            end
         end
      }
   end
   #-------------------------------------------------------------
   
   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "EventManager debug mode is on"
   end
   #-------------------------------------------------------------

private

   #-------------------------------------------------------------

   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return true
   end
   #-------------------------------------------------------------

end # class

end # module

