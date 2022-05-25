#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #InterfaceHandlerFTPS class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component -> Data Collector Component
### 
### Git: $Id: InterfaceHandlerFTPS_implicit.rb,v 1.12 2014/05/16 00:14:38 bolf Exp $
###
### Module Interface
### This class polls a given FTPS Interface using curl
###
#########################################################################

require 'ctc/WrapperCURL'

require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigOutgoing'
require 'dec/ReadConfigIncoming'
require 'dec/CheckerInterfaceConfig'
require 'dec/InterfaceHandlerAbstract'

require 'net/ftp'
require 'fileutils'

## https://ruby-doc.org/stdlib-2.4.0/libdoc/net/ftp/rdoc/Net/FTP.html

module DEC


class InterfaceHandlerFTPS_Implicit < InterfaceHandlerAbstract

   include CTC::WrapperCURL

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   ## * entity (IN):  Entity textual name (i.e. FOS)
   def initialize(entity, log, bPull=true, bPush=true, manageDirs=false)
      @entity     =  entity
      @logger     =  log
      @bPull      =  bPull
      @bPush      =  bPush
      @manageDirs =  manageDirs
                      
      @entityConfig     = ReadInterfaceConfig.instance
      
      if @bPull == true then
         @inConfig         = ReadConfigIncoming.instance
         @ftpServer        = @entityConfig.getFTPServer4Receive(@entity)
         @bDelete          = @inConfig.deleteDownloaded?(@entity)
         @inDirectory      = @inConfig.getIncomingDir(@entity)
      end
      
      if @bPush  == true then
         @outConfig        = ReadConfigOutgoing.instance
         @ftpServer        = @entityConfig.getFTPServer4Send(@entity)
      end
      
      @tmpDir           = DEC::ReadConfigDEC.instance.getTempDir
      @ftps             = nil
             
   end   
   ## -----------------------------------------------------------
   ##
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("InterfaceHandlerFTPS_Implicit debug mode is on") 
   end
   ## -----------------------------------------------------------
   
   def inspect
      puts "#{self.class} #{@entity} pull => #{@bPull} | push => #{@bPush}"
   end
   ## -----------------------------------------------------------

   def checkConfig(entity, pull, push)
      checker     = CheckerInterfaceConfig.new(entity, pull, push, @logger)
      
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

   def pushFile(sourceFile, targetFinal, targetTemp)   
      host     = @ftpServer[:hostname]
      port     = @ftpServer[:port]
      user     = @ftpServer[:user]
      pass     = @ftpServer[:password]
      passive  = @ftpServer[:isPassive]
      chkSSL   = @ftpServer[:verifyPeerSSL]


      return ftpsPutFile(host, \
                  port, \
                  sourceFile, \
                  targetFinal, \
                  user, \
                  pass, \
                  chkSSL, \
                  @logger, \
                  @isDebugMode\
                  )

      ## Not tested yet
      return ftpsPutFileRename(host, \
                  port, \
                  sourceFile, \
                  targetTemp, \
                  targetFinal, \
                  user, \
                  pass, \
                  chkSSL, \
                  @logger, \
                  @isDebugMode\
                  )
   
   end
   ## -----------------------------------------------------------
   ##
   ##
   
   def getUploadDirList(bTemp = false)

      host     = @ftpServer[:hostname]
      port     = @ftpServer[:port]
      user     = @ftpServer[:user]
      pass     = @ftpServer[:password]
      passive  = @ftpServer[:isPassive]
      chkSSL   = @ftpServer[:verifyPeerSSL]
   
      dir      = nil
      
      if bTemp == false then
         dir = @outConfig.getUploadDir(@entity)
      else
         dir = @outConfig.getUploadTemp(@entity)
      end
      
      if @isDebugMode == true then
         @logger.debug("InterfaceHandlerFTPS_Implicit::getUploadDirList tmp => #{bTemp} / #{dir}")
      end

      arrFiles = Array.new

      begin   
         items = ftpsListFiles(host, port, dir, user, pass, chkSSL, @logger, @isDebugMode)
         
         items.each{|item|
            arrFiles << "#{dir}#{item}"
         } 
      rescue Exception => e
         @logger.error("[DEC_612] I/F #{@entity}: Cannot reach #{dir} directory")
         @logger.error("[DEC_613] I/F #{@entity}: #{e.to_s}")
      end

         
      return arrFiles.flatten
   end

   ## -----------------------------------------------------------
   ## DEC - Pull

   def getList

      host     = @ftpServer[:hostname]
      port     = @ftpServer[:port]
      user     = @ftpServer[:user]
      pass     = @ftpServer[:password]
      passive  = @ftpServer[:isPassive]
      chkSSL   = @ftpServer[:verifyPeerSSL]
      
      @depthLevel    = 0
      pwd            = nil
          
      arrFiles          = Array.new
      arrDownloadDirs   = @inConfig.getDownloadDirs(@entity)        
      

      arrDownloadDirs.each{|downDir|
         
         remotePath = downDir[:directory]
         maxDepth   = downDir[:depthSearch]

         if maxDepth != 0 then
            @logger.warning("[DEC_XXX] I/F #{@entity} : #{remotePath} directory DepthSearch cannot be <> 0 for FTPS Implicit")
         end

         if @isDebugMode then
            @logger.debug("Polling FTPS implicit #{remotePath}")
         end
                
         begin
            items = ftpsListFiles(host, port, remotePath, user, pass, chkSSL, @logger, @isDebugMode)
            items.each{|item|
               arrFiles << "#{remotePath}/#{item}"
            }
            
         rescue Exception => e
            @logger.error("[DEC_612] I/F #{@entity}: Cannot reach #{@remotePath} directory")
            @logger.error("[DEC_613] I/F #{@entity}: #{e.to_s}")
         end


      }
      return arrFiles.flatten
   end
   ## -----------------------------------------------------------
   ##

   def checkRemoteDirectory(directory)
      host     = @ftpServer[:hostname]
      port     = @ftpServer[:port]
      user     = @ftpServer[:user]
      pass     = @ftpServer[:password]
      passive  = @ftpServer[:isPassive]
      chkSSL   = @ftpServer[:verifyPeerSSL]

      begin
         items = ftpsListFiles(host, port, directory, user, pass, chkSSL, @logger, @isDebugMode)          
      rescue Exception => e
         @logger.error("[DEC_612] I/F #{@entity}: Cannot reach #{@remotePath} directory")
         @logger.error("[DEC_613] I/F #{@entity}: #{e.to_s}")
         return false
      end
   end
   ## -----------------------------------------------------------
   
   ## We are placed on the right local directory (tmp dir): 
   ##          receiveAllFiles->downloadFile->self
   
   ## Download a file from the I/F
   def downloadFile(filename)
      host     = @ftpServer[:hostname]
      port     = @ftpServer[:port]
      user     = @ftpServer[:user]
      pass     = @ftpServer[:password]
      passive  = @ftpServer[:isPassive]
      chkSSL   = @ftpServer[:verifyPeerSSL]
      
      ## DO NOT MOVE INTO FINAL DIR
      ##Dir.chdir(@inDirectory)
      Dir.chdir(@tmpDir)
      
      ## bDelete is actually forced to false to perform deletion in a second step if it applies
      ret = true
      begin
         ret = ftpsGetFile(host, port, filename, false, user, pass, chkSSL, @logger, @isDebugMode)
      rescue Exception => e
         @logger.error("[DEC_628] I/F #{@entity}: #{e.to_s}")
         if File.exist?("#{Dir.pwd}/#{File.basename(filename)}") == true then
            begin
               size = File.size("#{Dir.pwd}/#{File.basename(filename)}")
               # File.delete("#{Dir.pwd}/#{File.basename(filename)}")
               @logger.warn("[DEC_XXX] I/F #{@entity}: #{File.basename(filename)} incomplete? file with size #{size} bytes")
               # @logger.warn("[DEC_XXX] I/F #{@entity}: #{File.basename(filename)} deleted incomplete file with size #{size} bytes")
            rescue Exception => e
               @logger.error("[DEC_628] I/F #{@entity}: #{e.to_s}")
            end
         end
         return false
      end
      
      if ret == true then
         cmd = "\\mv -f #{Dir.pwd}/#{File.basename(filename)} #{@inDirectory}"
         if @isDebugMode == true then
            @logger.debug(cmd)
         end
         ret = system(cmd)
         if ret == false then
            @logger.error("[DEC_628] I/F #{@entity}: Failed to move #{File.basename(filename)} into #{@inDirectory}")
         end
      end
      
      return ret
   end	
	## -----------------------------------------------------------

	## -----------------------------------------------------------

	## This method is invoked after placing the files into the operational
	## directory. It deletes the file in the remote Entity if the Config
	## flag DeleteFlag is enable.
	def deleteFromEntity(filename)
      host     = @ftpServer[:hostname]
      port     = @ftpServer[:port]
      user     = @ftpServer[:user]
      pass     = @ftpServer[:password]
      passive  = @ftpServer[:isPassive]
      chkSSL   = @ftpServer[:verifyPeerSSL]
      
      return ftpsDeleteFile(host, port, filename, user, pass, chkSSL, @logger, @isDebugMode)
	end
   ## -----------------------------------------------------------



	## -------------------------------------------------------------

private


end # class

end # module
