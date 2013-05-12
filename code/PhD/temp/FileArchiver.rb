#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileArchiver class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: FileArchiver.rb,v 1.14 2009/03/13 09:21:32 decdev Exp $
#
# module MINARC
#
#########################################################################

require "cuc/DirUtils"
require "cuc/EE_ReadFileName"
require "cuc/FT_PackageUtils"
require "minarc/MINARC_DatabaseModel"
require "minarc/ReportEditor"

module MINARC

class FileArchiver

   include CUC::DirUtils
   #------------------------------------------------  
   
   # Class contructor
   # move : boolean. If true a move is made, otherwise it is moved from source
   # debug: boolean. If true it shows debug info.
   def initialize(bMove = false, bHLink = false, debugMode = false)
      @bMove               = bMove
      @bHLink              = bHLink
      @isDebugMode         = debugMode
      checkModuleIntegrity
   end
   #------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "FileArchiver debug mode is on"
   end
   #------------------------------------------------

   def enableReporting(filePath)
      @bReport = true
      @reportFullName = filePath
   end
   #-------------------------------------------------------------
   
   # Main method of the class.
   def archive(full_path_file, fileType = "", bDelete = false, bUnPack = false, arrAddFields = nil)

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
         puts
         puts "#{fileName} is already archived !"
         return false
      end

      if fileType == "" then
         nameDecoder = nil
         nameDecoder = CUC::EE_ReadFileName.new(fileName)
         fileType    = nil

         # -------------------------------------------------
         # If file-type has not been detected as Earth Explorer
         # Try to see whether it is MIRAS BUFR file
         if nameDecoder.isEarthExplorerFile? == false then
            ret = isType_MIRAS_L1C_BUFR?(fileName)
            
            # ------------------------------------
            # Detected MIRAS BUFR file
            if ret == true then
               fileType = "MIRAS_L1C_BUFR"  
               handler  = ""
               rubylibs = ENV['RUBYLIB'].split(':')
            
               rubylibs.each {|path|
                  if File.exists?("#{path}/minarc/plugins/#{fileType.upcase}_Handler.rb") then
                     handler = "#{fileType.upcase}_Handler"
                     break
                  end
               }

               if handler == "" then
                  puts "Fatal Error in FileArchiver.rb !"
                  puts
                  puts "Could not find handler-file for file-type #{fileType.upcase} :-("
                  puts
                  exit(99)
               end
            
               require "minarc/plugins/#{handler}"
            
               nameDecoderKlass  = eval(handler)
               nameDecoder       = nameDecoderKlass.new(fileName)
            
               if nameDecoder != nil and nameDecoder.isValid == true then
                  type  = nameDecoder.fileType.upcase
                  start = nameDecoder.start_as_dateTime
                  stop  = nameDecoder.stop_as_dateTime
               else
                  puts
                  puts "#{name} could not be identified as a true #{fileType.upcase}"
                  puts
                  puts "FileArchiver was unable to manage #{name} ! :-("
                  puts
                  exit(99)
               end
            else
               puts
               puts "Please specify file-type for non-EE Files !"
               return false
            end
            
            # ------------------------------------
         end
         # -------------------------------------------------
         
         if nameDecoder.fileType == nil or nameDecoder.fileType == "" then
            puts
            puts "Could not identify EE file-type for #{fileName} :-("
            return false
         else
            fileType = nameDecoder.fileType.upcase
            start    = nameDecoder.start_as_dateTime
            stop     = nameDecoder.stop_as_dateTime
         end
      else
         handler  = ""
         rubylibs = ENV['RUBYLIB'].split(':')
         rubylibs.each {|path|
            if File.exists?("#{path}/minarc/plugins/#{fileType.upcase}_Handler.rb") then
               handler = "#{fileType.upcase}_Handler"
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
               start = nameDecoder.start_as_dateTime
               stop  = nameDecoder.stop_as_dateTime
            else
               puts
               puts "The file #{fileName} could not be identified as a valid #{fileType.upcase} file..."
               puts "Unable to store #{fileName} :-("
               return false
            end     
         end
      end

      return store(full_path_file, fileType[0..19], start, stop, bDelete, bUnPack, arrAddFields)

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
   def store(full_path_filename, type, start, stop, bDelete, bUnPack, arrAddFields)
      
      archival_date = Time.now

      if File.directory?(full_path_filename) then
         bIsDir = true
      else
         bIsDir = false
      end
      
      #-------------------------------------------
      # Define destination folder

      destDir =  "#{@archiveRoot}/#{type}"
      destDir << archival_date.strftime("/%Y%m")

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
      # Read file-size in bytes
      
      begin
         if bUnPack then
            sizeInArc = 0
            Dir.new("#{destDir}").each{|f|
               if f != ".." then
                  sizeInArc = sizeInArc + File.size("#{destDir}/#{f}")
               end
            }
         elsif bIsDir then
            sizeInArc = 0
            Dir.new("#{destDir}/#{File.basename(full_path_filename)}").each{|f|
               if f != ".." then
                  sizeInArc = sizeInArc + File.size("#{destDir}/#{File.basename(full_path_filename)}/#{f}")
               end
            }
         else
            sizeInArc = File.size("#{destDir}/#{File.basename(full_path_filename)}");
         end
      rescue Exception => e
         puts
         puts e.to_s
         puts
         sizeInArc = nil
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
         anArchivedFile.filesize       = sizeInArc
         anArchivedFile.basepath       = @archiveRoot

         if start != "" and start != nil then
            anArchivedFile.validity_start = start
         end

         if stop != "" and stop != nil then
            anArchivedFile.validity_stop = stop
         end

         anArchivedFile.save!

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
            cmd = "\\chmod -R 777 #{destDir}"
         elsif bIsDir then
            cmd = "\\chmod -R 777 #{destDir}/#{File.basename(full_path_filename)}"
         else
            cmd = "\\chmod 777 #{destDir}/" << File.basename(full_path_filename)
         end

         system(cmd)

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

      if @isDebugMode == true then
         puts "===================================="
         puts "         NEW FILE ARCHIVING         "
         puts "...................................."
         puts "Source File    -> #{full_path_filename}"
         puts "File-Type      -> #{type}"
         puts "Filesize       -> #{sizeInArc}"
         puts "BasePath       -> #{@archiveRoot}"
         puts "Validity Start -> #{start}"
         puts "Validity Stop  -> #{stop}"
         puts "Archival date  -> #{archival_date}"
         puts "==================================="
      else
         puts "(Archived) : " << anArchivedFile.filename
      end

      return true

   end
   #-------------------------------------------------------------

   # Method to detect if a given file is MIRAS BUFR file
   def isType_MIRAS_L1C_BUFR?(filename)
      if filename.slice(0,5) != "miras" then
         return false
      end
      if File.extname(filename) != ".bufr" then
         return false
      end
      return true
   end
   #-------------------------------------------------------------


end # class

end # module
#=================================================
