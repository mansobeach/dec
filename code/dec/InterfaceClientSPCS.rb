#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #InterfaceClientSPCS class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: InterfaceClientSPCS.rb,v 1.12 2014/05/16 00:14:38 bolf Exp $
###
###
#########################################################################

module DEC

require 'dec/ReadConfigDEC'

class InterfaceClientSPCS

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   def initialize
      @entity        = "SPCS"
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
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
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
