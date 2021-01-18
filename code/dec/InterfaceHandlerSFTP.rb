#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #InterfaceHandlerSFTP class
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === Data Exchange Component
## 
## Git: $Id: InterfaceHandlerSFTP.rb,v 1.12 2014/05/16 00:14:38 bolf Exp $
##
## Module Interface
## This class pushes (pending pull) a given SFTP Interface and gets all registered available files
##
#########################################################################

require 'ctc/FTPClientCommands'
require 'ctc/WrapperCURL'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigOutgoing'
require 'dec/ReadConfigIncoming'
require 'dec/InterfaceHandlerAbstract'

require 'uri'
require 'net/http'
require 'curb'
require 'nokogiri'
require 'fileutils'

module DEC


class InterfaceHandlerSFTP < InterfaceHandlerAbstract

   include CTC::FTPClientCommands
   include CTC::WrapperCURL

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   ## * entity (IN):  Entity textual name (i.e. FOS)
   def initialize(entity, log, pull=true, push=true, manageDirs=false, isDebug=false)
      @entity     =  entity
      @logger     =  log
      @manageDirs =  manageDirs
      
      if isDebug == true then
         self.setDebugMode
      end

      @entityConfig     = ReadInterfaceConfig.instance
      @outConfig        = ReadConfigOutgoing.instance
      @inConfig         = ReadConfigIncoming.instance
      @isSecure         = @entityConfig.isSecure?(@entity)
      @server           = @entityConfig.getServer(@entity)
      @uploadDir        = @outConfig.getUploadDir(@entity)
      @arrPullDirs      = @inConfig.getDownloadDirs(@entity)
   
      time        = Time.new   
      strTime     = time.to_i.to_s
      @batchFile  = %Q{#{ENV['DEC_TMP']}/.batchCheckSent2#{@entity}#{strTime}}
            
   end   
   ## -----------------------------------------------------------
   ##
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("InterfaceHandlerSFTP debug mode is on") 
   end
   ## -----------------------------------------------------------

   def pushFile(file)
   end
   ## -----------------------------------------------------------

   ## -----------------------------------------------------------

   def checkConfig(entity, pull, push)
      checker     = CheckerInterfaceConfig.new(entity, pull, push, @logger, @isDebugMode)
      
      if @isDebugMode == true then
         checker.setDebugMode
      end
      
      retVal      = checker.check
 
      if retVal == true then
         if @isDebugMode == true then
            @logger.debug("#{entity} I/F is configured correctly")
 	      end
      else
         raise "[DEC_000] I/F #{entity}: init / configuration problem"
      end
   end

   ## -----------------------------------------------------------

   ## -----------------------------------------------------------
   ## DEC - Pull


   ## -----------------------------------------------------------

   ## -----------------------------------------------------------
   ## -----------------------------------------------------------

   def getUploadDirList(bTemp = false)
      if @isDebugMode == true then
         @logger.debug("InterfaceHandlerSFTP::getUploadDirList tmp => #{bTemp}")
      end
      
      dir      = nil
      
      if bTemp == false then
         dir = @outConfig.getUploadDir(@entity)
      else
         dir = @outConfig.getUploadTemp(@entity)
      end
      
      if @isDebugMode == true then
         @logger.debug("InterfaceHandlerSFTP::getUploadDirList tmp => #{bTemp} / #{dir}")
      end
   
      return self.getDirList(dir)
   
   end
   ## -----------------------------------------------------------
   
   def getPullList(bShortCircuit = false)
      raise
   end
   ## -----------------------------------------------------------
   
   def getDirList(remotePath)
      return self.checkRemoteDirectory(remotePath)
   end
   ## -----------------------------------------------------------
   
   ## Need to make it pure SFTP
   
   def checkRemoteDirectory(remotePath)
      if @isDebugMode == true then
         @logger.debug("InterfaceHandlerSFTP::getDirList => #{remotePath}")
      end

      cmd = self.createSftpCommand(@server[:hostname],
                                  @server[:port],
                                  @server[:user],
                                  @batchFile,
                                  "cd #{remotePath}",
                                  nil,
                                  nil)
      cmd = self.createSftpCommand(@server[:hostname],
                                  @server[:port],
                                  @server[:user],
                                  @batchFile,
                                  "ls",
                                  "-1",
                                  nil)
                                  
      retVal = system(cmd)

      if FileTest.exist?(@batchFile) then
         File.delete(@batchFile)
      end     

   end
	## -----------------------------------------------------------

	## -------------------------------------------------------------
   
   ## -------------------------------------------------------------
   ##
   ## download file using SFTP protocol verb GET 
   ##
   def downloadFile
      raise
   end
      
   ## -------------------------------------------------------------


private

   ## -------------------------------------------------------------
   ##
   ## -------------------------------------------------------------

end # class

end # module
