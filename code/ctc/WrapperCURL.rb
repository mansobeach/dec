#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FTPClientCommands module
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# === module Common Transfer Component module WrapperCURL
#
# This module contains methods for creating the curl
# command line parameters. 
#
#########################################################################

require 'shell'
require 'fileutils'

module CTC

module WrapperCURL
  
   ## -------------------------------------------------------------
   ##
   def getURL(url, isDebugMode = false)
      cmd = "curl -L -f -s -X GET #{url}"
      if isDebugMode == true then
         puts cmd
      end
      
      output = `#{cmd}`
      
      if $? != 0 then
         if isDebugMode == true then
            puts
            puts "Failed execution of #{cmd} ! :-("
            puts "Exit code #{$?}"
            puts output
            puts 
         end
         return false
      end
      return output
   end
   
   ## -------------------------------------------------------------
   
   ## Remove file with DELETE
   
   ## curl -X DELETE http://localhost:8080/tmp/test1.txt
   
   def deleteFile(url, file, isDebugMode = false)
      if url[-1, 1] != "/" then
         url = "#{url}/"  
      end

      cmd = "curl -X DELETE #{url}#{file}"
            
      if isDebugMode == true then
         cmd = "#{cmd} -v "
         puts cmd
      end
      return system(cmd)
   end
   
   ## -------------------------------------------------------------
   
   ## Upload with PUT <formless>

   ## curl --upload-file /tmp/1.plist http://localhost:4567/uploadFile/

   def putFile(url, file, isDebugMode = false, logger = nil)
      
      ## -----------------------------------------
      ## Behaviour with WebDAVNav Server to include slash
      ## for uploading files into a directory
      if url[-1, 1] != "/" then
         url = "#{url}/"  
      end
      ## -----------------------------------------

      
            
      cmd = "curl -s --upload-file #{file} --max-time 12000 --connect-timeout 10 --keepalive-time 12000 #{url}"
            
      if isDebugMode == true then
         cmd = "#{cmd} -v "
         output = `#{cmd}`
      else
         system(cmd)
      end
      
      if isDebugMode == true and $? != 0 then
         puts "Failed execution of #{cmd} ! :-("
         puts
         puts "curl exit code is #{$?}"
         puts
      end

      if logger != nil and isDebugMode == true then
         logger.debug("#{cmd} => exit code #{$?}")
         logger.debug(output)
      end

      if $? != 0 then
         return false
      else
         return true
      end

   end
   
   ## -------------------------------------------------------------
   
   ## Upload with PUT <formless>

   ## curl --upload-file /tmp/1.plist http://localhost:4567/uploadFile/
   
   def putFileSilent(url, file, isDebugMode = false)
   
      if url[-1, 1] != "/" then
         url = "#{url}/"  
      end
   
      cmd = "curl --upload-file #{file} --max-time 12000 --connect-timeout 10 --keepalive-time 12000 #{url}"
            
      if isDebugMode == true then
         cmd = "#{cmd} -v "
         puts cmd
      end

      return system(cmd)
   
   end
   ## -------------------------------------------------------------
   
   ## curl parameters tailored for sending big files

   def postFile(url, file, hFormParams, isDebugMode = false)
      ## --silent mode removed
      cmd = "curl --progress-bar -o upload.txt --max-time 12000 --connect-timeout 10 --keepalive-time 12000 -X POST "
      
      if isDebugMode == true then
         cmd = "#{cmd} -v "
      end
      
      hFormParams.each{|key,value|
         cmd = "#{cmd} -S -f -F '#{key}=#{value}'"
      }
      cmd = "#{cmd} -F file=@#{file} #{url}"
      
      if isDebugMode == true then
         puts cmd
      end
      
      output = `#{cmd}`
      
      if isDebugMode == true and $? != 0 then
         puts "Failed execution of #{cmd} ! :-("
         puts
         puts "curl exit code is #{$?}"
         puts
      end
      
      FileUtils.rm_f("upload.txt")
      
      if $? != 0 then
         return false
      else
         return true
      end

   end
   ## -------------------------------------------------------------

   ## Method requires curl 7.21.2 or later to make usage of 
   ##  --remote-header-name / -J 
   ## option -J

   def getFile(url, filename, isDebugMode = false)
      ## --progress-bar commented
      cmd = "curl -L --silent --max-time 12000 --connect-timeout 10 --keepalive-time 12000 -f -OJ -X GET "
      
      if isDebugMode == true then
         cmd = "#{cmd} -v "
      end

      # cmd = "#{cmd} #{url} > #{filename}"
      
      cmd = "#{cmd} #{url}"
      
      if isDebugMode == true then
         puts cmd
      end
      
      system(cmd)
      
      # output = `#{cmd}`
      
      if isDebugMode == true and $? != 0 then
         puts "Failed execution of #{cmd} ! :-("
         puts
         puts "curl exit code is #{$?}"
         puts
      end
      
      if $? != 0 then
         return false
      else
         return true
      end

   end
   ## -------------------------------------------------------------

   ## Implementation for curl for versions older than 7.21.2 

   def getDirtyFile_obsoleteCurl(url, filename, isDebugMode = false)
      if isDebugMode == true then
         puts "WrapperCURL::getDirtyFile_obsoleteCurl"
         puts
         puts self.backtrace
         puts
      end
   
      # curl -sI  $url | grep -o -E 'filename=.*$' | sed -e 's/filename=//'
      
      cmd = %Q{curl -sI "#{url}" | grep -o -E 'filename=.*$' | sed -e 's/filename=//'}
      
      # puts
      # puts cmd
      # puts
      
      filename = `#{cmd}`
      
#      puts
#      puts filename
#      puts
      
      ## --silent mode removed
      cmd = %Q{curl --progress-bar --max-time 900 --connect-timeout 10 --keepalive-time 12000 -o "#{filename.to_s.chop}" -L "#{url}" }
      
      if isDebugMode == true then
         puts
         puts cmd
         puts
      end

      system(cmd)
      
      if isDebugMode == true and $? != 0 then
         puts "Failed execution of #{cmd} ! :-("
         puts
         puts "curl exit code is #{$?}"
         puts
      end
      
      if $? != 0 then
         return false
      else
         return true
      end
      
   end
   ## -------------------------------------------------------------

end # module FTPClientCommands

end # module CTC
