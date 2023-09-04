#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #FileRetriever class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Mini Archive Component (MinArc)
### 
### Git: $Id$: FileRetriever.rb,v 1.14 2008/11/26 12:40:47 decdev Exp $
###
### module MINARC
###
#########################################################################

require 'fileutils'

require 'cuc/DirUtils'
require 'cuc/FT_PackageUtils'
require 'cuc/EE_ReadFileName'

require 'arc/MINARC_Client'
require 'arc/ReportEditor'
require 'arc/FileDeleter'


module ARC

class FileRetriever

   include CUC::DirUtils
   ## ----------------------------------------------------------- 
   
   ## Class contructor
   def initialize(bListOnly = false, bNoServer = false, logger = nil)
      @bListOnly     = bListOnly
      @rule          = "ALL"
      @arrInv        = Array.new
      @logger        = logger
      @isDebugMode   = false
      
      if ENV['MINARC_SERVER'] and !bNoServer then
         @bRemoteMode = true
      else
         @bRemoteMode = false
         require 'arc/MINARC_DatabaseModel'
      end

      checkModuleIntegrity
   end
   ## -----------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      if @logger != nil then
         @logger.debug("FileRetriever debug mode is on")
      end
   end
   ## -----------------------------------------------------------

   def disableListMode
      @bListOnly = false
   end
   #-------------------------------------------------------------

   def enableListMode
      @bListOnly = true
   end
   #-------------------------------------------------------------

   def enableReporting(filePath)
      @bReport          = true
      @reportFullName   = filePath
   end
   #-------------------------------------------------------------

   def setRule(rule = "ALL")
      @rule = rule
   end
   #-------------------------------------------------------------

   def retrieve_new_files(destination, aDate, bDelete = false, bHardlink = false, bUnpack = false)
      arrFilenames   = Array.new
      arrFiles       = ArchivedFile.getNewFiles(aDate)
      retVal         = true
      
      if arrFiles != nil then
      
         arrFiles.each{|aFile|
            
            if @bListOnly then
               arrFilenames << aFile.filename
               aRetVal = true
            else
                     
               aRetVal = extractFromArchive(destination, aFile.filetype, aFile.filename,
                                              aFile.archive_date, bDelete, bHardlink, aFile.path)

               if aRetVal == true then
                  aFile.last_access_date = Time.now
                  aFile.access_counter   = aFile.access_counter + 1
                  begin
                     aFile.save
                  rescue Exception => e
                     # Could not update last access time
                     puts "ARC::FileRetriever - Could not update #{aFile.filename} last_access"
                  end
                  
                  if bUnpack == true then    
                     unPackFile(destination, aFile.filename)
                  end

                  
               end

               if retVal == true then
                  retVal = aRetVal
               end

         

            end
         
         }
         
         if @bListOnly == true then
            if arrFilenames.empty? == true then
               return false
            end 
            arrFilenames.sort.each{|name|
               puts name
            }
         end
         return true
      else
         return false
      end
      
   end
   
   # -------------------------------------------------------------
   
   def remote_retrieve_by_type(destination, fileType, start, stop, bDelete, bIncStart, bIncStop)
   
      files = remote_list_by_type(fileType)
    
      if files == false or files == nil then
         return false
      end
     
      retVal = true
     
      files.each{|file|
         cmd = "minArcRetrieve -f #{File.basename(file,File.extname(file))} -L #{destination}"
         ret = system(cmd)
         if ret == false then
            retVal = false
         end
      }
      
      if retVal == true then
         exit(0)
      else
         exit(99)
      end
      
   end
   
   # -------------------------------------------------------------
   
   def remote_list_by_type(fileType)
      if @isDebugMode == true then
         puts "FileRetriever::#{__method__.to_s}"
      end
      arc = ARC::MINARC_Client.new(@logger)
      if @isDebugMode == true then
         arc.setDebugMode
      end
      
      ret = arc.listFile_By_Filetype(fileType)
      
      if ret == false then
         return false
      else
         return ret.split("\n").sort.each{|file| puts File.basename(file,File.extname(file))}
      end   
   end
   # -------------------------------------------------------------

   # Main method of the class.
   def retrieve_by_type(destination, fileType, start = nil, stop = nil, bDelete = false, bIncStart = false, bIncStop = false, bHardlink = false)

      if @bRemoteMode == true then      
         ret = false
         if @bListOnly == false then
            
            ret = remote_retrieve_by_type(destination, fileType, start, stop, bDelete, bIncStart, bIncStop)
         
            if ret == false then
               return ret
            end
            return true
         else
            ret = remote_list_by_type(fileType)
         end
         return ret
      end

      @arrInv  = Array.new
      arrFiles = Array.new

      if @rule == "NEWEST" then
         arrFiles = ArchivedFile.last(1)
      else
         arrFiles = ArchivedFile.searchAllWithinInterval(fileType.upcase, start, stop, bIncStart, bIncStop)
      end

      @arrInv  = arrFiles.dup 
      retVal   = true

      if arrFiles != nil and arrFiles.size > 0 then
         case @rule
            when "OLDEST" then arrFiles = keepOnlyOldest(arrFiles)
            when "FIRST"  then arrFiles = keepOnlyFirst(arrFiles)
            when "LAST"   then arrFiles = keepOnlyLast(arrFiles)
         end
      end

      if @bReport then
         editor = ARC::ReportEditor.new(arrFiles)
         editor.generateReport(@reportFullName)
      end

      arrFilenames = Array.new
      if arrFiles != nil then
         arrFiles.each{|aFile|
            if @bListOnly then
               arrFilenames << aFile.filename
               aRetVal = true
            else
               aRetVal = extractFromArchive(destination, aFile.filetype, aFile.filename,
                                              aFile.archive_date, bDelete, bHardlink, aFile.path)

               if aRetVal then
                  aFile.last_access_date = Time.now
                  aFile.access_counter   = aFile.access_counter + 1
                  begin
                     aFile.save
                  rescue Exception => e
                     # Could not update last access time
                     puts "ARC::FileRetriever - Could not update #{aFile.filename} last_access"
                  end
               end
            end

            if retVal then
               retVal = aRetVal
            end
         }
      end

      if @bListOnly == true then
         arrFilenames.sort.each{|name|
            puts name
         }
      end
      return retVal
   end
   #-------------------------------------------------------------

   def remote_list_by_name(filename)
            
      if @isDebugMode == true then
         puts "FileRetriever::#{__method__.to_s}"
      end
      arc = ARC::MINARC_Client.new(@logger)
      if @isDebugMode == true then
         arc.setDebugMode
      end
            
      ret = arc.listFile_By_Name(filename)
            
      if ret == false then
         return false
      else
         ret.split("\n").sort.each{|file| puts File.basename(file,File.extname(file))}
         return true
      end
   end
   #-------------------------------------------------------------

   def remote_retrieve_by_name(filename, destination, bUnpack)

      if @isDebugMode == true then
         puts "FileRetriever::#{__method__.to_s}"
      end
      
      if filename.include?("%2A") then
         filename = filename.dup.gsub("%2A", "*")
      end
            
      arc = ARC::MINARC_Client.new(@logger)
            
      if @isDebugMode == true then
         arc.setDebugMode
      end
      
      ret = arc.retrieveFile(filename)
            
      if @isDebugMode == true then
         puts "arc.retrieveFile => #{ret}"
      end
      
      if ret != false then
            
         # Creating the destination directory if necessary
         
         if !checkDir(destination) then
            puts "'#{destination}' is not a valid path for extracting the file(s) !"
            return false
         end

         arr = Dir["#{filename}*"]

         if arr.empty? == true then
            puts
            puts Dir.pwd
            puts
            puts "#{filename}*"
            puts
         end

         arr.each{|file|
            
            if @isDebugMode == true then
               puts "FileRetriever Processing #{file} ; destination => #{destination} ; unpack => #{bUnpack}"
            end
            
            begin
               FileUtils.mv(file, destination)
            rescue Exception => e
               # puts e.to_s
            end
            
            if @logger != nil then
               @logger.info("[ARC_202] Retrieved: #{File.basename(file,File.extname(file))}")
            else
               puts "(Retrieved) : " << File.basename(file,File.extname(file))
            end
            
            if bUnpack == true then    
               unPackFile(destination, file)
            end

         }


      end
            
      return ret
   end
   #-------------------------------------------------------------

   def retrieve_by_name(destination, filename, bDelete = false, bHardlink = false, bUnpack = false)

      if @bRemoteMode == true then
      
         ret = false
      
         if @bListOnly == false then
            ret = remote_retrieve_by_name(filename, destination, bUnpack)
         
            if ret == false then
               return ret
            end
            return true
         else
            ret = remote_list_by_name(filename)
         end
         return ret
      end

      @arrInv  = Array.new

      aFile    = ArchivedFile.find_by_filename(filename)

      if aFile != nil then
         retVal = extractFromArchive(destination, aFile.filetype, aFile.filename, 
                                          aFile.archive_date, bDelete, bHardlink, aFile.path)
         if retVal then
            aFile.last_access_date = Time.now
            aFile.access_counter   = aFile.access_counter + 1
            aFile.save
         end
      
         if bUnpack == true then
            unPackFile(destination, aFile.filename)
         end
         return retVal
      end

      aFile = ArchivedFile.where("filename LIKE ?", "%#{File.basename(filename, ".*")}%")

      @arrInv << aFile

      ret = true

      @arrInv.to_a.each{|arrFiles|
            
         if arrFiles.empty? == true then
            return false
         end
      
         arrFiles.each{|aFile|
            puts aFile.filename
            if @bListOnly == false then
               retVal = extractFromArchive(destination, aFile.filetype, aFile.filename, 
                                          aFile.archive_date, bDelete, bHardlink, aFile.path)

               if retVal then
                  begin
                     aFile.last_access_date = Time.now
                     aFile.access_counter   = aFile.access_counter + 1
                     aFile.save
                  rescue Exception => e
                     puts "Could not update access_counter / access_date for #{aFile.filename}"
                  end
                  
                  if bUnpack == true then    
                     unPackFile(destination, aFile.filename)
                  end
                  
               else
                  ret = false
               end
            end
         }
         
      }

      return ret



