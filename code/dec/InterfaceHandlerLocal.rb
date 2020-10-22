#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #InterfaceHandlerLocal class
#
# === Written by DEIMOS Space S.L. (algk)
#
# === Data Exchange Component -> Data Collector Component
# 
# Git: $Id: InterfaceHandlerLocal.rb,v 1.12 2014/05/16 00:14:38 algs Exp $
#
# Module Data Collector Component
# This class polls a given LOCAL Interface and gets all registered available files
#
#########################################################################

require 'cuc/Log4rLoggerFactory'
#require 'ctc/CheckerLocalConfig'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigOutgoing'
require 'dec/CheckerInterfaceConfig'

require 'fileutils'

module DEC

class InterfaceHandlerLocal

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   ## * entity (IN):  Entity textual name (i.e. FOS)
   def initialize(entity, bDCC=true, bDDC=true, manageDirs=false)
      @entity     = entity
      # initialize logger
      
      if !ENV['DEC_CONFIG'] then
         puts "\nDEC_CONFIG environment variable not defined !  :-(\n\n"
      end
 
      configDir = nil
         
      if ENV['DEC_CONFIG'] then
         configDir         = %Q{#{ENV['DEC_CONFIG']}}  
      end
            
      loggerFactory = CUC::Log4rLoggerFactory.new("InterfaceHandlerLocal", "#{configDir}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in InterfaceHandlerLocal::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{ENV['DEC_CONFIG']}/dec_log_config.xml\"" 
			puts
			exit(99)
      end

      self.checkConfigLocal(entity, bDCC, bDDC)

      #to manage whole dirs
      @manageDirs=manageDirs

     #load classes needed
      @entityConfig     = ReadInterfaceConfig.instance
      @outConfig        = ReadConfigOutgoing.instance      
      
#       if Interface.find_by_name(@entity) == nil then
# 	      @logger.error("[DEC_001] #{entity} is not a registered I/F !")
#          raise "\n#{@entity} is not a registered I/F ! :-(" + "\ntry registering it with addInterfaces2Database.rb tool !  ;-) \n\n"
#       end

   end   
   ## -----------------------------------------------------------
   ##
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "InterfaceHandlerLocal debug mode is on"
   end
   ## -----------------------------------------------------------

   def checkConfigLocal (entity, bDCC, bDDC)
#       #check if I/F is correcly configured      
#       localChecker     = CTC::CheckerLocalConfig.new(entity)     
#       if @isDebugMode then
#          localChecker.setDebugMode
#       end
# 
#       if bDCC then
#          retVal = localChecker.checkLocal4Receive
#       end     
# 
#       if bDDC then
#          retVal = localChecker.checkLocal4Send
#       end

       #check if I/F is correcly configured

       checker     = CheckerInterfaceConfig.new(entity, bDCC, bDDC)
       retVal      = checker.check
 
       if retVal == true then
          if @isDebugMode == true then
             @logger.debug("#{entity} I/F is configured correctly")
 	      end
       else	
          @logger.error("[DEC_000] #{entity} I/F is not configured correctly")
          raise "Error in InterfaceHandlerLocal::initialize -> #{entity} I/F is not configured correctly :-("
       end

   end

   ## -----------------------------------------------------------
   ##
   ##
   
   def getUploadDirList(bTemp = false)
      dir      = nil
      if bTemp == false then
         dir = @outConfig.getUploadDir(@entity)
      else
         dir = @outConfig.getUploadTemp(@entity)
      end
      
      prevDir = Dir.pwd
      
      begin
         Dir.chdir(dir)
      rescue Exception => e
         @logger.error("[DEC_712] I/F #{@entity}: Directory #{dir} is unreachable. Try with decCheckConfig -e")
         return Array.new
      end
      
      entries  = Dir["*"].sort_by{|time| File.stat(time).mtime}
      
      Dir.chdir(prevDir)
      return entries
   end

   ## -----------------------------------------------------------
   ## DCC - Pull

   def getLocalList
      @newArrFile    = Array.new      
      @depthLevel    = 0
      @ftpserver     = @entityConfig.getFTPServer4Receive(@entity)

      arrDownloadDirs = @ftpserver[:arrDownloadDirs]

      arrDownloadDirs.each{|downDir|
         
         @remotePath = downDir[:directory]
         @maxDepth   = downDir[:depthSearch]

         if @isDebugMode then
            @logger.debug("Polling #{@remotePath}")
         end
         
         formerDir= Dir.pwd #shuold not be necessary; safety reasons
         begin
            Dir.chdir(@remotePath)
         rescue Exception => e
            @logger.error("[DEC_002] Directory #{@remotePath} is unreachable. Check with CheckconfigDCC.rb -e")
         end

         entries  = Dir["*"].sort_by{|time| File.stat(time).mtime}
         @pwd     = @remotePath
         
         entries.each{|entry|
            exploreLocalTree(entry)
         }
         
         Dir.chdir(formerDir)
      }
      return @newArrFile
   end
   ## -----------------------------------------------------------

   def exploreLocalTree(relativeFile)

      if @isDebugMode == true then
         @logger.debug("InterfaceHandlerLocal::exploreLocalTree #{relativeFile}")
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
                     @logger.debug("InterfaceHandlerLocal::exploreLocalTree change dir to #{relativeFile}")
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
   
   ## Download a file from the I/F
   def downloadFile(filename)      
       #we are placed on the right directory (tmp dir): receiveAllFiles->downloadFile->self
      if File.directory?(filename) then
         return downloadDir(filename)
      else  
         begin
            FileUtils.link(filename,File.basename(filename))
         rescue
            if @isdebugMode then @logger.debug("Could not make a Hardlink of #{filename} to #{Dir.pwd}. Copying the file") end
            begin
               FileUtils.copy(filename,'.'+File.basename(filename))
               FileUtils.move('.'+File.basename(filename), File.basename(filename))
            rescue
               @logger.error("[DEC_003] Error: Could not make a hardlink/copy of #{filename}")
               if @isdebugMode then puts"Error: Could not make a copy of #{filename}" end
               return false
            end
         end
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
         @logger.debug("InterfaceHandlerLocal::deleteFromEntity: I/F #{@entity}")
      end

      begin
         FileUtils.rm_rf(filename)    
      rescue
         if @isdebugMode == true then 
            @logger.debug("[DEC_XXX] I/F #{@entity}: InterfaceHandlerLocal::deleteFromEntity: Could not delete #{filename}")
         end
         return false
      end

      return true
	end
   ## -----------------------------------------------------------


# DDC =============================================================

  # Upload a file to the I/F  (DDC)
   def uploadFile(filename,targetFile,targetTemp)      
       #we are placed on the right directory (sourceDir): sendFile->self  (DDC) 
      begin
         FileUtils.link(filename,targetFile)
      rescue         
         if @isdebugMode then puts "Could not make a Hardlink of #{filename} to #{dir}. Copying the file" end
         begin
            FileUtils.copy(filename,targetTemp)
            FileUtils.move(targetTemp, targetFile)
         rescue
            @logger.error("[DEC_003] Error: Could not make a copy of #{filename}")
            if @isdebugMode then puts"Error: Could not make a copy of #{filename}" end
            return false
         end
      end
      return true
   end
	## -----------------------------------------------------------

   ## Upload a file to the I/F  (DDC)
   def uploadDir(dirname,targetDir,targetTemp)      
       #we are placed on the right directory (sourceDir): sendFile->self  (DDC) 
      if @manageDirs then
         begin
            FileUtils.cp_r(dirname,targetTemp)
            if File.exists?(targetDir) then FileUtils.rm_rf(targetDir) end
            FileUtils.move(targetTemp, targetDir)
         rescue
            @logger.error("[DEC_003] Error: Could not make a copy of #{dirname} dir")
            if @isdebugMode then puts"Error: Could not make a copy of #{dirname} dir" end
            return false
         end
      else
         return false
      end
      #everything ok
      return true
   end
	## -------------------------------------------------------------

end # class

end # module
