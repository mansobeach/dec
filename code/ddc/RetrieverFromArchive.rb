#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #RetrieverFromArchive class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# CVS: $Id: RetrieverFromArchive.rb,v 1.13 2008/07/03 11:38:26 decdev Exp $
#
# Module Data Distributor Component
# This class retrieves files to be transferred from the DDC Archive.
# DDC Archive is pointed by DDC_ARCHIVE_ROOT Environment variable.
#
#########################################################################

require 'cuc/DirUtils'
require 'cuc/FT_PackageUtils'
require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadFileDestination'
require 'ddc/ReadConfigDDC'


require 'fileutils'


module DDC


class RetrieverFromArchive

   include CUC::DirUtils
   include FileUtils::NoWrite
   
   #-------------------------------------------------------------
      
   # Class constructor.
   def initialize
      ddcConfig = DDC::ReadConfigDDC.instance
      @confDest = CTC::ReadFileDestination.instance
      @arrFileTypes       = @confDest.getAllOutgoingTypes
      @bDeleteSourceFiles = ddcConfig.deleteSourceFiles?
      @globalOutbox       = ddcConfig.getGlobalOutbox
      @isDebugMode        = false
      checkModuleIntegrity
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      puts "DDC_RetrieverFromArchive debug mode is on"
      @isDebugMode = true
   end
   #-------------------------------------------------------------
   
   # This Method extracts all files to be delivered from the DCC Archive
   # Optionally by a configuration flag it deletes them.
   def retrieve(bJustList = false)
      prevDir = Dir.pwd
      
      if bJustList == true then
         puts
         puts "==============================="
         puts "DDC Source Archive:" 
         puts "#{@sourceDirectory}"
         puts "==============================="
         puts
      end

      if bJustList == true and @arrFileTypes.length == 0 then
         puts "No File-types are configured to be sent ?:-|"
         puts
      end

      @arrFileTypes.each{|filetype|

         Dir.chdir(@sourceDirectory)

         begin
            Dir.chdir(filetype)
            if bJustList == true then
               puts
               puts "[#{filetype}] - Searching files"
            end
         rescue Exception
            puts
            puts "Directory #{filetype} does not exist in DDC_ARCHIVE_ROOT"
            next
         end
         arrFiles = Dir["*#{filetype}*"]
         arrFiles.each{|afile|
             if bJustList == true then
                puts afile
             else
                # FileUtils.cp_r(afile, %Q{#{@targetDirectory}/#{afile}})
                
                cmd = "\\cp -Rf #{afile} #{@targetDirectory}/#{afile}"
                if @isDebugMode == true then
                  puts cmd
                end
                system(cmd)
                
                if @bDeleteSourceFiles == true and bJustList == false then
                   FileUtils.rm_rf(afile)
                end
             end
         }
      }
      Dir.chdir(prevDir)

   end
   #-------------------------------------------------------------
   
   # Copy the files from the target Directory to all outboxes
   def deliver(bJustList = false)
      
      @entityConfig = CTC::ReadInterfaceConfig.instance
      arrEntity     = @entityConfig.getAllExternalMnemonics
   
      arrEntity.each{|entity|
         dir = @entityConfig.getIncomingDir(entity)
         checkDirectory(dir)
         dir = @entityConfig.getOutgoingDir(entity)
         checkDirectory(dir)
      }
            
      prevDir = Dir.pwd
      Dir.chdir(@targetDirectory)
      
      @arrFileTypes.each{|filetype|
         arrFiles    = Dir["*#{filetype}*"]
         
         arrEntities = @confDest.getEntitiesReceivingOutgoingFile(filetype)
         
         arrFiles.each{|afile|
            puts
            puts afile
            arrEntities.each{|anEntity|
               dir         = @entityConfig.getOutgoingDir(anEntity)
               arrMethods  = @confDest.getDeliveryMethods(anEntity, filetype)
               arrMethods.each{|aMethod|
                  aDir = %Q{#{dir}/#{aMethod}}
                  checkDirectory(aDir)
                  if bJustList == false then
		               begin
                        # cmd = "\\cp -Rf #{afile} #{aDir}/#{afile}"
                        cmd = "\\cp -Rf #{afile} #{aDir}/"
                        if @isDebugMode == true then
                           puts cmd
                        end
                        system(cmd)
                        #FileUtils.cp_r(afile, %Q{#{aDir}/#{afile}})
			               puts "Copied to #{anEntity} #{aMethod} outbox"
			
			               # Apply Compress Method
			               ext        = getFileExtension(afile)
			               compMethod = @confDest.getCompressMethod(anEntity, filetype)
			               packFile(afile, aDir, compMethod)
			
                     rescue Exception => e
		     	            puts e.to_s
			               exit(99)
			               #puts e.backtrace
		               end
		     
                  else
                     puts "Would be Copied to #{anEntity} #{aMethod} outbox"
                  end
               }
               
            }
         
	      }
      }
      Dir.chdir(prevDir)

      #Delete global outbox folder unless we run in debug mode
      if @isDebugMode == false then
         cmd = "\\rm -rf #{@targetDirectory}"
         system(cmd)
      end

   end
   #-------------------------------------------------------------
   

   #-------------------------------------------------------------

private

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity 
      bDefined = true
      bCheckOK = true
   
      if !ENV['DDC_ARCHIVE_ROOT'] then
         puts "\nDDC_ARCHIVE_ROOT environment variable not defined !  :-(\n\n"
         bCheckOK = false
         bDefined = false
      end

      if bCheckOK == false then
         puts "DDC_RetrieverFromArchive::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end
      
      @sourceDirectory = ENV['DDC_ARCHIVE_ROOT']
      @targetDirectory = @globalOutbox
      
      time             = Time.new
      tmpConfigFile    = time.to_i.to_s
      
      @targetDirectory = %Q{#{@targetDirectory}/_Delivery_/#{tmpConfigFile}}
    
      checkDirectory(@sourceDirectory)
      checkDirectory(@targetDirectory)
  end
   #-------------------------------------------------------------

   def packFile(file, srcPath, method, bUnPack = false)
      bRet = false
      if @isDebugMode == true then
         puts "#{file} is Packaged with #{method} method"
      end
      package        = FT_PackageUtils.new(file, srcPath, true)
      if @isDebugMode == true then
         package.setDebugMode
      end
      bMethod = package.setCompressMethod(method)
   
      if bMethod == false then
         puts "\nFATAL Error in getFilesToBeTransferred::packFile"
         puts "\nError in Compression Method for #{file} !! =:-O\n"
         puts
         exit(99)
      end
      
      # BOLF - 2007-04-10 We do not perform unpack directly anymore
      # Currently there is a Package method called "unpack" that performs
      # that operation when required.

      if bUnPack == false then
         bRet = package.pack
         arr  = Array.new
         arr << bRet
         bRet = arr
      else      
         bRet = package.unpack
      end
   
      if bRet == false then
         puts "\nError in RetrieverFromArchive::packFile"
         puts "\nFailed to Pack #{file} !! =:-O\n"
         exit(99)      
      end 
      return bRet
   end
   #-------------------------------------------------------------
      
end # class

end # module

