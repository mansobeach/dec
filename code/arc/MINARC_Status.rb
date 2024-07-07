#!/usr/bin/env ruby

require 'filesize'

module ARC

class MINARC_Status

   #-------------------------------------------------------------   
   
   # Class contructor
   def initialize(filename = nil)
      @filename     = filename
      checkModuleIntegrity
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "FileStatus debug mode is on"
   end
   #-------------------------------------------------------------

   def statusFile
      status
   end
   #-------------------------------------------------------------

   def status
      aFile = queryInventory
      
      if aFile == nil then
         puts "#{@filename} not present in the archive"
         return false
      end
      
      puts "Filename       - #{aFile.filename}"
      puts "Type           - #{aFile.filetype}"
      puts "Path           - #{aFile.path}"
      puts "Size           - #{aFile.size}"
      puts "Original Size  - #{aFile.size_original}"
      puts "Disk usage     - #{aFile.size_in_disk}"
      puts "Start Val      - #{aFile.validity_start}"
      puts "Stop Val       - #{aFile.validity_stop}"
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

   def statusGlobal   

      require 'arc/MINARC_DatabaseModel'

      hResult = Hash.new
      
      arrFiles          = ArchivedFile.all   
      numTotalFiles     = ArchivedFile.count
      lastHourFiles     = ArchivedFile.where('archive_date > ?', 1.hours.ago)
      lastHourCount     = lastHourFiles.count
      puts lastHourCount
      puts ArchivedFile.last
      puts
      puts ArchivedFile.last.archive_date
      puts
      lastArchiveDate   = ArchivedFile.last.archive_date
      sizeOriginal      = Filesize.from("#{arrFiles.sum(:size_original)} B").pretty
      sizefile          = Filesize.from("#{arrFiles.sum(:size)} B").pretty
      sizeInDisk        = Filesize.from("#{arrFiles.sum(:size_in_disk)} B").pretty 
      arrTypes          = ArchivedFile.select(:filetype).distinct
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
      
      if lastHourCount == 0 then
         # ActiveRecord::Base.remove_connection
         puts "No files archived during period"
         return hResult
      end
            
      puts 
            
      arrTypes = ArchivedFile.select(:filetype).distinct
            
      arrTypes.each{|record|
         # puts record.filetype
         
         arrFiles = ArchivedFile.where(filetype: record.filetype).order('archive_date ASC')
         
         puts "#{record.filetype} / #{arrFiles.count} files"
         
         # puts ArchivedFile.all.group(:filetype).count
         
      }
      
      puts
      
      # ActiveRecord::Base.remove_connection
      return hResult
      
   end
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
      
      puts arrFiles.sum(:size_in_disk)
      
      puts arrFiles.first.archive_date
      puts arrFiles.last.archive_date
      puts arrFiles.count
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

      if !ENV['MINARC_ARCHIVE_ROOT'] then
         require 'arc/MINARC_DatabaseModel'
      end

      if bCheckOK == false or bDefined == false then
         puts("FileDeleter::checkModuleIntegrity FAILED !\n\n")
         exit(99)
      end

      @archiveRoot = ENV['MINARC_ARCHIVE_ROOT']
      return
   end
   #-------------------------------------------------------------

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
   ## -----------------------------------------------------------

end # class

end # module
#=====================================================================


#-----------------------------------------------------------


