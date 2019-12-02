#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #EventManager class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# Git EventManager.rb,v $Id$ 1.4 2007/03/21 08:43:44 decdev Exp $
#
# === Module: Common Transfer Component // Class EventManager
#
# This class is in charge of processing different Events.
#
#########################################################################

require 'ctc/FTPClientCommands'
require 'ctc/SFTPBatchClient'
require 'ctc/CheckerFTPConfig'
require 'dec/ReadInterfaceConfig'

module DEC

Events = [
            "ONSENDOK",
            "ONSENDNEWFILESOK",
            "ONSENDERROR",
            "ONRECEIVEOK",
            "ONRECEIVENEWFILESOK",
            "ONRECEIVENEWFILE",
            "ONRECEIVEERROR",
            "ONTRACKOK",
            "NEWFILE2INTRAY" 
            ]

class EventManager
   
   include CTC
   include FTPClientCommands
    
   ## -----------------------------------------------------------

   ## Class constructor.
   ## IN (string) Mnemonic of the Entity.
   def initialize
      @isDebugMode = false
      checkModuleIntegrity
      @ftReadConf = ReadInterfaceConfig.instance
   end
   ## -----------------------------------------------------------
   
   def trigger(interface, eventName, params = nil, log = nil)

      eventMgr  = @ftReadConf.getEvents(interface)
      if eventMgr == nil then
         return
      end
      
      if @isDebugMode == true and log != nil then
         log.debug("EventManager::trigger #{eventName} - #{interface} - #{params}")
      end
      
      events = eventMgr[:arrEvents]
            
      events.each{|event|
         
         if eventName.upcase == event["name"].upcase then
            cmd = event["cmd"]
            # Escape special XML characters.
            # At least '&' required for background execution
            anewCmd = cmd.sub!("&amp;", "&")
            if anewCmd != nil then
               cmd = anewCmd
            end
            if log != nil then
               log.info(cmd)
            end
            retVal = system(cmd)
            if @isDebugMode == true then
               puts "Event #{eventName} Triggered for #{interface}"
               puts "Executing command #{cmd}" 
            end
            if retVal == false then
               puts "Error when executing #{cmd}"
            end
         else
#            puts "xxxxxxxx"
#            puts eventName
#            puts event["name"]
#            puts "xxxxxxxx"
         end
      }
   end
   ## -----------------------------------------------------------
   
   ## Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "EventManager debug mode is on"
   end
   ## -----------------------------------------------------------

private

   ## -----------------------------------------------------------

   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      return true
   end
   ## -----------------------------------------------------------

end # class

end # module

