#!/usr/bin/env ruby

require 'benchmark'

require 'json'
require 'cuc/DirUtils'
require 'cuc/Wrapper_md5sum'
require 'cuc/EE_ReadFileName'
require 'cuc/FT_PackageUtils'

require 'arc/MINARC_Client'
require 'arc/FileDeleter'

module ARC

class FileArchiver

   include Benchmark

   include CUC::DirUtils
   ## --------------------------------------------
   
   ## Class contructor
   ## move : boolean. If true a move is made, otherwise it is moved from source
   ## debug: boolean. If true it shows debug info.
   def initialize(bMove = false, bHLink = false, bUpdate = false, bInvOnly = false, bNoServer = true, logger = nil, debugMode = false)
      @bMove               = bMove
      @bHLink              = bHLink
      @bUpdate             = bUpdate
      @bInvOnly            = bInvOnly
      @bIsAlreadyArchived  = false
      @logger              = logger
      @isDebugMode         = debugMode
      @isProfileMode       = false
            
      if ENV['MINARC_SERVER'] and !bNoServer then
         @bRemoteMode = true
      else
         @bRemoteMode = false
         require 'arc/MINARC_DatabaseModel'
      end
      checkModuleIntegrity
   end
   ## --------------------------------------------
   
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      if @logger != nil then
         @logger.debug("FileArchiver debug mode is on")
         @logger.debug("Update mode is #{@bUpdate}")
      else
         puts "FileArchiver debug mode is on"
         puts "Update mode is #{@bUpdate}"
      end
   end
   ## --------------------------------------------

   ## Set the flag for profiling execution time.
   def setProfileMode
      @isProfileMode = true
      puts "FileArchiver profile mode is on"
      puts
   end
   ## --------------------------------------------

   # Main method of the class.
   def bulkarchive(arrFiles, fileType = "", bDelete = false, bUnPack = false,\
               arrAddFields = nil, full_path_location = nil,\
               size = 0, size_in_disk = 0, size_original = 0)
               
      if @bRemoteMode == true then
         puts "FileArchiver::bulkarchive remote not supported yet :-("
         exit(99)
      end

      handler = ""
      rubylibs = ENV['RUBYLIB'].split(':')
      rubylibs.each {|path|
            # puts "#{path}/arc/plugins/#{fileType.upcase}_Handler.rb"
	      name = "#{path}/arc/plugins/Handler_#{fileType.upcase}.rb"
	    
         if File.exists?(name) == true then
            handler = "Handler_#{fileType.upcase}"
            break
         end
      }

      if handler == "" then
         puts
         puts "Could not find handler-file for file-type #{fileType.upcase} ! :-("
         puts
         exit(99)
      end
      
      bInventory = false
         
      require "arc/plugins/#{handler}"
      nameDecoderKlass = eval(handler)
      
      the_archived_file = Array.new
      arrFilesArchived  = Array.new
      arrFilesFailed    = Array.new
      
      arrHFiles         = Array.new
      
      arrArchivedFiles  = Array.new
      arrColumns        = Array.new
      
      # setProfileMode
      
      hParams = Hash.new
      hParams[:logger]        = @logger   
      hParams[:isDebugMode]   = @isDebugMode

      arrFiles.each{|full_path_file|
            
            nameDecoder = nameDecoderKlass.new(full_path_file, nil, hParams)
            
            # --------------------------------------------------------
            
            if nameDecoder != nil and nameDecoder.isValid == true then
               filename          = File.basename(full_path_file)
               fileType          = nameDecoder.fileType.upcase
               start             = nameDecoder.start_as_dateTime
               stop              = nameDecoder.stop_as_dateTime
               path              = nameDecoder.archive_path
               size              = nameDecoder.size
               size_in_disk      = nameDecoder.size_in_disk
               size_original     = nameDecoder.size_original
               newFilename       = nameDecoder.filename
               filename_original = nameDecoder.filename_original
               json_metadata     = JSON.generate(nil)

               if nameDecoder.respond_to?("json_metadata") == true then
                  json_metadata = nameDecoder.json_metadata
               end

               
               puts "Detected #{filename} for bulk import"
                              

               
               hFile = {
                                 :filename            => filename,
                                 :filename_original   => filename_original,
                                 :filetype            => fileType,
                                 :path                => path,
                                 :size                => size,
                                 :size_original       => size_original,
                                 :size_in_disk        => size_in_disk,
                                 :archive_date        => Time.now,
                                 :validity_start      => start,
                                 :validity_stop       => stop,
                                 :json_metadata       => json_metadata

               }
                                                            
               retVal = true
               
               perf = measure {
                  retVal = store(filename_original,
                                    full_path_file, 
                                    fileType, 
                                    start, 
                                    stop, 
                                    bDelete, 
                                    bUnPack, 
                                    arrAddFields, 
                                    path, 
                                    json_metadata,
                                    size, 
                                    size_in_disk, 
                                    size_original,
                                    bInventory
                                    )
               }


               if @isProfileMode == true then
                  puts "store_no_inventory(#{filename} / #{size} bytes) :"
                  puts perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")
                  puts
               end


               if retVal == false then
                  puts "Could not archive #{File.basename(full_path_file)} ! :-("
                  # original full_path_file is added to the array needed for the roll-back.

#                   the_archived_file << full_path_file
#                   arrFilesFailed << the_archived_file
               else
#                   arrFilesArchived << the_archived_file
#                   arrArchivedFiles << archivedFile
                  arrHFiles        << hFile
               end
                      
            else
               puts
               puts "The file #{full_path_file} could not be identified as a valid #{fileType.upcase} file..."
               puts "Unable to store #{full_path_file} :-("
               next
            end     
      
      
      }
            
      perf = measure {
         # ArchivedFile.bulkImport(arrFilesArchived)
         # ArchivedFile.superBulk(arrArchivedFiles, arrColumns)
         ArchivedFile.superBulkSequel_mysql2(arrHFiles)
      }
      
      if @isProfileMode == true then
         # puts "ArchivedFile.bulkImport(#{arrFilesArchived.length} items) :"
         puts "ArchivedFile.superBulkSequel_mysql2(#{arrHFiles.length} items) :"
         puts perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")
         puts
      end
      
      arrFilesFailed.each{|archive_item|
         puts "Rolling archive for #{archive_item[0]}"
         puts "NOT IMPLEMENTED YET ! :0p"
         # to be implemented
      }

      puts "End of superbulk"
      
      exit
            
   end
   
   ## --------------------------------------------------------
   ##
   
   def remote_archive(full_path_file, fileType, bDelete, destination)
      arc = ARC::MINARC_Client.new(@logger, @isDebugMode)
      
      ## the name of the file archived can be changed by the server
      new_file = full_path_file.dup
      
      ret = arc.storeFile(new_file, fileType, bDelete, destination)

      # ------------------------------------------
      #
      # 20190620 - TO BE DEVELOPED
      # The name of the file can be modified at the server
      # therefore an update is needed here

      if ret == true then
         if @logger != nil then
            @logger.info("[ARC_100] Archived: #{File.basename(new_file)}")
         end
      end

      # -------------------------------------------
      # Delete Source file if requested

      if bDelete then
         cmd = "\\rm -rf #{full_path_file}"
