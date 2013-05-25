#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileRetriever class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: FileRetriever.rb,v 1.14 2008/11/26 12:40:47 decdev Exp $
#
# module MINARC
#
#########################################################################

require "cuc/DirUtils"
require "cuc/EE_ReadFileName"
require "minarc/MINARC_DatabaseModel"
require "minarc/ReportEditor"
require "minarc/FileDeleter"

module MINARC

class FileRetriever

   include CUC::DirUtils
   #-------------------------------------------------------------   
   
   # Class contructor
   def initialize(bListOnly = false)
      @bListOnly  = bListOnly
      @rule       = "ALL"
      checkModuleIntegrity
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "FileRetriever debug mode is on"
   end
   #-------------------------------------------------------------

   def disableListMode
      @bListOnly = false
   end
   #-------------------------------------------------------------

   def enableListMode
      @bListOnly = true
   end
   #-------------------------------------------------------------

   def enableReporting(filePath)
      @bReport = true
      @reportFullName = filePath
   end
   #-------------------------------------------------------------

   def setRule(rule = "ALL")
      @rule = rule
   end
   #-------------------------------------------------------------

   # Main method of the class.
   def retrieve_by_type(destination, fileType, start = nil, stop = nil, bDelete = false, bIncStart = false, bIncStop = false, bHardlink = false)
      
      arrFiles = Array.new

      if @rule == "NEWEST" then
         arrFiles = ArchivedFile.last(1)
      else
         arrFiles = ArchivedFile.searchAllWithinInterval(fileType.upcase[0..19], start, stop, bIncStart, bIncStop)
      end

      retVal = true

      if arrFiles != nil and arrFiles.size > 0 then
         case @rule
            when "OLDEST" then arrFiles = keepOnlyOldest(arrFiles)
            when "FIRST"  then arrFiles = keepOnlyFirst(arrFiles)
            when "LAST"   then arrFiles = keepOnlyLast(arrFiles)
         end
      end

      if @bReport then
         editor = MINARC::ReportEditor.new(arrFiles)
         editor.generateReport(@reportFullName)
      end

      if arrFiles != nil then
         arrFiles.each{|aFile|
            if @bListOnly then
               puts aFile.filename
               aRetVal = true
            else
               aRetVal = extractFromArchive(destination, aFile.filetype, aFile.filename,
                                              aFile.archive_date, bDelete, bHardlink, aFile.path)

               if aRetVal then
                  aFile.last_access_date = Time.now
                  begin
                     aFile.save
                  rescue Exception => e
                     # Could not update last access time
                     puts "MINARC::FileRetriever - Could not update #{aFile.filename} last_access"
                  end
               end
            end

            if retVal then
               retVal = aRetVal
            end
         }
      end

      return retVal
   end
   #-------------------------------------------------------------

   def retrieve_by_name(destination, filename, bDelete = false, bHardlink = false)

      aFile = ArchivedFile.find_by_filename(filename)

      if !aFile then
         return false
      end

      if @bReport then
         editor = MINARC::ReportEditor.new(Array[aFile])
         editor.generateReport(@reportFullName)
      end

      if @bListOnly then
         puts aFile.filename
         return true
      else
         retVal = extractFromArchive(destination, aFile.filetype, aFile.filename, 
                                          aFile.archive_date, bDelete, bHardlink, aFile.path)

         if retVal then
            aFile.last_access_date = Time.now
            aFile.save
         end
      
         return retVal
      end

   end
   #-------------------------------------------------------------

