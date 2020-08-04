#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #InterfaceHandlerHTTP class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component
# 
# Git: $Id: InterfaceHandlerHTTP.rb,v 1.12 2014/05/16 00:14:38 bolf Exp $
#
# Module Interface
# This class polls a given HTTP Interface and gets all registered available files
#
#########################################################################

require 'ctc/WrapperCURL'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigOutgoing'
require 'dec/ReadConfigIncoming'
require 'dec/CheckerInterfaceConfig'

require 'net/ftp'
require 'fileutils'

module DEC

## https://ruby-doc.org/stdlib-2.4.0/libdoc/net/ftp/rdoc/Net/FTP.html

class InterfaceHandlerHTTP

   include CTC::WrapperCURL

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   ## * entity (IN):  Entity textual name (i.e. FOS)
   def initialize(entity, log, bDCC=true, bDDC=true, manageDirs=false)
      @entity     =  entity
      @logger     =  log
      @manageDirs =  manageDirs
                   
      @entityConfig     = ReadInterfaceConfig.instance
      @outConfig        = ReadConfigOutgoing.instance
      @inConfig         = ReadConfigIncoming.instance
      @server           = @entityConfig.getServer(@entity)
      @uploadDir        = @outConfig.getUploadDir(@entity)
            
      @http             = nil
      @url              = nil
      
      self.checkConfig(entity, bDCC, bDDC)      
   end   
   ## -----------------------------------------------------------
   ##
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("InterfaceHandlerHTTP debug mode is on") 
   end
   ## -----------------------------------------------------------

   def pushFile(file)
      buildURLPush()
      if @isDebugMode == true then
         @logger.debug("InterfaceHandlerHTTP::pushFile => #{file} / #{@url}")
      end
      return putFile(@url, file, @isDebugMode, @logger)
   end
   ## -----------------------------------------------------------

   def buildURLPush   
      if @server[:user] != "" and @server[:user] != nil then
         @url = "#{@server[:user]}:#{@server[:password]}@#{@server[:hostname]}:#{@server[:port]}#{@@uploadDir}"
      else
         @url = "#{@server[:hostname]}:#{@server[:port]}#{@uploadDir}"
      end
      
      if @server[:isSecure] == false then
         @url = "http://#{@url}"
      else
         @url = "https://#{@url}/"
      end
      return @url
   end

   ## -----------------------------------------------------------

   def checkConfig(entity, bDCC, bDDC)
      checker     = CheckerInterfaceConfig.new(entity, bDCC, bDDC)
      
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

   def getList
      @depthLevel    = 0
      pwd            = nil
      login()
      
      arrFiles          = Array.new
      arrDownloadDirs   = @inConfig.getDownloadDirs(@entity)        
      

      arrDownloadDirs.each{|downDir|
         
         remotePath = downDir[:directory]
         maxDepth   = downDir[:depthSearch]

         if @isDebugMode then
            @logger.debug("Polling #{remotePath}")
         end
        
         begin
            @ftps.chdir(remotePath)
            pwd = @ftps.pwd
         rescue Exception => e
            @logger.error("[DEC_612] I/F #{@entity}: Cannot reach #{@remotePath} directory")
            @logger.error("[DEC_613] I/F #{@entity}: #{e.to_s}")
         end

         begin
            # items = ftps.list
            items = @ftps.nlst
            items.each{|file|
               arrFiles << "#{pwd}/#{file}"
            }
         rescue Exception => e
            @logger.error("[DEC_615] I/F #{@entity}: Failed to get list of files / FTPS passive mode is #{ftps.passive}")
            @logger.error("[DEC_613] I/F #{@entity}: #{e.to_s}")
         end

      }
      return arrFiles.flatten
   end
   ## -----------------------------------------------------------

   def exploreTree(relativeFile)

      if @isDebugMode == true then
         @logger.debug("InterfaceHandlerFTPS::exploreLocalTree #{relativeFile}")
      end

      # Treat normal files
      if File.file?(relativeFile) then
         if @isDebugMode == true then  @logger.debug("Found #{%Q{#{@pwd}/#{relativeFile}}}") end
         @newArrFile << %Q{#{@pwd}/#{relativeFile}}
      else #its a dir
         #be sure if it is
         if File.directory?(relativeFile) then
            # and the flag to download dirs is deactivated 

            if !@manageDirs then
               #and the depth is okey explore dir.
               if @depthLevel < @maxDepth then
                  if @isDebugMode == true then
                     @logger.debug("InterfaceHandlerFTPS::exploreLocalTree change dir to #{relativeFile}")
                  end 
                  #get into directory (stack recursion)
                  Dir.chdir(relativeFile)
                  @pwd = Dir.pwd     
                  @depthLevel = @depthLevel + 1 

                  # get etnries and call to recursion
                  entries = Dir["*"]
                  entries.each{|element|
                     exploreLocalTree(element)
                  }
     
                  # unstack recursion
                  Dir.chdir("..")
                  @pwd = Dir.pwd
                  @depthLevel = @depthLevel - 1
               end             
            else #download whole dir
               if @isDebugMode == true then @logger.debug("Found #{%Q{#{@pwd}/#{relativeFile}}}") end
               @newArrFile << %Q{#{@pwd}/#{relativeFile}}
            end

         end
      end

   end
   ## -----------------------------------------------------------
   
   ## We are placed on the right directory (tmp dir): 
   ##          receiveAllFiles->downloadFile->self
   
   ## Download a file from the I/F
   def downloadFile(filename)
   
      if @isDebugMode == true then
         @logger.debug("InterfaceHandlerFTPS::downloadFile(#{filename})")
      end
      
      login()
      
      @ftps.getbinaryfile(filename)
      @ftps.close
      
      if @isDebugMode == true then
         @logger.debug("InterfaceHandlerFTPS::downloadFile / Completed")
      end

      return true
   end	
	## -----------------------------------------------------------

   ## Download a file from the I/F
   def downloadDir(filename)      
       #we are placed on the right directory (tmp dir): receiveAllFiles->downloadFile->self
      if  @manageDirs then
         begin
            target=File.basename(filename)         
            FileUtils.cp_r(filename,'.'+target)
            if File.exists?(target) then FileUtils.rm_rf(target) end
            FileUtils.move('.'+target, target)
         rescue
            @logger.error("[DEC_003] Error: Could not make a copy of #{filename} dir")
            if @isdebugMode then puts"Error: Could not make a copy of #{filename} dir" end
            return false
        end
      else
         return false
      end
      #everything ik ok
      return true
   end	
	## -----------------------------------------------------------

	## This method is invoked after placing the files into the operational
	## directory. It deletes the file in the remote Entity if the Config
	## flag DeleteFlag is enable.
	def deleteFromEntity(filename)

      if @isDebugMode == true then 
         @logger.debug("InterfaceHandlerFTPS::deleteFromEntity: I/F #{@entity}")
      end

      begin
         FileUtils.rm_rf(filename)    
      rescue
         if @isdebugMode == true then 
            @logger.debug("[DEC_XXX] I/F #{@entity}: InterfaceHandlerFTPS::deleteFromEntity: Could not delete #{filename}")
         end
         return false
      end

      return true
	end
   ## -----------------------------------------------------------

	## -----------------------------------------------------------

	## -------------------------------------------------------------

private

   ## -------------------------------------------------------------
   ##
   ## -------------------------------------------------------------

end # class

end # module