#
#  problematic to break tests
#         if @isDebugMode == true then
#            puts cmd
#         end
         retVal = system(cmd)
         if retVal == false then
            puts "WARNING : Could not delete source file ! :-("
            puts full_path_file
            puts
         end
      end
      # -------------------------------------------
      return ret
   end
   
   ## ------------------------------------------------------
   ##
   ## Main method of the class.
   ##
   def archive(full_path_file, \
               fileType = "", \
               bDelete = false, \
               bUnPack = false, \
               arrAddFields = nil, \
               full_path_location = nil, \
               json_metadata = nil, \
               size = 0, \
               size_in_disk = 0, \
               size_original = 0 \
               )
      
      if @bRemoteMode == true then
         return remote_archive(full_path_file, fileType, bDelete, full_path_location)
      end
      
               
      path = ""

      ## -------------------------------
      ## CHECK WHETHER SPECIFIED FILE EXISTS
      if File.exists?(full_path_file) == false then
         raise "#{full_path_file} does not exist ! #{'1F480'.hex.chr('UTF-8')}"
         #return false
      end
      ## -------------------------------
      
      fileName = ""

      if bUnPack == false then
         fileName = File.basename(full_path_file)
      else
         fileName = File.basename(full_path_file, ".*")
      end

      # ----------------------------------------------------
      # 
      # 20170605 - Dirty Patch
      # Optimistic approach to not check previous file
      
      aFile = nil