private


   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      
      if !ENV['MINARC_ARCHIVE_ROOT'] then
         puts
         puts "MINARC_ARCHIVE_ROOT environment variable is not defined !\n"
         bDefined = false
      end

      if bCheckOK == false or bDefined == false then
         puts("FileRetriever::checkModuleIntegrity FAILED !\n\n")
         exit(99)
      end

      @archiveRoot = ENV['MINARC_ARCHIVE_ROOT']
      return
   end
   #-------------------------------------------------------------

   def extractFromArchive(destination, fileType, fileName, archDate, bDelete, bHardlink, path)

      arrEntries = Array.new

      # srcDir = "#{@archiveRoot}/#{path}"
      srcDir = "#{path}"
      
      srcPath = "#{srcDir}/" << fileName

      destDir = "#{destination}"

      if File.directory?(srcPath) then
         srcDir  << "/" << fileName
         destDir << "/" << fileName
         Dir.chdir(srcPath) do
            arrEntries = Dir["*"]
         end
      else
         arrEntries.push(fileName)
      end

      # Creating the destination directory if necessary
      if !checkDir(destDir) then
         puts "'#{destDir}' is not a valid path for extracting the file(s) !"
         return false
      end

      bRetVal = true

      # Copy / Link the file(s) to the destination directory
      arrEntries.each {|entry|

         if bHardlink then
            cmd = "\\ln -f #{srcDir}/#{entry} #{destDir}/#{entry}"
         else
            cmd = "\\cp -f #{srcDir}/#{entry} #{destDir}/#{entry}"
         end

         if @isDebugMode then
            puts cmd
         end
         
         tmpVal = system(cmd)

         if bRetVal then
            bRetVal = tmpVal
         end
      }

      if bRetVal then
         
         if bDelete then
            deleter = FileDeleter.new
            if @isDebugMode then
               deleter.setDebugMode
            end
            retVal = deleter.delete_by_name(fileName)
            if !retVal then
               puts "Could not delete source file from the archive :-("
            end
         end
      
         puts "(Retrieved) : " << fileName
         
         return true

      else
         return false
      end

   end
   #-------------------------------------------------------------

   def checkDir(dir)
      if File.directory?(dir) then
         return true
      else
         cmd = %{mkdir -p #{dir}}
         return system(cmd) 
      end
   end
   #-------------------------------------------------------------

   # keeps the file that has the newest archive date
   def keepOnlyNewest(arrFiles)
      newFile = nil
      arrFiles.each{|aFile|
         if !newFile then
            newFile = aFile
            next            
         end

         if aFile.archive_date > newFile.archive_date then
            newFile = aFile
            next
         end
      }
      return Array[newFile]
   end
   #-------------------------------------------------------------

   # keeps the file that has the oldest archive date
   def keepOnlyOldest(arrFiles)
      oldFile = nil
      arrFiles.each{|aFile|
         if !oldFile then
            oldFile = aFile
            next            
         end

         if aFile.archive_date < oldFile.archive_date then
            oldFile = aFile
            next
         end
      }
      return Array[oldFile]
   end
   #-------------------------------------------------------------

   # keeps the file that has the lower validity values
   # First criteria  : lower validity_start
   # Second criteria : lower validity_stop
   # There might be multiple result files
   def keepOnlyFirst(arrFiles)
      
      # Sort files by validity_start (ASC)
      arrFiles.sort_by{|aFile|
         aFile.validity_start
      }

      # The val_start of the first element of the array is the reference value (smallest validity_start of the set)
      refStart = arrFiles[0].validity_start

      # Exclude all the files that have a higher validity_start than the reference 
      arrFiles = arrFiles.reject{|aFile|
         aFile.validity_start != refStart
      }

      # If there are several files with same start
      if arrFiles.size > 1 then
         # Sort files by validity_stop (ASC)
         arrFiles.sort_by{|aFile|
            aFile.validity_stop
         }

         # The val_stop of the first element of the array is the reference value (smallest validity_stop of the set)
         refStop = arrFiles[0].validity_stop

         # Exclude all the files that have a higher validity_stop than the reference 
         arrFiles = arrFiles.reject{|aFile|
            aFile.validity_stop != refStop
         }
      end

      return arrFiles
   end
   #-------------------------------------------------------------

   # keeps the file that has the higher validity values
   # First criteria  : higher validity_stop
   # Second criteria : higher validity_start
   # There might be multiple result files
   def keepOnlyLast(arrFiles)

      # Sort files by validity_stop (ASC)
      arrFiles.sort_by{|aFile|
         aFile.validity_stop
      }
         
      # The val_stop of the last element of the array is the reference value (greatest validity_stop of the set)
      refStop = arrFiles[arrFiles.size - 1].validity_stop
      
      # Exclude all the files that have a lower validity_stop than the reference 
      arrFiles = arrFiles.reject{|aFile|
         aFile.validity_stop != refStop
      }
    
      # If there are several files with same start
      if arrFiles.size > 1 then
         # Sort files by validity_start (ASC)
         arrFiles.sort_by{|aFile|
            aFile.validity_start
         }

         # The val_start of the last element of the array is the reference value (greatest validity_start of the set)
         refStart = arrFiles[arrFiles.size - 1].validity_start

         # Exclude all the files that have a lower validity_start than the reference 
         arrFiles = arrFiles.reject{|aFile|
            aFile.validity_start != refStart
         }
      end

      return arrFiles
   end
   #-------------------------------------------------------------

end # class

end # module
#=====================================================================
