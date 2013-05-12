#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileArchiver class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: FileArchiver.rb,v 1.12 2008/09/24 16:09:19 decdev Exp $
#
# module MINARC
#
#########################################################################

require 'cuc/DirUtils'
require 'cuc/EE_ReadFileName'
require 'cuc/FT_PackageUtils'
require 'minarc/MINARC_DatabaseModel'
require 'minarc/FileDeleter'

module MINARC

class FileArchiver

   include CUC::DirUtils
   #------------------------------------------------  
   
   # Class contructor
   # move : boolean. If true a move is made, otherwise it is moved from source
   # debug: boolean. If true it shows debug info.
   def initialize(bMove = false, bHLink = false, bUpdate = false, debugMode = false)
      @bMove               = bMove
      @bHLink              = bHLink
      @bUpdate             = bUpdate
      @bIsAlreadyArchived  = false
      @isDebugMode         = debugMode
      checkModuleIntegrity
   end
   #------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "FileArchiver debug mode is on"
      puts "Update mode is #{@bUpdate}"
   end
   #------------------------------------------------

   # Main method of the class.
   def archive(full_path_file, fileType = "", bDelete = false, bUnPack = false, arrAddFields = nil)
      path = ""

      # CHECK WHETHER SPECIFIED FILE EXISTS
      if File.exists?(full_path_file) == false then
         puts
         puts "#{full_path_file} does not exist ! :-("
         return false
      end

      fileName = ""

      if bUnPack == false then
         fileName = File.basename(full_path_file)
      else
         fileName = File.basename(full_path_file, ".*")
      end

      # CHECK WHETHER FILE IS NOT ALREADY ARCHIVED

      aFile = ArchivedFile.find_by_filename(fileName)

      if aFile != nil then
         puts "#{fileName} was already archived !"
         @bIsAlreadyArchived = true
         if @bUpdate == false then
            return false
         end
         puts "Updating the archive ..."
         delFile = FileDeleter.new
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
         rubylibs = ENV['RUBYLIB'].split(':')
         rubylibs.each {|path|
            # puts "#{path}/minarc/plugins/#{fileType.upcase}_Handler.rb"
	    name = "#{path}/minarc/plugins/Handler_#{fileType.upcase}.rb"
	    
            if File.exists?(name) == true then
               handler = "Handler_#{fileType.upcase}"
               break
            end
         }

         if handler == "" then
            puts
            puts "Could not find handler-file for file-type #{fileType.upcase}..."
            puts "Storing #{fileName} without further processing :-|"
            puts
            fileType = fileType.upcase
            start = ""
            stop  = ""
         else
            require "minarc/plugins/#{handler}"
            nameDecoderKlass = eval(handler)
            nameDecoder = nameDecoderKlass.new(fileName)
            
            if nameDecoder != nil and nameDecoder.isValid == true then
               fileType = nameDecoder.fileType.upcase
               start    = nameDecoder.start_as_dateTime
               stop     = nameDecoder.stop_as_dateTime
               path     = nameDecoder.archive_path
            else
               puts
               puts "The file #{fileName} could not be identified as a valid #{fileType.upcase} file..."
               puts "Unable to store #{fileName} :-("
               return false
            end     
         end
      end

      return store(full_path_file, fileType[0..19], start, stop, bDelete, bUnPack, arrAddFields, path)

   end
   #------------------------------------------------