#       # ----------------------------------------------------
#       # CHECK WHETHER FILE IS NOT ALREADY ARCHIVED
# 
#       perf = measure{
#          aFile = ArchivedFile.find_by_filename(fileName)
#       }
# 
#       if @isDebugMode == true then
#          puts
#          puts "ArchivedFile.find_by_filename(#{fileName}) :"
#          puts perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")
#          puts
#          puts
#       end
#       # ----------------------------------------------------

      # ----------------------------------------------------

      # aFile = ArchivedFile.where(filename: fileName).load

      if aFile != nil then
         puts "#{fileName} was already archived !"
         @bIsAlreadyArchived = true
         if @bUpdate == false then
            return false
         end
         puts "Updating the archive ..."
         delFile = FileDeleter.new(@logger, @isDebugMode)
         if @isDebugMode == true then
            delFile.setDebugMode 
         end
         delFile.delete_by_name(fileName)
      end


      if fileType == "" then
            
         nameDecoder = CUC::EE_ReadFileName.new(fileName)

         if nameDecoder.isEarthExplorerFile? == false then
            puts
            puts "Please specify file-type for non-EE Files !"
            return false
         end

         if nameDecoder.fileType == nil or nameDecoder.fileType == "" then
            puts
            puts "Could not identify EE file-type for #{fileName} :-("
            return false
         else
            fileType = nameDecoder.fileType
            start    = nameDecoder.start_as_dateTime
            stop     = nameDecoder.stop_as_dateTime
         end
      else
         handler = ""

=begin
         rubylibs = ENV['RUBYLIB'].split(':')
         rubylibs.each {|path|
            # puts "#{path}/arc/plugins/#{fileType.upcase}_Handler.rb"
	    name = "#{path}/arc/plugins/Handler_#{fileType.upcase}.rb"
	    
            if File.exists?(name) == true then
               handler = "Handler_#{fileType.upcase}"
               break
            end
         }
