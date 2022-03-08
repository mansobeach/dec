#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #InterfaceClientSPCS class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: InterfaceClientSPCS.rb,v  $
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


require 'dec/ReadConfigDEC'

class InterfaceClientSPCS

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   def initialize(entity, log, pull=true, push=false, manageDirs=false, isDebug=false)
      @entity        = entity
      @logger        =  log
      @manageDirs    =  manageDirs
      
      if isDebug == true then
         self.setDebugMode
      end

      @ifConfig      = ReadInterfaceConfig.instance
      @protocol      = @ifConfig.getProtocol(@entity)
      @server        = @ifConfig.getServer(@entity)
      @user          = @server[:user]
      @pass          = @server[:password]
      @port          = @server[:port]
      @passive       = @server[:isPassive]
   end   
   ## -----------------------------------------------------------
   ##
   ## Set the flag for debugging on
   def setDebugMode
      @logger.debug("#{self.class}::#{__method__.to_s}")
   end
   ## -----------------------------------------------------------

   ## -----------------------------------------------------------
   ## DEC - Pull

   def getPullList
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end

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
   
   ## We are placed on the right directory (tmp dir): 
   ##          receiveAllFiles->downloadFile->self
   
   ## Download a file from the I/F
   def downloadFile(filename)
      raise NotImplementedError.new("#{__method__.to_s} needs to be implemented")
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
