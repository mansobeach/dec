#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #RetrieverFromArchive class
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === Data Exchange Component -> Data Distributor Component
## 
## Git: $Id: RetrieverFromArchive.rb,v 1.13 2008/07/03 11:38:26 decdev Exp $
##
## Module Data Distributor Component
## This class retrieves files to be transferred is pointed by 
## SourceDir configuration item and files are placed into 
## dec_config.xml GlobalOutbox directory
##
#########################################################################

require 'fileutils'

require 'cuc/DirUtils'
require 'cuc/FT_PackageUtils'
require 'cuc/PackageUtils'
require 'cuc/Log4rLoggerFactory'

require 'dec/ReadConfigDEC'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigOutgoing'

module DEC

class RetrieverFromArchive

   include CUC::DirUtils
   include FileUtils::NoWrite
   
   ## -----------------------------------------------------------
   ##
   ## catch SIGTERM signal and remove the temporary dir used
   trap 15,proc{  cmd = "\\rm -rf #{@targetDirectory}"
                     system(cmd) }
  
   
   ## -----------------------------------------------------------
      
   ## Class constructor.
   def initialize
      decConfig            = DEC::ReadConfigDEC.instance
      @confDest            = ReadConfigOutgoing.instance
      @arrFileTypes        = @confDest.getAllOutgoingTypes
      @arrFileNames        = @confDest.getAllOutgoingFileNames
      @arrFilters          = decConfig.getOutgoingFilters      
      @bDeleteSourceFiles  = decConfig.deleteSourceFiles?
      @sourceDirectory     = decConfig.getSourceDir
      @globalOutbox        = decConfig.getGlobalOutbox
      @isDebugMode         = false
      @uploadDirs          = decConfig.getUploadDirs
      
      checkModuleIntegrity
      
      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("push", "#{@@configDirectory}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in DEC_ReceiverFromInterface::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{@@configDirectory}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end
      
   end   
   ## -----------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      if @logger != nil then
         @logger.debug("RetrieverFromArchive debug mode is on")
      end
      @isDebugMode = true
   end
   ## -----------------------------------------------------------
      
   def mv2OutTrays(bDeliverOnce = false)
      prevDir = Dir.pwd
      Dir.chdir(@targetDirectory)
      arrFiles = Dir["*"]
      
      arrFiles.each{|aFile|
         
         arrIF = @confDest.getEntitiesReceivingOutgoingFile(aFile)
         
         if arrIF.empty? == true or arrIF == nil then
            @logger.error("Error RetrieverFromArchive::mv2OutTrays #{aFile} not recognized in dec_outgoing_files.xml")
            next
         end
         
         arrIF.each{|interface|
            
            dir = @confDest.getOutgoingDir(interface[:mnemonic])
            
            arrMethods = interface[:deliveryMethods]

            arrMethods.each{|aMethod|

               destDir = "#{dir}/#{aMethod}"
               
               checkDirectory(destDir)

               if @isDebugMode == true then
                  @logger.debug("RetrieverFromArchive::mv2OutTrays => #{aFile} / #{interface[:mnemonic]} / #{destDir}")
               end

               ## ---------------------------------
               ## If delivery once has been selected, check whether the file
               ## has already been delivered
               
               if bDeliverOnce == true then
                  if SentFile.hasAlreadyBeenSent?(thefile, interface[:mnemonic], aMethod) == true then
                     @logger.warn("[DEC_XXX] Skipping #{aFile} already sent to #{interface[:mnemonic]} via #{aMethod}")
                     next
                  end
               end 
               ## ---------------------------------
            
               mvFile2OutTray(aFile, destDir, interface[:compressMethod], interface[:mnemonic])
            
            }
            
            if @isDebugMode == true then
               @logger.debug("mv2OutTrays removing #{aFile} from #{@targetDirectory}")
            end
         }
         FileUtils.rm_f(aFile)
      }
      Dir.chdir(prevDir)
      return
   end

   ## -------------------------------------------------------------

   ## ----------------------------------------------------------- 

   ## Public retrieve method that will call private method retrieveFilesOrNames two times:
   ## Once for the file-types files and another for the non-file types (wildcards)
   def retrieve(bJustList = false)

      @arrFileTypesOrNames = @arrFileTypes.clone

      gather(@sourceDirectory, bJustList)

      return
   end
   ## -----------------------------------------------------------
   
private

   ## -----------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity 
      bDefined = true
      bCheckOK = true
   
      if bCheckOK == false then
         puts "RetrieverFromArchive::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end

      configDir = nil
         
      if ENV['DEC_CONFIG'] then
         configDir         = %Q{#{ENV['DEC_CONFIG']}}
      else
         puts "Fatal ERROR ::DEC_ReceiverFromInterface::checkModuleIntegrity DEC_CONFIG not defined"
         exit(99)
      end        
            
      @@configDirectory = configDir

            
      @targetDirectory = @globalOutbox
      
      time             = Time.new
      tmpConfigFile    = time.to_i.to_s
      
      @targetDirectory = %Q{#{@targetDirectory}/_Delivery_/#{tmpConfigFile}}
    
      checkDirectory(@sourceDirectory)
      checkDirectory(@targetDirectory)
   end
   ## -----------------------------------------------------------
   
   ## ------------------------------------------------------------

   def gather(sourceDir, bJustList = false)
      
      prevDir = Dir.pwd
          
      @arrFileTypesOrNames.each{|filetype|

         if @isDebugMode == true then
            @logger.debug("#{Dir.pwd} ** #{sourceDir} ** #{filetype}")
         end

         if Dir.exist?(sourceDir) == true then
            Dir.chdir(sourceDir)
         end
                  
         if @isDebugMode == true then
            @logger.debug("RetrieveFromArchive::gather (list mode = #{bJustList}) => #{filetype} || #{Dir.pwd}")
         end

         # ---------------------------------------

         if filetype.include?("/") == true && Dir.exist?(filetype) == false && \
         !filetype.include?("*") && !filetype.include?("?") then
            @logger.error("Could not reach directory #{@sourceDirectory} => #{filetype}")
            next
         end
         # ---------------------------------------

         # Directory + Wildcard
         if  (filetype.include?("*") || filetype.include?("?") ) then
            list = Array.new
            if filetype.include?("/") then
               begin
                  Dir.chdir(File.dirname(filetype))
               rescue Exception => e
                  @logger.error("[DEC_711] Could not reach directory #{@sourceDirectory}/#{File.dirname(filetype)} by rule #{filetype} defined in dec_outgoing_files.xml")
                  next
               end
               list = Dir["*#{File.basename(filetype)}*"]
            else
               list = Dir["*#{filetype}*"]
            end
            list.each{|aFile|
               if bJustList == true then
                  @logger.info("[DEC_XXX] File #{aFile} available for push circulation")
                  next
               else
                  if @isDebugMode == true then
                     @logger.debug("File #{aFile} is selected for push circulation")
                  end
                  mv2GlobalOutBox(aFile)                    
                  next
               end
            }
         end

         # ---------------------------------------
         # Rule by fixed filename
         if File.exist?(filetype) == true then

            @arrFilters.each{|filter|
               if @isDebugMode == true then
                  @logger.debug("Filtering gathering files by #{filter} at #{Dir.pwd}")
               end     
            
               if File.fnmatch(filter, filetype.gsub(/.*\//, '')) == true then
                  if bJustList == true then
                     @logger.info("[DEC_XXX] File #{filetype} available for push circulation")
                     next
                  else
                     if @isDebugMode == true then
                        @logger.debug("File #{filetype} is selected for push circulation")
                     end
                     mv2GlobalOutBox(filetype)                    
                     next
                  end
               end
            }
            next
         end
         # ---------------------------------------

         # ---------------------------------------
         # Rule by directory (NOT TESTED)

         if Dir.exist?(filetype) == true then
            @logger.debug("RetrieveFromArchive::gather #{filetype} rule is a directory")
            gather(filetype, bJustList)
            next
         end
         # ---------------------------------------
      }
      Dir.chdir(prevDir)
   end
   ## ------------------------------------------------------------
   
   def mv2GlobalOutBox(filetype)
      cmd = "\\ln -f #{Dir.pwd}/#{filetype} #{@targetDirectory}/#{filetype} >& /dev/null"

      if @isDebugMode == true then               
         @logger.debug(cmd)
      end
                     
      retVal = system(cmd)
                     
      if retVal == true then
         @logger.info("[DEC_211] File #{filetype} at GlobalOutbox #{@targetDirectory}")
      else
         @logger.error("[DEC_XXX] File #{filetype} failed gathering hard-link towards GlobalOutbox #{@targetDirectory}")
      end
                     
      if @bDeleteSourceFiles == true and retVal == true then
         FileUtils.rm_f(filetype)
         @logger.info("[DEC_212] File #{filetype} is removed from SourceDir")
      end

   end
   ## ------------------------------------------------------------
   
   def mvFile2OutTray(filename, destination, compress, interface)
      
      if @isDebugMode == true then
         @logger.debug("mvFile2OutTray => #{filename} #{destination} #{compress}")
      end
      
      cmd = "\\ln -f #{Dir.pwd}/#{filename} #{destination}/#{filename} >& /dev/null"

      if @isDebugMode == true then               
         @logger.debug(cmd)
      end
        
      retVal = system(cmd)
                     
      if retVal == true then
         @logger.info("[DEC_213] I/F #{interface}: #{filename} is hard-linked at LocalOutbox #{destination}")
      else
         @logger.error("[DEC_713] I/F #{interface}: #{filename} hard-link failure towards LocalOutbox #{destination}")
         return false
      end

      if compress.upcase == "NONE" then
         return
      end

      package        = FT_PackageUtils.new(filename, destination, true)
      if @isDebugMode == true then
         package.setDebugMode
      end
      
      bMethod = package.setCompressMethod(compress)
   
      if bMethod == false then
         @logger.error("[DEC_999] Fatal Error : compress method #{compress} not supported / check dec_outgoing_files.xml")
         raise
      end

      bRet = package.pack
      arr  = Array.new
      arr << bRet
      
      if bRet == true then
         @logger.info("[DEC_214] I/F #{interface}: #{package.newfilename} compressed at LocalOutbox #{destination}")
      else
         @logger.error("[DEC_714] I/F #{interface}: Failed to compress #{package.newfilename}")
      end
            
      return bRet
   end
   ## ------------------------------------------------------------
      
end # class

end # module