=end

         handler = "Handler_#{fileType.upcase}"

         if handler == "" then
            puts
            puts "Could not find handler-file for file-type #{fileType.upcase}..."
            puts "Storing #{fileName} without further processing :-|"
            puts
            fileType = fileType.upcase
            start = ""
            stop  = ""
         else
            require "arc/plugins/#{handler}"
            nameDecoderKlass = eval(handler)
            
            # --------------------------------------------------------
            # 2014-03-24
            # New Interface with plug-ins
            # Now the filename provided is full-path to allow 
            # plug-ins process physically the file if needed
            
            
            # 2018-09-06
            # New interface with plug-ins
            # additional parameter with a hash 
            
            hParams = Hash.new
            
            hParams[:logger]        = @logger
            hParams[:isDebugMode]   = @isDebugMode
            
            if bDelete == true then
               hParams[:bDeleteSource] = bDelete
            end
            
            nameDecoder = nameDecoderKlass.new(full_path_file, full_path_location, hParams)
            
            #
            # --------------------------------------------------------
            
            if nameDecoder != nil and nameDecoder.isValid == true then
               fileType          = nameDecoder.fileType.upcase
               start             = nameDecoder.start_as_dateTime
               stop              = nameDecoder.stop_as_dateTime
               path              = nameDecoder.archive_path
               full_path_file    = nameDecoder.fileName
               size              = nameDecoder.size
               size_in_disk      = nameDecoder.size_in_disk
               size_original     = nameDecoder.size_original
               newFilename       = nameDecoder.filename
               filename_original = nameDecoder.filename_original
               json_metadata     = JSON.generate(nil)

               if nameDecoder.respond_to?("json_metadata") == true then
                  json_metadata = nameDecoder.json_metadata
               end

            else
               puts
               puts "The file #{fileName} could not be identified as a valid #{fileType.upcase} file..."
               puts "Unable to store #{fileName} :-("
               return false
            end     
         end
      end


      if @bInvOnly == true then
               
         md5 = CUC::WrapperMD5SUM.new(full_path_filename).md5
         if @isDebugMode == true then
            @logger.debug("path => #{full_path_filename} / md5 => #{md5}")
         end
      
         perf = measure {
            return inventoryNewFile(filename_original, \
                                    full_path_file, \
                                    fileType, \
                                    start, \
                                    stop, \
                                    arrAddFields, \
                                    path, \
                                    json_metadata, \
                                    size, \
                                    size_in_disk, \
                                    size_original, \
                                    md5)
         }

         if @isDebugMode == true and @logger != nil then
            @logger.debug("inventoryNewFile(#{full_path_file}) :")
            @logger.debug( perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y") )
         end

      end

      retVal = false
      
      
      perf = measure {
         retVal = store(filename_original, \
                              full_path_file, \
                              fileType, \
                              start, \
                              stop, \
                              bDelete, \
                              bUnPack, \
                              arrAddFields, \
                              path, \
                              json_metadata, \
                              size, \
                              size_in_disk, \
                              size_original)
      }
      
      if @isDebugMode == true and @logger != nil then
         @logger.debug("store(#{full_path_file}) :")
         @logger.debug( perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y") )
      end
      
      if retVal == true then
         # code commented since plug-ins can now modify the final filename used for the archive
         # puts "(Archived) : " << fileName
         #puts "(Archived) : " << newFilename
         
         if @logger != nil then
            @logger.info("[ARC_100] Archived: #{File.basename(full_path_file, ".*")}")
         end

      end
      
      
      return retVal

   end
   #------------------------------------------------

   def reallocate(fp_file)
   
      if @bRemoteMode == true then
         puts "FileArchiver::reallocate remote not supported yet :-("
         exit(99)
      end
   
   
      full_path_file = fp_file.dup
      newpath        = File.dirname(full_path_file)
      filename       = File.basename(full_path_file)
                        
      aFile = ArchivedFile.find_by_filename(filename)

      if aFile == nil then
         puts "File #{filename} is not in the Archive"
         return false
      end
     
      if File.exists?(full_path_file) == false then
         puts "Error #{full_path_file} does not exist"
         return false
      end
          
      if aFile.path == newpath then
         puts "#{filename} is already archived in #{newpath}"
         return false
      end
     
      aFile.path = newpath
      
      aFile.save!
      
      return true
   end
   #------------------------------------------------

private

   #-------------------------------------------------------------
   # Check that everything needed by the class is present.
   #-------------------------------------------------------------
   def checkModuleIntegrity
            
      if ENV['MINARC_ARCHIVE_ROOT'] and @bRemoteMode == false then
         @archiveRoot = ENV['MINARC_ARCHIVE_ROOT']
      else
         if @bRemoteMode == false then
            puts
            puts "MINARC_ARCHIVE_ROOT environment variable is not defined !\n"
            puts("FileArchiver::checkModuleIntegrity FAILED !\n\n")
            exit(99)
         end
      end

      if ENV['MINARC_ARCHIVE_ERROR'] and @bRemoteMode == false then
         @archiveError = ENV['MINARC_ARCHIVE_ERROR']
         checkDirectory(@archiveError)
      else
         if @bRemoteMode == false then
            puts
            puts "MINARC_ARCHIVE_ERROR environment variable is not defined !\n"
            puts("FileArchiver::checkModuleIntegrity FAILED !\n\n")
            exit(99)
         end
      end

      if @bHLink == true and @bMove == true then
         raise "Fatal Error in FileArchiver::checkModuleIntegrity / cannot move and hard-link simultaneously"
      end

   end
   # -------------------------------------------------------
   
   
   ## -----------------------------------------------------------
   
   def inventoryNewFile(filename_original,
                        full_path_filename, \
                        type, \
                        start, \
                        stop, \
                        arrAddFields, \
                        path = "", \
                        json_metadata = nil, \
                        size = 0, \
                        size_in_disk = 0, \
                        size_original = 0, \
                        md5 = nil)
  
      archival_date = Time.now
  
      #-------------------------------------------
      # Register the file in the inventory

      begin
         anArchivedFile = ArchivedFile.new
         
         anArchivedFile.name              = File.basename(full_path_filename, ".*")
         anArchivedFile.filename          = File.basename(full_path_filename)
         anArchivedFile.filename_original = filename_original
         anArchivedFile.filetype          = type
         anArchivedFile.archive_date      = archival_date
         anArchivedFile.path              = path
         anArchivedFile.size              = size
         anArchivedFile.size_in_disk      = size_in_disk
         anArchivedFile.size_original     = size_original
         anArchivedFile.json_metadata     = json_metadata
         ## ----------------------------
         ## recover if model is still 1.0
         begin
            if md5 != nil then
               anArchivedFile.md5 = md5
            end
         rescue Exception => e
            @logger.error(e.to_s)
         end
         ## ----------------------------
         
         if start != "" and start != nil then
            anArchivedFile.validity_start = start
         end

         if stop != "" and stop != nil then
            anArchivedFile.validity_stop = stop
         end

         #Treat eventual additional fields
         if arrAddFields != nil and arrAddFields.size >= 2 then
            i=0
            while i <= (arrAddFields.size - 2)
               
               if anArchivedFile.has_attribute?(arrAddFields[i]) then
                  anArchivedFile.update_attribute(arrAddFields[i], arrAddFields[i+1])
               else
                  puts "Attribute '#{arrAddFields[i]}' is not present in the archived_files table !"
                  puts "Going on with archiving..."
               end

               i=i+2 
            end
         end

         anArchivedFile.save!
         
         if @isDebugMode == true then
            @logger.debug("NEW FILE ARCHIVING")
            @logger.debug("Source File       -> #{full_path_filename}")
            @logger.debug("Path Archive      -> #{path}")
            @logger.debug("File-Type         -> #{type}")
            @logger.debug("Validity Start    -> #{start}")
            @logger.debug("Validity Stop     -> #{stop}")
            @logger.debug("Size              -> #{size}")
            @logger.debug("Disk occupation   -> #{size_in_disk}")
            @logger.debug("Metadata          -> #{json_metadata}")
         end      
      rescue Exception => e
         @logger.error(e.to_s)         
         return false
      end  
   
      return true
   end
  
   ## -----------------------------------------------------------
  
   ## ------------------------------------------------------------
   ## Performs the file archiving.
   ## Copies/Moves the source file to the proper directory
   ## Sets access rights
   ## Registers the file in the database
   ## ------------------------------------------------------------
   def store(  filename_original,
               full_path_filename, 
               type, 
               start, 
               stop, 
               bDelete, 
               bUnPack, 
               arrAddFields, 
               path,
               json_metadata, 
               size, 
               size_in_disk, 
               size_original,
               bInventory = true  )
      
      archival_date = Time.now

      if File.directory?(full_path_filename) then
         bIsDir = true
      else
         bIsDir = false
      end
      

      # -------------------------------------------
      # Define destination folder

      destDir =  "#{@archiveRoot}/#{type}"

      if path != "" then
         destDir = "#{path}"
      else
         destDir << archival_date.strftime("/%Y%m")
      end

#       if bUnPack then         
#          destDir << "/" << File.basename(full_path_filename, ".*")
#       end

      # Copy / Move the source file to the archive

      checkDirectory(destDir)

      if @bHLink then

         
         
         if File.directory?(full_path_filename) == true then
         
            checkDirectory("#{destDir}/#{File.basename(full_path_filename, ".*")}")
         
            prevDir = Dir.pwd
            Dir.chdir(full_path_filename)
            arrFiles = Dir["*"]
      
            bRetVal = true
            
            arrFiles.each {|entry|
               cmd = "\\ln -f #{full_path_filename}/#{entry} #{destDir}/#{File.basename(full_path_filename, ".*")}/#{entry}"

               if @isDebugMode and @logger != nil then
                  @logger.debug(cmd)
               end
         
               tmpVal = system(cmd)

               if tmpVal == false then
                  puts
                  puts "Could not hard-link #{full_path_filename}/#{entry} to the Archive ! :-("
                  puts
               end

               if bRetVal then
                  bRetVal = tmpVal
               end
            }
            
            Dir.chdir(prevDir)

            if bRetVal == false then
               return false
            end

         else
            cmd = "\\ln -f \"#{full_path_filename}\" \"#{destDir}\""
        
            if @isDebugMode then
               puts cmd
            end

            ret = system(cmd)

            if ret == false then
               puts
               puts "Could not hard-link #{full_path_filename} to the Archive ! :-("
               puts
               return false
            end
         end
      else
         if @bMove then
            cmd = "\\mv -f \"#{full_path_filename}\" \"#{destDir}/\""
         else
            cmd = "\\cp -Rf \"#{full_path_filename}\" \"#{destDir}/\""
         end

         if @isDebugMode then
            puts cmd
         end

         ret = system(cmd)

         if ret == false then
            puts
            puts "Could not copy / Move #{full_path_filename} to the Archive ! :-("
            puts
            return false
         end
      end
      
      #-------------------------------------------
      # Unpack the file

      begin
         if bUnPack then
            unpacker = FT_PackageUtils.new(File.basename(full_path_filename), "#{destDir}", true)
            if @isDebugMode then
               unpacker.setDebugMode
            end
            unpacker.unpack
         end
      rescue
         puts
         puts "Could not unpack the file, rolling back ! :-("
         
         cmd = "\\rm -rf #{destDir}"

         ret = system(cmd)

         if ret == false then
            puts
            puts "Could not rollback ! Leaving MINARC in possible incoherent state :-("
            puts
         end
   
         return false 
      end

      ## -------------------------------------------
      ## Set access rights (read only)

      if bUnPack then
         cmd = "\\chmod 555 #{destDir}; chmod 444 #{destDir}/*"
      elsif bIsDir then
         cmd = "\\chmod 555 #{destDir}/#{File.basename(full_path_filename)}; chmod 444 #{destDir}/#{File.basename(full_path_filename)}/*"
      else
         cmd = "chmod 744 #{destDir}; \\chmod 444 #{destDir}/" << File.basename(full_path_filename)
      end
      
      ## -------------------------------------------


      if @isDebugMode == true and @logger != nil then
         @logger.debug(cmd)
      end
      
      ret = system(cmd)

      if ret == false then
         logger.warn("Could not set access rights to the archived file ! :-(")
      end      

      ## -------------------------------------------
      ## Register the file in the inventory

      retVal = true


      if bInventory == true then

         md5 = CUC::WrapperMD5SUM.new("#{destDir}/#{File.basename(full_path_filename)}").md5
      
         if @isDebugMode == true then
            @logger.debug("MD5 => #{destDir}/#{File.basename(full_path_filename)} / #{md5}")
         end
         
         perf = measure {
            retVal = inventoryNewFile(filename_original, \
                                       full_path_filename, \
                                       type, \
                                       start, \
                                       stop, \
                                       arrAddFields, \
                                       path, \
                                       json_metadata, \
                                       size, \
                                       size_in_disk, \
                                       size_original, \
                                       md5)
         }
      
         if @isDebugMode == true and @logger != nil then
            @logger.debug("inventoryNewFile(#{full_path_filename}) :")
            @logger.debug( perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y") )
         end

         ## ------------------------------------------------------ 
         ## If could not store in the database (likely duplication)
         ## file is already at 
         if retVal == false then
            if @isDebugMode and @logger != nil then
               @logger.debug("Copying file #{File.basename(full_path_filename)} into ERROR area ")
            end
            if @bMove == true then
               cmd = "\\cp -f #{destDir}/#{File.basename(full_path_filename)} #{@archiveError}/"
               if @isDebugMode and @logger != nil then
                  @logger.debug(cmd)
               end
               system(cmd)
            else
               cmd = "\\mv -f #{full_path_filename} #{@archiveError}/"
               if @isDebugMode and @logger != nil then
                  @logger.debug(cmd)
               end
               system(cmd)
            end

            return false
         end

         ## -----------------------------------------------------

      end
       
      #-------------------------------------------
      # Delete Source file if requested

      if bDelete then
         cmd = "\\rm -rf #{full_path_filename}"
         ret = system(cmd)
         if ret == false then
            puts "WARNING : Could not delete source file ! :-("
         end
      end
      return true
   end

   #--------------------------------------------------------

end ## class

end ## module

