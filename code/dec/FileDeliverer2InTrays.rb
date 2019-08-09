#!/usr/bin/env ruby

#########################################################################
#
# = Ruby source for #FileDeliverer2InTrays class
#
# = Written by DEIMOS Space S.L. (bolf)
#
# = Data Exchange Component -> Data Exchnge Component
# 
# CVS:
#   $Id: FileDeliverer2InTrays.rb,v 1.16 2008/07/03 11:38:07 decdev Exp $
#
#########################################################################

require 'fileutils'

require 'cuc/Log4rLoggerFactory'
require 'cuc/CommandLauncher'
require 'cuc/DirUtils'
require 'cuc/PackageUtils'
require 'ctc/ReadInterfaceConfig'
require 'ctc/EventManager'
require 'cuc/EE_ReadFileName'
require 'dcc/ReadInTrayConfig'
require 'dec/ReadConfigDEC'

 # This class moves all files from the I/Fs local inboxes
 # to the configured In-Trays  

module DEC

class FileDeliverer2InTrays

   include CUC::DirUtils
   include CUC::CommandLauncher
   include CUC::PackageUtils
   
   ## -------------------------------------------------------------   
   
   # Class contructor
   def initialize(debugMode = false)
      @@isModuleOK        = false
      @@isModuleChecked   = false
      @isDebugMode        = debugMode
      checkModuleIntegrity
	   @entConfig = CTC::ReadInterfaceConfig.instance
		@dimConfig = DCC::ReadInTrayConfig.instance
      
      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("FileDeliverer2InTrays", "#{@@configDirectory}/dec_log_config.xml")
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
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "FileDeliverer2InTrays debug mode is on"
	   @entConfig.setDebugMode
		@dimConfig.setDebugMode
   end
   #-------------------------------------------------------------
   
   # Main method of the class which delivers the incoming files
   # from the local Entities In-Boxes to the DIMs In-Trays
   def deliver(mnemonic = "")
