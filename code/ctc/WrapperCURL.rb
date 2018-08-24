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
# command line statements. 
#
#########################################################################

require 'shell'

module CTC

module WrapperCURL
  
   # -------------------------------------------------------------
   #
   def getURL(url, isDebugMode = false)
      cmd = "curl -f -s -X GET #{url}"
      if isDebugMode == true then
         puts cmd
      end
      output = `#{cmd}`
      
      if $? !=0 then
         if isDebugMode == true then
            puts "Failed execution of #{cmd} ! :-("
         end
         return false
      end
      return output
   end
   # -------------------------------------------------------------

   def postFile(url, file, hFormParams, isDebugMode = false)
      cmd = "curl -s -X POST "
      
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
      
      if $? != 0 then
         return false
      else
         return true
      end

   end
   # -------------------------------------------------------------

   # Method requires curl 7.21.2 or later to make usage of 
   #  --remote-header-name / -J 
   # option -J

   def getFile(url, filename, isDebugMode = false)
      cmd = "curl -s -f -OJ -X GET "
      
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
   # -------------------------------------------------------------

   # Implementation for curl for versions older than 7.21.2 

   def getDirtyFile_obsoleteCurl(url, filename, isDebugMode = false)
      # curl -sI  $url | grep -o -E 'filename=.*$' | sed -e 's/filename=//'
      
      cmd = %Q{curl -sI "#{url}" | grep -o -E 'filename=.*$' | sed -e 's/filename=//'}
      
      # puts
      # puts cmd
      # puts
      
      filename = `#{cmd}`
      
      cmd = %Q{curl -s -o "#{filename.to_s.chop}" -L "#{url}" }
      
      # puts
      # puts cmd
      # puts

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
   # -------------------------------------------------------------

end # module FTPClientCommands

end # module CTC
