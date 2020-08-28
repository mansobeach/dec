#!/usr/bin/env ruby

#########################################################################
#
# = Ruby source for #FileDeliverer2InTrays class
#
# = Written by DEIMOS Space S.L. (bolf)
#
# = Data Exchange Component
# 
# Git:
#   $Id: FileDeliverer2InTrays.rb,v 1.16 2008/07/03 11:38:07 decdev Exp $
#
#########################################################################

require 'fileutils'

require 'cuc/Log4rLoggerFactory'
require 'cuc/CommandLauncher'
require 'cuc/DirUtils'
require 'cuc/PackageUtils'
require 'cuc/EE_ReadFileName'
require 'dec/ReadConfigDEC'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigIncoming'
require 'dec/EventManager'

 # This class moves all files from the I/Fs local inboxes
 # to the configured In-Trays  

module DEC

class FileDeliverer2InTrays

   include CUC::DirUtils
   include CUC::CommandLauncher
   include CUC::PackageUtils
   
   ## -------------------------------------------------------------   
   
   ## Class contructor
   ##
   def initialize(debugMode = false)
      @@isModuleOK        = false
      @@isModuleChecked   = false
      @isDebugMode        = debugMode
      checkModuleIntegrity
	   @entConfig = ReadInterfaceConfig.instance
		@dimConfig = ReadConfigIncoming.instance
                  
      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("pull", "#{@@configDirectory}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in FileDeliverer2InTrays::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{@@configDirectory}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end

      # Not used by this class at the time being
      # @satPrefix = DEC::ReadConfigDEC.instance.getSatPrefix
   end
   ## -----------------------------------------------------------
   
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      @logger.debug("FileDeliverer2InTrays debug mode is on")
	   @entConfig.setDebugMode
		@dimConfig.setDebugMode
   end
   ## -----------------------------------------------------------
   
   ## Main method of the class which delivers the incoming files
   ## from the local Entities In-Boxes to the DIMs In-Trays
   def deliver(mnemonic = "")
#	   setDebugMode
          
      if mnemonic != "" and @isDebugMode == true then
         @logger.debug("Dissemination of files previously received from #{mnemonic}")
      end
      
      arrEnts   = @entConfig.getAllExternalMnemonics     

		arrEnts.each{|entity|
			
         if mnemonic != "" and entity.to_s != mnemonic then
            next
         end

         dir = @dimConfig.getIncomingDir(entity)
         
         if @isDebugMode == true then    
            @logger.debug("#{entity} local inbox #{dir}")
         end
            	
			arrFiles = getFilenamesFromDir(dir, "*")
			if arrFiles.empty? == true then
			   if @isDebugMode == true then
				   @logger.debug("There are no previous files to disseminate")
				end
            next
			end

			arrFiles.each{|afile|
         	
            file = File.basename(afile)
            	   
            bIsEEFile   = CUC::EE_ReadFileName.new(file).isEarthExplorerFile?
            fileType    = CUC::EE_ReadFileName.new(file).fileType
            dimsDirs    = Array.new
            dimsName    = Array.new
            bByType     = true
            
            if bIsEEFile == true then
               bByType  = true
               dimsDirs = @dimConfig.getTargetDirs4Filetype(fileType)
               dimsName = @dimConfig.getDIMs4Filetype(fileType)
		      else
               bByType  = false
               dimsDirs = @dimConfig.getTargetDirs4Filename(file)
               dimsName = @dimConfig.getDIMs4Filename(file)
            end
            
            if dimsName != false then
               if @isDebugMode == true then
                  dimsName.each{|dim|
                     @logger.debug("#{file} is disseminated to #{dim}")
                  }
               end
            else
               # @logger.warn("#{file} has no InTray config")
               if @isDebugMode == true then 
                  @logger.debug("#{file} has no InTray config")
               end
            end            
            
            
            if dimsDirs.empty? == false then
            
				   hdlinked = ""
				
               if bByType == true then
                  hdlinked = @dimConfig.isHardLinked?(fileType)
	            else
                  hdlinked = @dimConfig.isHardLinked?(file)
               end
                         
               if @isDebugMode == true then
					   @logger.debug("CONTROL-1 #{file} is disseminated to: #{dimsName}")
					end

               # main dissemination method
               # - interface
               # - file
               # - from directory
               # - to array of directories 

               # ret = disseminate(entity, file, dir, dimsDirs, hdlinked)

					ret = disseminate(entity, file, dir, dimsName, hdlinked)
               
               ## ---------------------------------
               # 20170601 - Patch to compress locally disseminated files               
               if ret == true then
                  ret = compressFile(dimsName, file)
               end
               ## ---------------------------------
               
               ## ---------------------------------
               
               # The original file is only deleted if the dissemination has been
               # performed successfully, otherwise it is kept in order to not loose
               # the information and perform a later manual dissemination 
               if ret == true then
                  begin
                     if @isDebugMode == true then
                        @logger.debug("[DEC_951.2] I/F #{mnemonic}: Removing #{dir}/#{file}")
                        @logger.debug("#{file} has been disseminated locally according to rules")
                     end
                     FileUtils.rm_f("#{dir}/#{file}")
                  rescue Exception
                     @logger.error("Could not delete #{dir}/#{file}")
                     exit(99)
                  end
               else      
                  # @logger.error("#{file} has not been disseminated")
                  @logger.warn("[DEC_331] I/F #{entity}: #{file} is stuck in LocalInbox #{dir}")
               end
				end
			}
      }
      
   end
   ## -----------------------------------------------------------
   
   ## It Deliver Files present in a given directory
   def deliverFromDirectory(directory)
         arrFiles = getFilenamesFromDir(directory, "*")
			if arrFiles.empty? == true then
			   if @isDebugMode == true then
               logger.debug("deliverFromDirectory: there are no new files to disseminate")
				end
			end
			
         arrFiles.each{|file|
            deliverFile(nil, directory, file)
			}
   end
   ## -------------------------------------------------------------
   
   ## It delivers a given file
   def deliverFile(entity, directory, afile)
      
      file = File.basename(afile)                        
                              
#      @logger.info("deliverFile directory => #{directory}")
#      @logger.info("deliverFile file => #{file}") 
                              
                                    
      bByType  = false
      dimsDirs = @dimConfig.getTargetDirs4Filename(file)
      dimsName = @dimConfig.getDIMs4Filename(file)
               
      if dimsName != false then
         if @isDebugMode == true then
            dimsName.each{|dim|
               @logger.debug("#{file} is disseminated to #{dim}")
            }
         end
      else
         # @logger.warn("#{file} has no InTray config")
         if @isDebugMode == true then
            @logger.debug("#{file} has no InTray config")
         end
      end            

      if dimsDirs.empty? == false then
	      hdlinked = false
               
         if bByType == true then
            hdlinked = @dimConfig.isHardLinked?(fileType)
	      else
            hdlinked = @dimConfig.isHardLinked?(file)
         end
                  
         if @isDebugMode == true then
			   @logger.debug("#{file} is disseminated in: #{dimsDirs}")
		   end
         
#         disseminate(file, directory, dimsDirs, hdlinked)
#         File.delete("#{directory}/#{file}")
 
 
         ## 20200324
 
 		   # ret = disseminate(entity, file, directory, dimsDirs, hdlinked)

         ret = disseminate(entity, file, directory, dimsName, hdlinked)

         # ---------------------------------
         # 20170601 - Patch to compress locally disseminated files               
         
         if ret == true then
            ret = compressFile(dimsName, file)
         end
               
         # ---------------------------------

         
         # The original file is only deleted if the dissemination has been
         # performed successfully, otherwise it is kept in order to not loose
         # the information and perform a later manual dissemination 
         if ret == true then
            begin
               if @isDebugMode == true then
                  @logger.debug("[DEC_951_1] I/F #{entity}: Removing #{directory}/#{file}")
               end
               FileUtils.rm_f("#{directory}/#{file}")
               if @isDebugMode == true then
                  @logger.debug("File #{file} has been disseminated locally according to rules")
               end
            rescue Exception
               @logger.error("dissemination : Could not delete #{file}")
               exit(99)
            end
         else
            @logger.warn("[DEC_331] I/F #{entity}: #{file} is stuck in #{directory} directory")
         end       
      else         
         if @isDebugMode == true then
            @logger.debug("#{file} is not disseminated to any Intray")
            @logger.debug("#{file} is still placed in #{directory}")
         end
      end
   end
   ## -----------------------------------------------------------
   
private

   @@isModuleOK        = false
   @@isModuleChecked   = false
   @isDebugMode        = false
   @@configDirectory   = ""  
   @@monitorCfgFiles   = nil
   @@arrExtEntities    = nil

   ## -----------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity      
      bDefined = true
      bCheckOK = true
 
      if !ENV['DCC_CONFIG'] and !ENV['DEC_CONFIG'] then
         puts "DEC_CONFIG environment variable not defined !  :-(\n"
         bCheckOK = false
         bDefined = false
      end

      configDir = nil
         
      if ENV['DEC_CONFIG'] then
         configDir         = %Q{#{ENV['DEC_CONFIG']}}  
      else
         configDir         = %Q{#{ENV['DCC_CONFIG']}}  
      end        
            
      @@configDirectory = configDir
         
      if bCheckOK == false then
         puts "FileDeliverer2InTrays::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end      
   end
   ## -----------------------------------------------------------
	##
   ## It disseminates the file from a directory to a set of target dirs.
   ## GOCEPMF-SPR-005
   ## First at all it copies the file hidden in the In-Tray
   ## Once it has been completely copied, it renames it to the operational name
	
   ## 20200325 - change function signature to include the Intray names
   ## > get directory
   ## > get execution command
   
   def disseminate(entity, afile, fromDir, arrToIntray, hardlinked = false)
      
#      puts
#      puts
#      puts caller
      
      # @logger.info(arrToIntray)
      
      
      bReturn = true
      
      if hardlinked == true and arrToIntray.length <2
		   if @isDebugMode == true then
			   @logger.debug("HardLink flag for #{file} is useless for one target dir")
			end
		end
		
		prevDir = Dir.pwd
      
      file = File.basename(afile)
      
		Dir.chdir(fromDir)
      
		bFirst      = true
		firstDir    = ""
      
      arrToIntray.each{|intray|
               
         targetDir = @dimConfig.getInTrayDir(intray)
         exec      = @dimConfig.getInTrayExecution(intray)
                  
#         

      
         checkDirectory(targetDir)
		   cmd = ""
         
         # -------------------------------------------
         # Management of event NewFile2Intray
         
         hParams              = Hash.new
         hParams["filename"]  = file 

         hParams["directory"] = targetDir
      
         # -------------------------------------------  
         
		   if bFirst == true then
			   bFirst   = false
           
            ### 20200316 UPDATE
            ### First operation is a hardlink to avoid copies
            # Move operation is not safe.
            # When dissemination is performed to several In-Trays, it is not
            # possible to rely on that a file would be still present in the first intray
            # a file is disseminated in.
             
            cmd  = "\\ln -f #{file} #{targetDir}/.TEMP_#{file}"
            #cmd  = "\\cp -f #{file} #{targetDir}/.TEMP_#{file}"
            #cmd  = "\\mv -f #{file} #{targetDir}/.TEMP_#{file}"
                       
            if @isDebugMode == true then
	   		   @logger.debug("[DEC_941] Intray #{intray}: Disseminate command (I) : #{cmd}")
		   	end
            bRet = execute(cmd, "pull")
            
            if bRet == false then
               @logger.error("[DEC_625] Intray #{intray}: #{file} failed dissemination into #{targetDir}")
               Dir.chdir(prevDir)
               bReturn = false
               return false
            end
            
            # --------------------------
            # Remove in target directory any eventual copy of a file with the same name
            if File.exists?(targetDir+'/'+file) then 
               @logger.warn("[DEC_555] Intray #{intray}: #{file} duplicated already existed in #{targetDir}")
               @logger.warn("[DEC_556] Intray #{intray}: #{file} duplicated will be deleted before dissemination")
               FileUtils.rm_rf(targetDir+'/'+file) 
            end
            # --------------------------
            
			   cmd  = "\\mv -f #{targetDir}/.TEMP_#{file} #{targetDir}/#{file}"
   			if @isDebugMode == true then
	   		   @logger.debug("[DEC_942.1] Intray #{intray}: Disseminate command (II) : #{cmd}")
		   	end
            bRet = execute(cmd, "pull")

            if bRet == false then
               @logger.error("FileDeliverer2InTrays::disseminate Could not place #{file} in Target Directory #{targetDir} ! :-(")
               bReturn = false
            else
               if @isDebugMode == true then
                  @logger.debug("chmod a+r #{targetDir}/#{file}")
               end
               FileUtils.chmod "a=r", "#{targetDir}/#{file}" #, :verbose => true
            
               @logger.info("[DEC_115] Intray #{intray}: #{file} disseminated into #{targetDir}")
                               
               firstDir = targetDir                            
               event  = EventManager.new
      
               if exec != "" and exec != nil then
                  event.exec_trigger(intray, "NewFile2Intray", exec, hParams, @logger)
               end
      
               if @isDebugMode == true then
                  event.setDebugMode
               end
      
               if @isDebugMode == true then
                  @logger.debug("Event NEWFILE2INTRAY #{file} => #{targetDir}")
               end
               # @logger.info("Event NEWFILE2INTRAY #{file} => #{targetDir}")            
               
               event.trigger(entity, "NEWFILE2INTRAY", hParams, @logger)
               
               # -------------------------------------------
            end
                                   
			  
			else
			   
            if hardlinked == true then
               
               # ---------------------------------
               # Delete if the file previously exists in the target dir
               if File.exist?("#{targetDir}/#{file}") == true then
                  cmd = "\\rm -f #{targetDir}/#{file}"
                  @logger.warn("[DEC_555] Intray #{intray}: #{file} duplicated already existed in #{targetDir}")
                  @logger.warn("[DEC_556] Intray #{intray}: #{file} duplicated will be deleted before dissemination")
                  execute(cmd, "pull")
               end
               
               # ---------------------------------
			      cmd = "ln #{firstDir}/#{file} #{targetDir}"
               if @isDebugMode == true then
	   		      @logger.debug("[DEC_942.2] Intray #{intray}: Disseminate command : #{cmd}")
		   	   end
               bRet = execute(cmd, "pull")

               if bRet == false then
                  @logger.error("[DEC_626] Intray #{intray}: #{file} failed dissemination into #{targetDir}")
                  bReturn = false
               else
                  if @isDebugMode == true then
                     @logger.debug("chmod a=r #{targetDir}/#{file}")
                  end
                  FileUtils.chmod "a=r", "#{targetDir}/#{file}" #, :verbose => true
                  
                  @logger.info("[DEC_115] Intray #{intray}: #{file} disseminated into #{targetDir}")
                  
                  event  = EventManager.new
      
                  if @isDebugMode == true then
                     event.setDebugMode
                  end

                  #@logger.info("Event NEWFILE2INTRAY #{file} => #{targetDir}")
                  
                  if @isDebugMode == true then
                     @logger.debug("Event NEWFILE2INTRAY #{file} => #{targetDir}")            
                  end
                  
                  event.trigger(@entity, "NEWFILE2INTRAY", hParams, @logger)   

               end
				else
			      cmd  = "\\cp -f #{file} #{targetDir}/.TEMP_#{file}"
               #cmd  = "\\cp -f #{firstDir}/#{file} #{targetDir}/.TEMP_#{file}"
   			   if @isDebugMode == true then
	   		      @logger.debug(cmd)
		   	   end
               bRet = execute(cmd, "pull")
            
               if bRet == false then
                  @logger.error("Could not copy file #{file} into target Directory")
                  bReturn = false
               end
            
			      cmd  = "\\mv -f #{targetDir}/.TEMP_#{file} #{targetDir}/#{file}"
   			   if @isDebugMode == true then
	   		      @logger.debug(cmd)
		   	   end
               bRet = execute(cmd, "pull")
               
               if bRet == false then
                  @logger.error("Could not disseminate into #{targetDir} intray")
                  bReturn = false
                  Dir.chdir(prevDir)
                  return false
               else
                  @logger.info("[DEC_115] Intray #{intray}: #{file} disseminated into #{targetDir}")
                  
                  event  = EventManager.new
      
                  if @isDebugMode == true then
                     event.setDebugMode
                  end
      
                  event.trigger(entity, "NEWFILE2INTRAY")
   
                  #@logger.info("Event NEWFILE2INTRAY #{file} => #{targetDir}")
                  if @isDebugMode == true then
                     @logger.debug("Event NEWFILE2INTRAY #{file} => #{targetDir}")            
                  end
               end
				end
			end
		}
		Dir.chdir(prevDir)
      return bReturn
   end
	# -------------------------------------------------------------

   ## -----------------------------------------------------
   ##
   ## 20170601 Eventual compression upon local dissemination
   ##
   ##

   def compressFile(dimsName, file)
      retVal = true         
      
      dimsName.each{|dim|
      
         inTray   = @dimConfig.getInTrayDir(dim)
         compress = @dimConfig.getInTrayCompress(dim)

         if compress == nil then
            if @isDebugMode == true then
               @logger.debug("No Compression #{dim} - #{file}")
            end
            next
         end
               
         sourceFile = "#{inTray}/#{file}"
         targetFile =  File.basename(file, ".*")
         targetFile = "#{targetFile}.7z"
         targetFile = "#{inTray}/#{targetFile}"

         if File.exist?(sourceFile) == false then
            @logger.error("missing #{sourceFile}")
            @logger.error("skip compression in #{compress} to #{targetFile}")
            retVal = false
            next
         end
                  
         if compress == "7z" then
                                     
            ret = pack7z(sourceFile, targetFile, true, @isDebugMode, @logger)
                     
            if ret == false then
               @logger.error("Could not compress in #{compress} #{targetFile}")
               File.delete(targetFile)
               retVal = false
            else
               msg = "[DEC_116] Intray #{dim}: #{file} compressed in #{compress} at #{inTray}"
               @logger.info(msg)
            end
         else
            @logger.error("Compression mode #{compress} not supported")
            retVal = false
         end
                  
      }
      # -----------------------------------------------------
      return retVal
   end   
   ## -------------------------------------------------------------   
      
end # class

end # module
