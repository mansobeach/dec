#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #InterfaceHandlerFTPS class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Collector Component
# 
# Git: $Id: InterfaceHandlerAbstract.rb,v 1.12 2014/05/16 00:14:38 bolf Exp $
#
# Module Interface
# This is an abstract class that defines the interface handler methods
#
#########################################################################


module DEC

## http://morningcoffee.io/interfaces-in-ruby.html

class InterfaceHandlerAbstract

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   ## * entity (IN):  Entity textual name (i.e. FOS)
   def initialize(entity, log, bDCC=true, bDDC=true, manageDirs=false)
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end   
   ## -----------------------------------------------------------
   ##
   ## Set the flag for debugging on
   def setDebugMode
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------

   ## to inspect object

   def to_s
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")

   end
   ## -----------------------------------------------------------

   def checkConfig(entity, bDCC, bDDC)
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
   ## DEC - Pull

   def getList
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------

   ## -----------------------------------------------------------
   
   ## We are placed on the right directory (tmp dir): 
   ##          receiveAllFiles->downloadFile->self
   
   ## Download a file from the I/F
   def downloadFile(filename)
      raise NotImplementedError.new("#{__method__.to_s} needs to be implemented")
   end	
	## -----------------------------------------------------------

   ## Download a file from the I/F
   def downloadDir(filename)      
      raise NotImplementedError.new("#{__method__.to_s} needs to be implemented")
	end
   ## -----------------------------------------------------------

   ## -------------------------------------------------------------

end # class

end # module
