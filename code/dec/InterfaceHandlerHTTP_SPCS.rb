#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #InterfaceHandlerHTTP_SPCS class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: InterfaceHandlerHTTP_SPCS.rb,v  $
###
###
#########################################################################

module DEC

## curl -c cookies.txt -b cookies.txt https://www.space-track.org/ajaxauth/login -d 'identity=borja.lopez@deimos-space.com&password=perrillo.pwd.long'
## curl --cookie cookies.txt --limit-rate 100K 'https://www.space-track.org/basicspacedata/query/class/cdm_public/' | jq

## curl --cookie cookies.txt --limit-rate 100K 'https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/NORAD_CAT_ID/40013/predicates/EPOCH,TLE_LINE1,TLE_LINE2/format/json'

## https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/NORAD_CAT_ID/25544,36411,26871,27422/predicates/FILE,EPOCH,TLE_LINE1,TLE_LINE2/format/html
## https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/NORAD_CAT_ID/25544,36411,26871,27422/predicates/FILE/orderby/FILE%20desc/limit/1
## https://www.space-track.org/basicspacedata/query/class/tle/format/html/NORAD_CAT_ID/25544,36411,26871,27422/predicates/FILE,TLE_LINE1,TLE_LINE2/FILE/>3315483

## https://www.space-track.org/basicspacedata/query/class/satcat/NORAD_CAT_ID/39634/format/html/emptyresult/show
## https://www.space-track.org/basicspacedata/query/class/satcat/NORAD_CAT_ID/40697/format/html/emptyresult/show
## https://www.space-track.org/basicspacedata/query/class/satcat/NORAD_CAT_ID/42063/format/html/emptyresult/show
## https://www.space-track.org/basicspacedata/query/class/satcat/NORAD_CAT_ID/35681/format/html/emptyresult/show
## https://www.space-track.org/basicspacedata/query/class/satcat/NORAD_CAT_ID/40013/format/html/emptyresult/show

require 'open3'

require 'dec/ReadConfigDEC'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigIncoming'

class InterfaceHandlerHTTP_SPCS

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   def initialize(entity, log, pull=true, push=false, manageDirs=false, isDebug=false)
      @entity        = entity
      @logger        = log
      @manageDirs    = manageDirs
      @isDebugMode   = isDebug

      if isDebug == true then
         self.setDebugMode
      end

      @tmpDir        = ReadConfigDEC.instance.getTempDir
      @ifConfig      = ReadInterfaceConfig.instance
      @pullConfig    = ReadConfigIncoming.instance
      @protocol      = @ifConfig.getProtocol(@entity)
      @server        = @ifConfig.getServer(@entity)
      @host          = @server[:hostname]
      @user          = @server[:user]
      @pass          = @server[:password]
      @port          = @server[:port]
      @passive       = @server[:isPassive]
      @cookies       = "#{@tmpDir}/.cookies_#{@user}"
   end   
   ## -----------------------------------------------------------
   ##
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("#{self.class}::#{__method__.to_s}")
   end
   ## -----------------------------------------------------------

   ## ## curl -c cookies.txt -b cookies.txt https://www.space-track.org/ajaxauth/login -d 'identity=borja.lopez@deimos-space.com&password=perrillo.pwd.long'
   def login
      cmd = "curl -s -c #{@cookies} -b #{@cookies} https://www.space-track.org/ajaxauth/login -d 'identity=#{@user}&password=#{@pass}'"
      if @isDebugMode == true then
         @logger.debug("I/F #{@entity}: #{cmd}")
      end
      
      ret = `#{cmd}`

      if $?.exitstatus == 0 then
         ret = true
      else
         ret = false
      end
   
      #ret = system(cmd)
      if ret == false then
         @logger.error("[DEC_611] I/F #{@entity}: Failed login")
      else
         if @isDebugMode == true then
            @logger.debug("[DEC_XXX] I/F #{@entity}: Login OK")
         end
      end
   end

   ## -----------------------------------------------------------
   ## DEC - Pull

   def getPullList
      login

      arrResult   = Array.new
      arrDirs     = @pullConfig.getDownloadDirs(@entity)

      ## handle each entry as an URL
      arrDirs.each{|dir|
         url = dir[:directory]
         cmd = "curl -s --head --cookie #{@cookies} --limit-rate 100K '#{@host}#{url}'"
         if @isDebugMode == true then
            cmd = "curl --head --cookie #{@cookies} --limit-rate 100K '#{@host}#{url}'"
            @logger.debug("I/F #{@entity}: #{cmd}")
         end

         ret = `#{cmd}`

         if @isDebugMode == true then
            @logger.debug("I/F #{@entity}: #{ret}")
         end

         if $?.exitstatus == 0 then
            ret = true
         else
            ret = false
         end

         if ret == true then
            arrResult << url
         else
            @logger.error("I/F #{@entity}: #{url} not available")
         end
         
      }
      return arrResult
   end

   ## -----------------------------------------------------------
   ## We are placed on the right directory (tmp dir): 
   ##          receiveAllFiles->downloadFile->self
   
   ## The concept of file is faked and the name of the resouce is used to
   ## get the URL to hit
   def downloadFile(resource)
      arrDirs     = @pullConfig.getDownloadDirs(@entity)

      arrDirs.each{|dir|
         url = dir[:directory]

         if url.include?(resource) == false then
            next
         end

         cmd = "curl --progress-bar --cookie #{@cookies} --limit-rate 100K '#{@host}#{url}' | jq > #{File.basename(resource)}.json"
         
         if @isDebugMode == true then
            @logger.debug("I/F #{@entity}: #{cmd}")
         end
         
         exit_status = nil
         
         begin
            
            Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
               while line = stdout.gets
                  puts line
               end
               exit_status = wait_thr.value

               if exit_status == 0 then
                  return true
               end

            end

         rescue Exception => e
            log.error("[DEC_TBD] I/F #{@entity}: failed execution of #{cmd} / #{e.to_s}")
         end     

      }

      return false

   end	
	## -----------------------------------------------------------

   ## -----------------------------------------------------------
   ## to inspect object

   def to_s
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------

   def checkConfig(entity, pull, push)
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------

   def pushFile(sourceFile, targetFile, targetTemp)
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------
   
   def getUploadDirList(bTemp = false)
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------

   def checkRemoteDirectory(directory)
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------

   def getDirList(directory)
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------
   
   ## Download a file from the I/F
   def downloadDir(directory)      
      raise NotImplementedError.new("#{__method__.to_s} needs to be implemented")
	end
   ## -----------------------------------------------------------

   ## Download a file from the I/F
   def deleteFromEntity(filename)      
      raise NotImplementedError.new("#{__method__.to_s} needs to be implemented")
	end

   ## -------------------------------------------------------------

end # class

end # module
