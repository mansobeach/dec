#!/usr/bin/env ruby

##########################################################################
##
## === Ruby source for #EventManager class
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === Data Exchange Component -> Common Transfer Component
## 
## Git EventManager.rb,v $Id$ 1.4 2007/03/21 08:43:44 decdev Exp $
##
## === Module: Data Exchange Component // Class EventManager
##
## This class is in charge of processing different Events.
##
##########################################################################

require 'open3'

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
   
   ## Set debug mode on
   def setDebugMode
      @isDebugMode = true
   end
   ## -----------------------------------------------------------
   
   ##
   ## %f => filename
   ## %F => full path filename
   ## %d => directory
   def trigger(interface, eventName, params = nil, log = nil)

      filename    = nil
      directory   = nil
      pathfile    = nil

      if params != nil then
         filename    = params["filename"]
         directory   = params["directory"]
         if directory[-1,1] != "/" then
            pathfile    = "#{directory}/#{filename}"
         else
            pathfile    = "#{directory}#{filename}"
         end
      end

      eventMgr  = @ftReadConf.getEvents(interface)
      if eventMgr == nil then
         return
      end
            
      events = eventMgr[:arrEvents]
            
      events.each{|event|
         
         if eventName.upcase == event["name"].upcase then
            cmd = event["cmd"]

            # --------------------------
            # Escape special XML characters.
            # At least '&' required for background execution
            anewCmd = cmd.sub!("&amp;", "&")
            if anewCmd != nil then
               cmd = anewCmd
            end
            
            # --------------------------
            
            if params != nil then            
               anewCmd = cmd.sub!("%F", pathfile)
               if anewCmd != nil then
                  cmd = anewCmd
               end

               anewCmd = cmd.sub!("%f", filename)
               if anewCmd != nil then
                  cmd = anewCmd
               end

               anewCmd = cmd.sub!("%d", directory)
               if anewCmd != nil then
                  cmd = anewCmd
               end
            end
            # --------------------------
            
            if @isDebugMode == true and log != nil then
               log.debug("Event #{eventName} Triggered for #{interface}")
               log.debug("Executing command #{cmd}")
            end
            
            if log != nil then
               log.info("[DEC_130] I/F #{interface}: event triggered #{eventName.downcase} => #{cmd}")
            end
            
            exit_status = nil
            
            Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
               while line = stdout.gets
                  puts line
               end
               exit_status = wait_thr.value
            end           
            
#            output = `#{cmd}`
            # retVal = system(cmd)                        
            # if $?.exitstatus == 0 then
            
            if @isDebugMode == true and log != nil then
               log.debug("EventManager #{exit_status} / #{exit_status.exitstatus}")
            end
            
            if exit_status.exitstatus == 0 then
               if log != nil then
                  log.info("[DEC_130] I/F #{interface}: event completed #{eventName.downcase} => #{cmd}")
#                  if output != "" then
#                     log.info("#{msg} => #{output.chop}")
#                  else
#                     log.info(msg)
#                  end
               end
            else
               if log != nil then
                  log.error("[DEC_750] I/F #{interface}: EventManager failed execution of #{cmd} / #{$?.exitstatus}")
               end
            end
         else
#            log.error("[DEC_XXX] #{interface} I/F event: unsupported event #{event[:name]}")
         end
      }
   end
   ## -----------------------------------------------------------

   def exec_trigger(intray, eventName, cmd, params = nil, log = nil)

      # @isDebugMode = true

      filename    = nil
      directory   = nil
      pathfile    = nil

      if params != nil then
         filename    = params["filename"]
         directory   = params["directory"]
         if directory[-1,1] != "/" then
            pathfile    = "#{directory}/#{filename}"
         else
            pathfile    = "#{directory}#{filename}"
         end
      end

      # --------------------------
            
      # Escape special XML characters.
      # At least '&' required for background execution
            
      anewCmd = cmd.sub!("&amp;", "&")
            
      if anewCmd != nil then
         cmd = anewCmd
      end
            
      # --------------------------
            
      if params != nil then            
      
         anewCmd = cmd.sub!("%F", pathfile)   
         if anewCmd != nil then
            cmd = anewCmd
         end

         anewCmd = cmd.sub!("%f", filename)
         if anewCmd != nil then
            cmd = anewCmd
         end

         anewCmd = cmd.sub!("%d", directory)
         if anewCmd != nil then
            cmd = anewCmd
         end
      end
            
      # --------------------------
            
      if @isDebugMode == true and log != nil then
         log.debug("Event #{eventName} Triggered for #{intray}")
         log.debug("Executing command #{cmd}")
      end
            
      output = `#{cmd}`
            
                        
      if $?.exitstatus == 0 then
      
         if log != nil then
                  
            msg = "[DEC_131] Intray #{intray}: event #{eventName.downcase} => #{cmd}"
                  
#            if output != "" then
#               log.info("#{msg} => #{output.chop}")
#            else
#               log.info(msg)
#            end
         end
      else
         if log != nil then
            log.error("[DEC_750] Intray #{intray}: EventManager failed execution of #{cmd}")
            log.debug("#{cmd} / #{$?.exitstatus} / #{output}")
         end
      end


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

