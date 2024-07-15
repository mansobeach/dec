#!/usr/bin/env ruby

require 'open3'

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
      if @isDebugMode == true and log != nil then
         log.debug("I/F #{interface}: EventManager::trigger #{eventName} - #{interface} - #{params}")
      end

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
         if @isDebugMode == true and log != nil then
            log.info("I/F #{interface}: EventManager::trigger => no events")
         end
         return
      end

      events = eventMgr[:arrEvents]

      events.each{|event|

         if @isDebugMode == true and log != nil then
            log.debug("EVENT #{event}")
         end

         if eventName.upcase == event["name"].upcase then
            cmd = event["cmd"]

            if @isDebugMode == true and log != nil then
               log.debug(cmd)
            end

            exec_command = cmd

            # --------------------------
            # Escape special XML characters.
            # At least '&' required for background execution
            exec_command = cmd.gsub("&amp;", "&")

            if @isDebugMode == true and log != nil then
               log.debug(exec_command)
            end

            bBackground = false

            if exec_command.include?("&") then
               bBackground = true
            end
            # --------------------------

            if params != nil then
               exec_command = exec_command.dup.sub("%F", pathfile)

               if @isDebugMode == true and log != nil then
                  log.debug(exec_command)
               end

               exec_command = exec_command.dup.sub("%f", filename)

               if @isDebugMode == true and log != nil then
                  log.debug(exec_command)
               end

               exec_command = exec_command.dup.sub("%d", directory)

               if @isDebugMode == true and log != nil then
                  log.debug(exec_command)
               end

            end
            # --------------------------

            if @isDebugMode == true and log != nil then
               log.debug("I/F #{interface}: Executing command #{exec_command}")
            end

            if log != nil then
               log.info("[DEC_130] I/F #{interface}: event triggered #{eventName.downcase} => #{exec_command}")
            end

            ## -----------------------------------
            if bBackground == true then
               spawn(exec_command)
               log.info("[DEC_130] I/F #{interface}: event spawned #{eventName.downcase} => #{exec_command}")
               next
            end
            ## -----------------------------------

            exit_status = nil

            begin
               Open3.popen3(exec_command) do |stdin, stdout, stderr, wait_thr|
                  while line = stdout.gets
                     puts line
                  end
                  exit_status = wait_thr.value
               end
            rescue Exception => e
               log.error("[DEC_750] I/F #{interface}: EventManager failed execution of #{exec_command} / #{e.to_s}")
               next
            end

#            output = `#{cmd}`
            # retVal = system(cmd)
            # if $?.exitstatus == 0 then

            if @isDebugMode == true and log != nil then
               log.debug("EventManager #{exit_status} / #{exit_status.exitstatus}")
            end

            if exit_status.exitstatus == 0 then
               if log != nil then
                  log.info("[DEC_130] I/F #{interface}: event completed #{eventName.downcase} => #{exec_command}")
#                  if output != "" then
#                     log.info("#{msg} => #{output.chop}")
#                  else
#                     log.info(msg)
#                  end
               end
            else
               if log != nil then
                  log.error("[DEC_750] I/F #{interface}: EventManager failed execution of #{exec_command} / exit code: #{exit_status.exitstatus}")
               end
            end
         else
            if log != nil then
               # log.debug("[DEC_+++] #{interface} I/F event triggered #{eventName.upcase}: IS NOT event #{event[:name]} / #{event}")
            end
         end
      }
   end
   ## -----------------------------------------------------------

   def exec_trigger(intray, eventName, cmd, params = nil, log = nil)
      if @isDebugMode == true and log != nil then
         log.debug("EventManager::exec_trigger => #{eventName} #{intray} #{cmd} #{params}")
      end

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