#	   setDebugMode
      
      if mnemonic != "" and @isDebugMode == true then
         puts "Dissemination of files received from #{mnemonic}"
      end
      
      arrEnts   = @entConfig.getAllExternalMnemonics     

		arrEnts.each{|entity|
			
         if mnemonic != "" and entity.to_s != mnemonic then
            next
         end
         
         @logger.info("Dissemination of files received from #{entity}")
         dir = @entConfig.getIncomingDir(entity)
         
         if @isDebugMode == true then
            puts "================================================"          
            puts "#{entity} local inbox #{dir}"
         end
            	
			arrFiles = getFilenamesFromDir(dir, "*")
			if arrFiles.empty? == true then
			   if @isDebugMode == true then
				   puts "There are no new files"
				end
			end

			arrFiles.each{|file|
         		   
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
               dimsName.each{|dim|
                  @logger.debug("#{file} is disseminated to #{dim}")
               }
            else
               # @logger.warn("#{file} has no In-Tray config")
               @logger.debug("#{file} has no In-Tray config")
            end            
            
            
            if dimsDirs.empty? == false then
            
				   hdlinked = ""
				
               if bByType == true then
                  hdlinked = @dimConfig.isHardLinked?(fileType)
	            else
                  hdlinked = @dimConfig.isHardLinked?(file)
               end
                         
               if @isDebugMode == true then
# 					   puts "#{file} is placed in:"
# 				      puts dimsDirs
# 					else
					   puts "#{file} is disseminated to:"
                  puts dimsName
                  puts
					end

               # main dissemination method

					ret = disseminate(file, dir, dimsDirs, hdlinked)
					
               # ---------------------------------
               # 20170601 - Patch to compress locally disseminated files               
               ret = compressFile(dimsName, file)
               
               # ---------------------------------
               
               # The original file is only deleted if the dissemination has been
               # performed successfully, otherwise it is kept in order to not loose
               # the information and perform a later manual dissemination 
               if ret == true then
                  begin
                     FileUtils.rm_rf("#{dir}/#{file}")
                  rescue Exception
                     @logger.error("Could not delete #{dir}/#{file}")
                     puts
                     puts "Could not delete #{dir}/#{file} ! :-("
                     puts
                     exit(99)
                  end
               else      
                  @logger.error("#{file} has not been disseminated")
                  @logger.warn("#{file} is still placed in #{dir}")
                  puts "#{file} has not been disseminated"
                  puts "#{file} is still placed in #{dir}"
               end
				end
			}
         if @isDebugMode == true then
			   puts "================================================"
            puts
         end
      }
      
   end
   #-------------------------------------------------------------
   
   # It Deliver Files present in a given directory
   def deliverFromDirectory(directory)
			puts
         arrFiles = getFilenamesFromDir(directory, "*")
			if arrFiles.empty? == true then
			   if @isDebugMode == true then
				   puts "There are no new files"
				end
			end
			
         arrFiles.each{|file|
            deliverFile(directory, file)
			}
   end
   #-------------------------------------------------------------
   
   # It delivers a given file
   def deliverFile(directory, file)
      
      bIsEEFile = CUC::EE_ReadFileName.new(file).isEarthExplorerFile?
      fileType  = CUC::EE_ReadFileName.new(file).fileType
				
      dimsDirs  = Array.new
      dimsName  = ""
      bByType   = true
            
      if bIsEEFile == true then
         bByType  = true
         dimsDirs = @dimConfig.getTargetDirs4Filetype(fileType)
         dimsName = @dimConfig.getDIMs4Filetype(fileType)
         
         if dimsName == false then
            bByType  = false
            dimsDirs = @dimConfig.getTargetDirs4Filename(file)
            dimsName = @dimConfig.getDIMs4Filename(file)
         end

		else
         bByType  = false
         dimsDirs = @dimConfig.getTargetDirs4Filename(file)
         dimsName = @dimConfig.getDIMs4Filename(file)
      end   
               
      if dimsName != false then
         dimsName.each{|dim|
            @logger.debug("#{file} is disseminated to #{dim}")
         }
      else
         # @logger.warn("#{file} has no In-Tray config")
         @logger.debug("#{file} has no In-Tray config")
      end            

      if dimsDirs.empty? == false then
	      hdlinked = false
               
         if bByType == true then
            hdlinked = @dimConfig.isHardLinked?(fileType)
	      else
            hdlinked = @dimConfig.isHardLinked?(file)
         end
                  
         if @isDebugMode == true then
			   puts "#{file} is placed in:"
				puts dimsDirs
		   else
			#   puts file
		   end
         
#         disseminate(file, directory, dimsDirs, hdlinked)
#         File.delete("#{directory}/#{file}")
 
 		   ret = disseminate(file, directory, dimsDirs, hdlinked)

         # ---------------------------------
         # 20170601 - Patch to compress locally disseminated files               
               
         ret = compressFile(dimsName, file)
               
         # ---------------------------------

         
         # The original file is only deleted if the dissemination has been
         # performed successfully, otherwise it is kept in order to not loose
         # the information and perform a later manual dissemination 
         if ret == true then
            begin
               FileUtils.rm_rf("#{directory}/#{file}")
            rescue Exception
               @logger.error("deliverFile : Could not delete #{directory}/#{file}")
               puts
               puts "Could not delete #{directory}/#{file} ! :-("
               puts
               exit(99)
            end
         else
            @logger.error("deliverFile : #{file} has not been disseminated")
            @logger.warn("deliverFile : #{file} is still placed in #{directory}")
            puts "#{file} has not been disseminated"
            puts "#{file} is still placed in #{directory}"
         end       
      else
         # @logger.warn("#{file} is not disseminated to any In-Tray")
         @logger.debug("#{file} is not disseminated to any In-Tray")
         # @logger.warn("#{file} is still placed in #{directory}")
         @logger.debug("#{file} is still placed in #{directory}")
         puts "#{file} is not disseminated to any In-Tray"
      end
   end
   #-------------------------------------------------------------
   
