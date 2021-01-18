#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #WrapperCURL module
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component -> Common Transfer Component
### 
### === module Common Transfer Component module WrapperCURL
###
### This module contains methods for creating the curl
### command line parameters. 
###
#########################################################################

require 'shell'
require 'fileutils'

module CTC

module WrapperCURL
   
   ## -------------------------------------------------------------
   ## 
   ## curl -u myuser:mypassword -X MOVE --header 'Destination: http://185.52.193.141:81/fromESRIN/test2' http://185.52.193.141:81/fromESRIN/.test2
   
   def moveFile(currentUrl, \
                  newUrl, \
                  currentName, \
                  newName, \
                  user, \
                  pass, \
                  logger = nil, \
                  isDebugMode = false)      

      if currentUrl[-1, 1] != "/" then
         currentUrl = "#{currentUrl}/"
      end
   
      if newUrl[-1, 1] != "/" then
         newUrl = "#{newUrl}/"
      end

      cmd = "curl -u #{user}:#{escapePassword(pass)} -X MOVE --header \'Destination: #{newUrl}#{newName}\' #{currentUrl}#{currentName}"
            
      if isDebugMode == true then
         cmd = "#{cmd} -v "
         if logger != nil then
            logger.debug(cmd)
         else
            puts cmd
         end
      end
      return system(cmd)
   end
  
   ## -------------------------------------------------------------
   ##  
  
   def propfind(url, user, pass, isDebugMode = false)
      if url[-1, 1] != "/" then
         url = "#{url}/"  
      end

      cmd = "curl -u #{user}:#{escapePassword(pass)} -X PROPFIND #{url}"
            
      if isDebugMode == true then
         cmd = "#{cmd} -v "
         puts cmd
      end
      return system(cmd)   
   end
  
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
   
   def deleteFile(url, user, pass, file, isDebugMode = false)
      if url[-1, 1] != "/" then
         url = "#{url}/"  
      end

      cmd = "curl -u #{user}:#{escapePassword(pass)} -X DELETE #{url}#{file}"
            
      if isDebugMode == true then
         cmd = "#{cmd} -v "
         puts cmd
      end
      return system(cmd)
   end
   
   ## -------------------------------------------------------------
   
   ## Upload with PUT <formless>

   ## curl --upload-file /tmp/1.plist http://localhost:4567/uploadFile/

   def putFile(url, user, pass, file, isDebugMode = false, logger = nil)
      if isDebugMode == true then
         puts "WrapperCURL::putFile"
      end
      
      ## -----------------------------------------
      ## Behaviour with WebDAVNav Server to include slash
      ## for uploading files into a directory
      if url[-1, 1] != "/" then
         url = "#{url}/"  
      end   
      ## -----------------------------------------
      
      cmd = ""
      if user != nil and user != "" then
         cmd = "curl -u #{user}:#{escapePassword(pass)} -s --upload-file #{file} --max-time 12000 --connect-timeout 10 --keepalive-time 12000 #{url}"
      else
         cmd = "curl -s --upload-file #{file} --max-time 12000 --connect-timeout 10 --keepalive-time 12000 #{url}"
      end      
            
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
   
   def putFileSilent(url, user, pass, file, isDebugMode = false)
      if isDebugMode == true then
         puts "WrapperCURL::putFileSilent #{url} #{file}"
      end

      if url[-1, 1] != "/" then
         url = "#{url}/"  
      end
   
      cmd = ""
      if user != nil and user != "" then
         cmd = "curl -u #{user}:#{escapePassword(pass)} -s --upload-file #{file} --max-time 12000 --connect-timeout 10 --keepalive-time 12000 #{url}"
      else
         cmd = "curl --upload-file #{file} --max-time 12000 --connect-timeout 10 --keepalive-time 12000 #{url}"
      end  
            
      if isDebugMode == true then
         cmd = "#{cmd} -v "
         puts cmd
      end
   
      retVal = system(cmd)
      
      if retVal == false and isDebugMode == true then
         raise
      end

      return retVal
   
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

   ## FTPS list files from a directory
   def ftpsListFiles(host, \
                     port, \
                     directory, \
                     user, \
                     password, \
                     verifyPeerSSL, \
                     logger, \
                     isDebugMode\
                     )
      cmd = "curl --ftp-ssl --list-only"

      if isDebugMode == true then
         cmd = "#{cmd} -v"
      else
         cmd = "#{cmd} -s"
      end
      
      if verifyPeerSSL == false then
         cmd = "#{cmd} -k --insecure"
      end
      
      cmd = "#{cmd} --user #{user}:#{password}"
      
      ## 990 Implicit Mode
      if port.to_i == 990 then
         cmd = "#{cmd} ftps://#{host}/#{directory}/"
      else
         cmd = "#{cmd} ftp://#{host}/#{directory}/"
      end
      
      if isDebugMode == true then
         if logger != nil then
            logger.debug(cmd)
         else
            puts cmd
         end
      end
      
      output = `#{cmd}`
      
      if $? != 0 then
         raise "Failed execution of #{cmd} / Exit code #{$?}"
      end
      
      arrFiles = output.split("\n")
      
      return arrFiles
   end
   ## -------------------------------------------------------------

   ## https://stackoverflow.com/questions/28721515/curl-command-line-tool-delete-file-from-ftp-server
   def ftpsDeleteFile(host, \
                      port, \
                      filename, \
                      user, \
                      password, \
                      verifyPeerSSL, \
                      logger, \
                      isDebugMode\
                     )
                     
      cmd = "curl --ftp-ssl"

      if isDebugMode == true then
         cmd = "#{cmd} -v"
      else
         cmd = "#{cmd} -s"
      end

      if verifyPeerSSL == false then
         cmd = "#{cmd} -k --insecure"
      end
      
      cmd = "#{cmd} --user #{user}:#{password}"
      
      ## 990 Implicit Mode
      if port.to_i == 990 then
         cmd = "#{cmd} ftps://#{host}/#{File.dirname(filename)}/"
      else
         cmd = "#{cmd} ftp://#{host}/#{File.dirname(filename)}/"
      end

      ## Delete Command
      cmd = "#{cmd} -Q \"DELE #{filename}\""
               
      
      if isDebugMode == true then
         if logger != nil then
            logger.debug(cmd)
         else
            puts cmd
         end
      end
      
      output = `#{cmd}`
      
      if $? != 0 then
         raise "Failed execution of #{cmd} / Exit code #{$?} / #{output}"
      end
      
      return true

                     
   end
   ## -------------------------------------------------------------

   ## https://stackoverflow.com/questions/28721515/curl-command-line-tool-delete-file-from-ftp-server
   
   ## https://stackoverflow.com/questions/49031463/removing-a-file-from-ftp-with-curl
   
   ## curl -v --ftp-ssl -s -k --insecure --user dec:dec -o file.txt ftps://localhost/tmp/dir1/file.txt -Q "-DELE file.txt"
   
   def ftpsGetFile(host, \
                   port, \
                   filename, \
                   bDelete, \
                   user, \
                   password, \
                   verifyPeerSSL, \
                   logger, \
                   isDebugMode\
                   )
   
      cmd = "curl --ftp-ssl"

      if isDebugMode == true then
         cmd = "#{cmd} -v"
      else
         cmd = "#{cmd} -s"
      end

      if verifyPeerSSL == false then
         cmd = "#{cmd} -k --insecure"
      end
      
      cmd = "#{cmd} --user #{user}:#{password}"
      
      ## 990 Implicit Mode
      if port.to_i == 990 then
         cmd = "#{cmd} -o #{File.basename(filename)} ftps://#{host}/#{filename}"
      else
         cmd = "#{cmd} -o #{File.basename(filename)} ftp://#{host}/#{filename}"
      end

      if bDelete == true then
         cmd = "#{cmd} -Q \"-DELE #{File.basename(filename)}\""
      end                 
      
      if isDebugMode == true then
         if logger != nil then
            logger.debug(cmd)
         else
            puts cmd
         end
      end
      
      output = `#{cmd}`
      
      if $? != 0 then
         raise "Failed execution of #{cmd} / Exit code #{$?}"
      end
      
      return true
      
   end
   ## -------------------------------------------------------------
   
   def ftpsPutFile(host, \
                   port, \
                   filename, \
                   targetDirectory, \
                   user, \
                   password, \
                   verifyPeerSSL, \
                   logger, \
                   isDebugMode\
                   )
   
      cmd = "curl --ftp-ssl"

      if isDebugMode == true then
         cmd = "#{cmd} -v"
      else
         cmd = "#{cmd} -s"
      end

      if verifyPeerSSL == false then
         cmd = "#{cmd} -k --insecure"
      end
      
      cmd = "#{cmd} --user #{user}:#{password}"
      
      ## 990 Implicit Mode
      if port.to_i == 990 then
         cmd = "#{cmd} -T #{File.basename(filename)} ftps://#{host}/#{targetDirectory}"
      else
         cmd = "#{cmd} -T #{File.basename(filename)} ftp://#{host}/#{targetDirectory}"
      end
                         
      if isDebugMode == true then
         if logger != nil then
            logger.debug(cmd)
         else
            puts cmd
         end
      end

      output = `#{cmd}`
      
      if $? != 0 then
         raise "Failed execution of #{cmd} / Exit code #{$?} / #{output}"
      end
      
      return true
   end
   ## -------------------------------------------------------------
   
   ## curl -T localfile ftp://ftp.example.com/dir/path/
   ##
   ## curl -T localfile ftp://ftp.example.com/dir/path/remote-file

   def ftpsPutFileRename(host, \
                   port, \
                   filename, \
                   targetDirectory, \
                   targetTemp, \
                   user, \
                   password, \
                   verifyPeerSSL, \
                   logger, \
                   isDebugMode\
                   )
   
      cmd = "curl --ftp-ssl"

      if isDebugMode == true then
         cmd = "#{cmd} -v"
      else
         cmd = "#{cmd} -s"
      end

      if verifyPeerSSL == false then
         cmd = "#{cmd} -k --insecure"
      end
      
      cmd = "#{cmd} --user #{user}:#{password}"
      
      ## 990 Implicit Mode
      if port.to_i == 990 then
         cmd = "#{cmd} -T #{File.basename(filename)} ftps://#{host}/#{targetTemp}"
      else
         cmd = "#{cmd} -T #{File.basename(filename)} ftp://#{host}/#{targetTemp}"
      end
                      
      ## RENAME upon upload
      cmd = "#{cmd} -Q \"-RENAME #{targetTemp} #{targetDirectory}\""
   
      if isDebugMode == true then
         if logger != nil then
            logger.debug(cmd)
         else
            puts cmd
         end
      end

      output = `#{cmd}`
      
      if $? != 0 then
         raise "Failed execution of #{cmd} / Exit code #{$?} / #{output}"
      end
      
      return true
                      
   end
   ## -------------------------------------------------------------

   def escapePassword(pass)
      pass    = pass.dup.gsub('"', '\"')
      pass    = pass.dup.gsub('!', '\!')
      pass    = pass.dup.gsub('@', '\@')
      pass    = pass.dup.gsub('$', '\$')
      return pass
   end
   ## -------------------------------------------------------------

end # module WrapperCURL

end # module CTC