private

   #-------------------------------------------------------------
   # Check that everything needed by the class is present.
   #-------------------------------------------------------------
   def checkModuleIntegrity
      
      if ENV['MINARC_ARCHIVE_ROOT'] then
         @archiveRoot = ENV['MINARC_ARCHIVE_ROOT']
      else
         puts
         puts "MINARC_ARCHIVE_ROOT environment variable is not defined !\n"
         puts("FileArchiver::checkModuleIntegrity FAILED !\n\n")
         exit(99)
      end

      if @bHLink == true and @bMove == true then
         puts "\nFatal Error in FileArchiver::checkModuleIntegrity"
         puts
         puts "Cannot move and hard-link simultaneously"
         puts
         puts
         exit(99)
      end

   end


   #-------------------------------------------------------------
   # Performs the file archiving.
   # Copies/Moves the source file to the proper directory
   # Sets access rights
   # Registers the file in the database
   #-------------------------------------------------------------
   def store(full_path_filename, type, start, stop, bDelete, bUnPack, arrAddFields, path = "")
      
      archival_date = Time.now

      if File.directory?(full_path_filename) then
         bIsDir = true
      else
         bIsDir = false
      end
      
      if @isDebugMode == true then
         puts "===================================="
         if @bIsAlreadyArchived == false then
            puts "         NEW FILE ARCHIVING         "
         else
            puts "         UPDATE ARCHIVED FILE       "
         end
         puts "...................................."
         puts "Source File    -> #{full_path_filename}"
         puts "File-Type      -> #{type}"
         puts "Validity Start -> #{start}"
         puts "Validity Stop  -> #{stop}"
         puts "Archival date  -> #{archival_date}"
         puts "==================================="
      end

      #-------------------------------------------
      # Define destination folder

      destDir =  "#{@archiveRoot}/#{type}"

      if path != "" then
         destDir = "#{path}"
      else
         destDir << archival_date.strftime("/%Y%m")
      end

      if bUnPack then         
         destDir << "/" << File.basename(full_path_filename, ".*")
      end

      #-------------------------------------------
      # Copy / Move the source file to the archive

      checkDirectory(destDir)

      if @bHLink then

         checkDirectory("#{destDir}/#{File.basename(full_path_filename, ".*")}")
         
         if File.directory?(full_path_filename) == true then
            prevDir = Dir.pwd
            Dir.chdir(full_path_filename)
            arrFiles = Dir["*"]
      
            bRetVal = true
            
            arrFiles.each {|entry|
               cmd = "\\ln -f #{full_path_filename}/#{entry} #{destDir}/#{File.basename(full_path_filename, ".*")}/#{entry}"

               if @isDebugMode then
                  puts
                  puts cmd
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
            cmd = "\\ln -f #{full_path_filename} #{destDir}"
        
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
            cmd = "\\mv -f #{full_path_filename} #{destDir}"
         else
            cmd = "\\cp -Rf #{full_path_filename} #{destDir}"
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

      #-------------------------------------------
      # Set access rights (read only)

      if bUnPack then
         cmd = "\\chmod 555 #{destDir}; chmod 444 #{destDir}/*"
      elsif bIsDir then
         cmd = "\\chmod 555 #{destDir}/#{File.basename(full_path_filename)}; chmod 444 #{destDir}/#{File.basename(full_path_filename)}/*"
      else
         cmd = "\\chmod 444 #{destDir}/" << File.basename(full_path_filename)
      end

      if @isDebugMode then
         puts cmd
      end
      

      ret = system(cmd)

      if ret == false then
         puts "WARNING : Could not set access rights to the archived file ! :-("
      end      

      #-------------------------------------------
      # Register the file in the inventory

      begin
         anArchivedFile = ArchivedFile.new
         if bUnPack then
            anArchivedFile.filename       = File.basename(full_path_filename, ".*")
         else
            anArchivedFile.filename       = File.basename(full_path_filename)
         end

         anArchivedFile.filetype       = type
         anArchivedFile.archive_date   = archival_date
         anArchivedFile.path           = path

         if start != "" and start != nil then
            anArchivedFile.validity_start = start
         end

         if stop != "" and stop != nil then
            anArchivedFile.validity_stop = stop
         end

         anArchivedFile.save!

#          bInventoried = false
# 
#          while not bInventoried
#             begin
#                anArchivedFile.save!
#                bInventoried = true
#             rescue
#                puts "MINARC::FileArchiver - could not inventory #{anArchivedFile.filename}"
#                sleep(1)
#                bInventoried = true
#             end
#          end

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

      rescue Exception => e
         puts
         puts e.to_s
         puts
         puts "Could not inventory #{anArchivedFile.filename}, rolling back ! :-("
         puts

         if bUnPack then
            cmd = "\\rm -rf #{destDir}"
         else
            cmd = "\\rm -rf #{destDir}/" << File.basename(full_path_filename)
         end

         ret = system(cmd)

         if ret == false then
            puts
            puts "Could not rollback ! Leaving MINARC in possible incoherent state :-("
            puts
         end        

         return false
      end
      
      #-------------------------------------------
      # Delete Source file if requested

      if bDelete then
         cmd = "\\rm -rf #{full_path_filename}"
         if @isDebugMode then
            puts cmd
         end
         ret = system(cmd)

         if ret == false then
            puts "WARNING : Could not delete source file ! :-("
         end
      end

      puts "(Archived) : " << anArchivedFile.filename

      return true

   end

end # class

end # module
#=================================================