private

   @@isModuleOK        = false
   @@isModuleChecked   = false
   @isDebugMode        = false
   @@configDirectory   = ""  
   @@monitorCfgFiles   = nil
   @@arrExtEntities    = nil

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity      
      bDefined = true
      bCheckOK = true
 
      if !ENV['DCC_CONFIG'] and !ENV['DEC_CONFIG'] then
         puts "DCC_CONFIG environment variable not defined !  :-(\n"
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
   #-------------------------------------------------------------
	
   # It disseminates the file from a directory to a set of target dirs.
   # GOCEPMF-SPR-005
   # First at all it copies the file hidden in the In-Tray
   # Once it has been completely copied, it renames it to the operational name
	
   def disseminate(file, fromDir, arrToDir, hardlinked = false)
      bReturn = true
      if hardlinked == true and arrToDir.length <2
		   if @isDebugMode == true then
			   puts "HardLink flag is useless for one target dir"
			end
		end
		
		prevDir = Dir.pwd
      
		Dir.chdir(fromDir)
      
		firstDir = arrToDir[0]
		bFirst   = true
		arrToDir.each{|targetDir|
         checkDirectory(targetDir)
		   cmd = ""
		   if bFirst == true then
			  
            # Move operation is not safe.
            # When dissemination is performed to several In-Trays, it is not
            # possible to rely on that a file would be still present in the first intray
            # a file is disseminated in.
 
            cmd  = "\\cp -f #{file} #{targetDir}/.TEMP_#{file}"
            #cmd  = "\\mv -f #{file} #{targetDir}/.TEMP_#{file}"
            
            if @isDebugMode == true then
	   		   puts cmd
		   	end
            bRet = execute(cmd, "mv2DimsInTrays")
            
            if bRet == false then
               puts "Could not copy File in Target Directory "
               bReturn = false
            end
            
            # Remove in target directory any eventual copy of a file with the same name
            if File.exists?(targetDir+'/'+file) then 
               FileUtils.rm_rf(targetDir+'/'+file) 
            end
            
			   cmd  = "\\mv -f #{targetDir}/.TEMP_#{file} #{targetDir}/#{file}"
   			if @isDebugMode == true then
	   		   puts cmd
		   	end
            bRet = execute(cmd, "mv2DimsInTrays")

            if bRet == false then
               if @isDebugMode == true then
                  puts "Could not place final #{file} in Target Directory #{targetDir}! :-("
                  @logger.error("FileDeliverer2InTrays::disseminate Could not place #{file} in Target Directory #{targetDir} ! :-(")
               end
               bReturn = false
            else
            
               @logger.debug("chmod a+r #{targetDir}/#{file}")
               FileUtils.chmod "a=r", "#{targetDir}/#{file}" #, :verbose => true
            
               @logger.info("#{file} has been disseminated into #{targetDir}")
               
               # -------------------------------------------
               # Management of event NewFile2Intray
               arrParam             = Array.new
               hParam1              = Hash.new
               hParam1["filename"]  = file 

               hParam2              = Hash.new
               hParam2["directory"] = targetDir
      
               arrParam << hParam1
               arrParam << hParam2
               
               event  = CTC::EventManager.new
      
               if @isDebugMode == true then
                  event.setDebugMode
               end
      
               event.trigger(@entity, "NEWFILE2INTRAY", arrParam)
   
               @logger.debug("Event NEWFILE2INTRAY #{file} => #{targetDir}")
               #@logger.info("Event NEWFILE2INTRAY #{file} => #{targetDir}")            
               
               # -------------------------------------------
            end
                                   
			   bFirst = false
			else
			   if hardlinked == true then
               # Delete if the file previously exists in the target dir
               if File.exist?("#{targetDir}/#{file}") == true then
                  cmd = "\\rm -f #{targetDir}/#{file}"
                  @logger.warn("#{file} already existed in #{targetDir}")
                  @logger.warn("Old file #{file} will be deleted first")
                  execute(cmd, "mv2DimsInTrays")
               end
			      cmd = "ln #{firstDir}/#{file} #{targetDir}"
               if @isDebugMode == true then
	   		      puts cmd
		   	   end
               bRet = execute(cmd, "mv2DimsInTrays")

               if bRet == false then
                  puts "Could not Link File to the Target Directory"
                  bReturn = false
               else
                  
                  @logger.debug("chmod a=r #{targetDir}/#{file}")
                  FileUtils.chmod "a=r", "#{targetDir}/#{file}" #, :verbose => true
                  
                  @logger.info("#{file} has been disseminated into #{targetDir}")
                  
                  event  = CTC::EventManager.new
      
                  if @isDebugMode == true then
                     event.setDebugMode
                  end
      
                  event.trigger(@entity, "NEWFILE2INTRAY")
   
                  #@logger.info("Event NEWFILE2INTRAY #{file} => #{targetDir}")
                  @logger.debug("Event NEWFILE2INTRAY #{file} => #{targetDir}")            

               end
				else
			      cmd  = "\\cp -f #{file} #{targetDir}/.TEMP_#{file}"
               #cmd  = "\\cp -f #{firstDir}/#{file} #{targetDir}/.TEMP_#{file}"
   			   if @isDebugMode == true then
	   		      puts cmd
		   	   end
               bRet = execute(cmd, "mv2DimsInTrays")
            
               if bRet == false then
                  puts "Could not copy File in Target Directory"
                  bReturn = false
               end
            
			      cmd  = "\\mv -f #{targetDir}/.TEMP_#{file} #{targetDir}/#{file}"
   			   if @isDebugMode == true then
	   		      puts cmd
		   	   end
               bRet = execute(cmd, "mv2DimsInTrays")
               
               if bRet == false then
                  if @isDebugMode == true then
                     puts "Could not place final File in Target Directory ! :-("
                  end
                  @logger.error("Could not place final File in In-Tray")
                  bReturn = false
               else
                  @logger.info("#{file} has been disseminated into #{targetDir}")
                  
                  event  = CTC::EventManager.new
      
                  if @isDebugMode == true then
                     event.setDebugMode
                  end
      
                  event.trigger(@entity, "NEWFILE2INTRAY")
   
                  #@logger.info("Event NEWFILE2INTRAY #{file} => #{targetDir}")
                  @logger.debug("Event NEWFILE2INTRAY #{file} => #{targetDir}")            
                  
               end
				end
			end
		}
		Dir.chdir(prevDir)
      return bReturn
   end
	#-------------------------------------------------------------

   # -----------------------------------------------------
   # 20170601 Eventual compression upon local dissemination
   #
   #

   def compressFile(dimsName, file)
      retVal = true         
      
      dimsName.each{|dim|
      
         inTray   = @dimConfig.getDIMInTray(dim)
         compress = @dimConfig.getDIMCompress(dim)

         if compress == nil then
            @logger.debug("No Compression #{dim} - #{file}")
            next
         end
               
         sourceFile = "#{inTray}/#{file}"
         targetFile =  File.basename(file, ".*")
         targetFile = "#{targetFile}.7z"
         targetFile = "#{inTray}/#{targetFile}"
                  
         if compress == "7z" then
                  
#                      puts "xxxxxxxxxxx"
#                      puts sourceFile
#                      puts targetFile
#                      puts "xxxxxxxxxxx"
                   
            ret = pack7z(sourceFile, targetFile, true, @isDebugMode)
                     
            if ret == false then
               @logger.error("Could not compress in #{compress} #{file}")
               File.delete(targetFile)
               retVal = false
            else
               msg = "#{file} has been compressed in #{compress} for #{dim}"
               puts msg
               @logger.info(msg)
            end
         else
            puts "FileDeliverer2InTrays::deliver => Compression mode #{compress} not supported"
            @logger.error("Compression mode #{compress} not supported")
            retVal = false
         end
                  
      }
      # -----------------------------------------------------
      return retVal
   end   
   #-------------------------------------------------------------   
      
end # class

end # module
