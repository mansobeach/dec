#!/usr/bin/env ruby


require 'filesize'
require 'json'

require 'arc/MINARC_Client'

module ARC

class FileStatus

   ## -----------------------------------------------------------  
   
   ## Class contructor
   def initialize(filename = nil, bNoServer = true, logger = nil)
      @bRemoteMode = !bNoServer
      @filename    = filename
      
      if ENV['MINARC_SERVER'] and bNoServer == false then
         @bRemoteMode = true
      else
         @bRemoteMode = false
         require 'arc/MINARC_DatabaseModel'
      end
      
      @logger = logger
      checkModuleIntegrity
   end
   ## -----------------------------------------------------------
   
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      if @logger != nil then
         @logger.debug("FileStatus debug mode is on")
         @logger.debug("Remote mode is #{@bRemoteMode}")
      end
   end
   ## -----------------------------------------------------------

   def statusFileName(filename)
      if @bRemoteMode == true then
      
         arc = ARC::MINARC_Client.new(@logger)
      
         if @isDebugMode == true then
            arc.setDebugMode
         end
         
         return arc.statusFileName(filename)
      
      else
         aFile = queryInventoryByName(filename)
         if aFile == nil then
            return false
         end
         
         if @isDebugMode == true then
            puts "----------------------------------"
            aFile.print_introspection
            puts "----------------------------------"
         end
         return aFile.json_introspection
      end
   end
   #-------------------------------------------------------------

   def status
      aFile = queryInventory
      
      if aFile == nil then
         @logger.debug("#{@filename} not present in the archive")
         return false
      end
      
      puts "Filename       - #{aFile.filename}"
      puts "uuid           - #{aFile.uuid}"
      puts "Type           - #{aFile.filetype}"
      puts "Path           - #{aFile.path}"
      puts "Size           - #{aFile.size}"
      puts "Original Size  - #{aFile.size_original}"
      puts "Disk usage     - #{aFile.size_in_disk}"
      puts "Start Val      - #{aFile.validity_start}"
      puts "Stop Val       - #{aFile.validity_stop}"
      puts "md5            - #{aFile.md5}"
      puts "Archive Date   - #{aFile.archive_date}"
      puts "Last Access    - #{aFile.last_access_date}"
      puts "Num Access     - #{aFile.access_counter}"

