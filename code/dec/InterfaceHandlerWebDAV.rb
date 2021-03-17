#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #InterfaceHandlerWebDAV class
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === Data Exchange Component
## 
## Git: $Id: InterfaceHandlerWebDAV.rb,v 1.12 2014/05/16 00:14:38 bolf Exp $
##
## Module Interface
## This class pushes (pending pull) a given WebDAV Interface and 
## gets all registered available files
##
#########################################################################

### https://www.qed42.com/blog/using-curl-commands-webdav
### https://code.blogs.iiidefix.net/posts/webdav-with-curl/

require 'ctc/WrapperCURL'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigOutgoing'
require 'dec/ReadConfigIncoming'
require 'dec/InterfaceHandlerAbstract'

require 'uri'
require 'net/http'
require 'fileutils'

module DEC

class InterfaceHandlerWebDAV < InterfaceHandlerAbstract

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
      @verifyPeerSSL    = @entityConfig.isVerifyPeerSSL?(mnemonic)
      @uploadDir        = @outConfig.getUploadDir(@entity)
      @uploadTemp       = @outConfig.getUploadTemp(@entity)
      @arrPullDirs      = @inConfig.getDownloadDirs(@entity)
   end   
   ## -----------------------------------------------------------
   ##
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("InterfaceHandlerWebDAV debug mode is on") 
   end
   ## -----------------------------------------------------------

   def getPullList
      newArrFile = Array.new      
      @arrPullDirs.each{|element|
         dir = element[:directory]
         newArrFile << getDirList(dir)
      }
      return newArrFile.flatten      
   end
   ## -----------------------------------------------------------

   ## WebDAV Handler makes usage of a put + move to firstly push files
   ## into UploadTemp and then move into UploadDir when they are entirely uploaded

   def pushFile(file)
                  
      ## -------------------------------
      
      ## put file into the UploadTemp directory
      
      url = ""
      
      if @uploadTemp[0,1] == '/' then
         url = "#{@server[:hostname]}:#{@server[:port]}#{@uploadTemp}"
      else
         url = "#{@server[:hostname]}:#{@server[:port]}/#{@uploadTemp}"
      end
      
      if @server[:isSecure] == false then
         url = "http://#{url}"
      else
         url = "https://#{url}/"
      end
      
      if @isDebugMode == true then
         @logger.debug("InterfaceHandlerWebDAV::pushFile => #{file} / #{url} by #{@server[:user]}")
      end
   
      ret = putFile(url, @verifyPeerSSL, @server[:user], @server[:password], file, @isDebugMode, @logger)
   
      if ret == false then
         return false
      else
         if @isDebugMode == true then
            @logger.debug("InterfaceHandlerWebDAV::pushFile successful HTTP PUT into #{url}")
         end
      end
   
      ## -------------------------------
      ##
      ## move the file from UploadTemp directory into UploadDir

      currentUrl = url
      
      if @uploadDir[0,1] == '/' then
         url = "#{@server[:hostname]}:#{@server[:port]}#{@uploadDir}"
      else
         url = "#{@server[:hostname]}:#{@server[:port]}/#{@uploadDir}"
      end
      
      if @server[:isSecure] == false then
         url = "http://#{url}"
      else
         url = "https://#{url}/"
      end
      
      if @isDebugMode == true then
         @logger.debug("InterfaceHandlerWebDAV::pushFile => #{file} / #{url} by @server[:user]")
      end
      
      ret = moveFile(currentUrl, url, file, file, @verifyPeerSSL, @server[:user], @server[:password], @logger, @isDebugMode)
      
      if ret == false then
         return false
      else
         if @isDebugMode == true then
            @logger.debug("InterfaceHandlerWebDAV::pushFile successful HTTP MOVE from #{currentUrl} into #{url}")
         end
      end      
      
      ## -------------------------------
   
      return ret
   
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
         @logger.debug("InterfaceHandlerWebDAV::getUploadDirList tmp => #{bTemp}")
      end
      
      dir      = nil
      
      if bTemp == false then
         dir = @outConfig.getUploadDir(@entity)
      else
         dir = @outConfig.getUploadTemp(@entity)
      end
      
      if @isDebugMode == true then
         @logger.debug("InterfaceHandlerWebDAV::getUploadDirList tmp => #{bTemp} / #{dir}")
      end
   
      return self.getDirList(dir)
   
   end
   ## -----------------------------------------------------------
   
   ## -----------------------------------------------------------
   
   def getDirList(remotePath)
      if @isDebugMode == true then 
         @logger.debug("InterfaceHandlerWebDAV::getDirList(#{remotePath}): I/F #{@entity}")
      end

      newArrFile  = Array.new
      host        = ""
      
      if @isSecure == false then
         host        = "http://#{@server[:hostname]}:#{@server[:port]}/"
      else
         host        = "https://#{@server[:hostname]}:#{@server[:port]}/"
      end
      
      port        = @server[:port].to_i
      user        = @server[:user]
      pass        = @server[:password]
      dav         = Net::DAV.new(host, :curl => false)
      
      ## -------------------------------
      ## new configuration item VerifyPeerSSL is needed
      ##

      dav.verify_server = @entityConfig.isVerifyPeerSSL?(@entity)

      ## -------------------------------
 
      ## -------------------------------
      
      ## if credentials are not empty in the configuration file
      if user != "" or (pass != "" and pass != nil) then
         if @isDebugMode == true then
            @logger.debug("Passing Credentials to WebDAV server")
         end
         
         dav.credentials(user, pass)
      end
      ## -------------------------------
      
      @depthLevel = 0
         
      if @isDebugMode == true then
         @logger.debug("Checking directory with PROPFIND => #{remotePath}")
      end
         
      begin
         bFound = false
         
         dav.find(remotePath,:recursive => false,:suppress_errors=>true) do | item |
               
            bFound = true
               
            if @isDebugMode == true then
               @logger.debug("Found #{item.url.to_s} / #{item.type.to_s.downcase}")
            end 
                           
            if item.type.to_s.downcase == "file" then
               newArrFile << item.url.to_s
            end
         
            # dirty hack since exception is not raised but Warning: 401 "Unauthorized": /tmp
            
            if bFound == false then
               @logger.error("Could not reach #{remotePath} for #{@entity} / check credentials")
            end
            
         end # find
         
      rescue Exception => e
         @logger.error("Could not reach #{remotePath}")
         @logger.error(e.to_s)
         
         if @isDebugMode == true then
            @logger.debug(e.backtrace)
         end
         
      end
      return newArrFile
   end
	## -----------------------------------------------------------

	## -------------------------------------------------------------

private

end # class

end # module