#       if @bReport then
#          editor = ARC::ReportEditor.new(Array[aFile])
#          editor.generateReport(@reportFullName)
#       end


   end
   #-------------------------------------------------------------

   def retrieveAll(full_path_target, bDelete = false, bHardLink = false, bUnpack = false)
      @arrInv  = Array.new
      @arrInv  = ArchivedFile.all
      @arrInv  = ArchivedFile.all.order('filename DESC')
      
      retVal = true
      
      @arrInv.each{|aFile|
         puts aFile.name
         if @bListOnly == true then
            next
         end
         ret = self.retrieve_by_name(full_path_target, aFile.filename, bDelete, bHardLink, bUnpack)  
         if ret == false then
            retVal = false
         end
      }
      return retVal      
   end
   #-------------------------------------------------------------

   # Particularly useful when @bListOnly == true
   
   def getLastSearchResult
      return @arrInv
   end
   #-------------------------------------------------------------

private


   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      
      if !ENV['MINARC_ARCHIVE_ROOT'] and @bRemoteMode == false then
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

   def unPackFile(destination, filename)
      if @isDebugMode == true then
         puts "FileRetriever::unPackFile"
         puts destination
         puts filename
      end

      begin
         unpacker = FT_PackageUtils.new(File.basename(filename), "#{destination}", true)
            
         if @isDebugMode == true then
            unpacker.setDebugMode
         end
         unpacker.unpack
      rescue
         puts
         puts "Could not unpack the file #{filename} ! :-("
         puts
         exit(99)
      end
   end

   #-------------------------------------------------------------

   def extractFromArchive(destination, fileType, fileName, archDate, bDelete, bHardlink, path)

      arrEntries = Array.new

      # srcDir = "#{@archiveRoot}/#{path}"
      srcDir = "#{path}".gsub!(' ', '\ ')
      
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
            cmd = "\\ln -f #{path}/#{entry} #{destDir}/#{entry}"
         else
            cmd = "\\cp -f #{path}/#{entry} #{destDir}/#{entry}"
         end

         if @isDebugMode and @logger != nil then
            @logger.debug(cmd)
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
      
         if @logger != nil then
            @logger.info("[ARC_202] Retrieved: #{File.basename(fileName,File.extname(fileName))}")
         else
            puts "(Retrieved) : " << File.basename(fileName,File.extname(fileName))
         end         
         return true
      else

         if @logger != nil then
            @logger.error("[ARC_606] could not retrieve #{File.basename(fileName,File.extname(fileName))} from #{path}/#{entry} to #{destDir}/#{entry} #{'1F480'.hex.chr('UTF-8')}")
         else
            puts "[ARC_606] could not retrieve #{File.basename(fileName,File.extname(fileName))} from #{path}/#{entry} to #{destDir}/#{entry} #{'1F480'.hex.chr('UTF-8')}"
         end

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