#       puts aFile.detection_date
#       puts aFile.archive_date
#       puts aFile.last_access_date
#       puts aFile.info
#       
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------

   # It now reports a hash json-wise
   def statusType(filetype)
      
      require 'arc/MINARC_DatabaseModel'
      
      hResult = Hash.new
      
      # puts ArchivedFile.all.group(:filetype).count
      
      arrFiles = ArchivedFile.where(filetype: filetype).order('archive_date ASC')      
      hResult[:num_files] = arrFiles.count
      puts "Archived #{arrFiles.count} files of type #{filetype}"
      puts
      
      hResult[:last_archive_date] = arrFiles.last.archive_date
      puts "Last archive by #{arrFiles.last.archive_date}" 
      puts
      
      hResult[:first_archive_date] = arrFiles.first.archive_date
      puts "First archive by #{arrFiles.first.archive_date}" 
      puts
      
      hResult[:total_size] = Filesize.from("#{arrFiles.sum(:size)} B").pretty      
      sizefile = Filesize.from("#{arrFiles.sum(:size)} B").pretty
      puts "Size of the files #{sizefile}"
      puts
      
      hResult[:total_size_in_disk] = Filesize.from("#{arrFiles.sum(:size_in_disk)} B").pretty 
      sizedisk = Filesize.from("#{arrFiles.sum(:size_in_disk)} B").pretty 
      puts "Disk occupation #{sizedisk}"
      puts
      
      puts "Ratio #{(arrFiles.sum(:size).to_f/arrFiles.sum(:size_in_disk).to_f)*100}"
      puts
      
      # ActiveRecord::Base.remove_connection
      # ActiveRecord::Base.remove_connection
      
      return hResult
   end
   # -------------------------------------------------------------

   def statusGlobal   
      require 'arc/MINARC_DatabaseModel'

      hResult = Hash.new
      
      begin  
         arrFiles          = ArchivedFile.all   
         numTotalFiles     = ArchivedFile.count
         lastHourFiles     = ArchivedFile.where('archive_date > ?', 1.hours.ago)
         lastArchiveDate   = ArchivedFile.last.archive_date
         arrTypes          = ArchivedFile.select(:filetype).distinct
      rescue Exception => e
         # Archive is likely to be empty
         hResult[:total_size]                = nil
         hResult[:total_size_in_disk]        = nil
         hResult[:total_size_original]       = nil
         hResult[:num_total_files]           = nil
         hResult[:num_files_last_hour]       = nil
         hResult[:num_file_types]            = nil
         hResult[:last_date_archive]         = nil
         hResult[:last_archive_filename]     = nil
         hResult[:last_hour_size_original]   = nil
         hResult[:last_hour_size]            = nil
         hResult[:last_hour_size_in_disk]    = nil
         return hResult.to_json
      end

      lastHourCount     = lastHourFiles.count
      sizeOriginal      = Filesize.from("#{arrFiles.sum(:size_original)} B").pretty
      sizefile          = Filesize.from("#{arrFiles.sum(:size)} B").pretty
      sizeInDisk        = Filesize.from("#{arrFiles.sum(:size_in_disk)} B").pretty 
      
      lastHourSizeO     = lastHourFiles.sum(:size_original)
      lastHourSize      = lastHourFiles.sum(:size)
      lastHourDisk      = lastHourFiles.sum(:size_in_disk)
      prettyHourSizeO   = Filesize.from("#{lastHourSizeO} B").pretty
      prettyHourSize    = Filesize.from("#{lastHourSize} B").pretty
      prettyHourDisk    = Filesize.from("#{lastHourDisk} B").pretty
                 
      hResult[:total_size]                = sizefile
      hResult[:total_size_in_disk]        = sizeInDisk
      hResult[:total_size_original]       = sizeOriginal
      hResult[:num_total_files]           = numTotalFiles
      hResult[:num_files_last_hour]       = lastHourCount
      hResult[:num_file_types]            = arrTypes.length
      hResult[:last_date_archive]         = lastArchiveDate
      hResult[:last_archive_filename]     = ArchivedFile.last.filename
      hResult[:last_hour_size_original]   = prettyHourSizeO
      hResult[:last_hour_size]            = prettyHourSize
      hResult[:last_hour_size_in_disk]    = prettyHourDisk
      
      return hResult.to_json      
   end


   # -------------------------------------------------------------

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

      if !ENV['MINARC_ARCHIVE_ROOT'] and @bRemoteMode == false then
         require 'arc/MINARC_DatabaseModel'
      end

      if bCheckOK == false or bDefined == false then
         puts("FileDeleter::checkModuleIntegrity FAILED !\n\n")
         exit(99)
      end
   end
   # -------------------------------------------------------------

   def queryInventory
      if @filename == nil then
         return nil
      end
   
      aFile = ArchivedFile.find_by_filename(@filename)
      if !aFile then
         aFile = ArchivedFile.where("filename LIKE ?", "%#{File.basename(@filename, ".*")}%") #.to_sql
         
         if aFile == nil then
            puts
            puts "#{@filename} not present in the archive :-|"
            puts
            return false
         else
            return aFile[0]
         end
      end
      return aFile
   end
   # -------------------------------------------------------------
   
   def queryInventoryByName(filename)
      aFile = ArchivedFile.find_by_filename(filename)
      if !aFile then
      
         aFile = ArchivedFile.where("name LIKE ?", "%#{File.basename(filename, ".*")}%") #.to_sql
         
         if aFile == nil then
            puts
            puts "#{filename} not present in the archive :-|"
            puts
            return false
         else
            return aFile[0]
         end
      end
      return aFile   
   end
   # -------------------------------------------------------------
   
   def remote_status_filename(filename)
      if @isDebugMode == true then
         puts "FileStatus::#{__method__.to_s}"
      end
      arc = ARC::MINARC_Client.new(@logger)
      if @isDebugMode == true then
         arc.setDebugMode
      end
            
      ret = arc.statusFileName(filename)

      return ret
            
   end
   # -------------------------------------------------------------

end # class

end # module
#=====================================================================


#-----------------------------------------------------------


