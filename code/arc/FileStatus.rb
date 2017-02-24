#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileDeleter class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: FileStatus.rb,v 1.8 2008/11/26 12:40:47 decdev Exp $
#
# module MINARC
#
#########################################################################


require "arc/MINARC_DatabaseModel"

module ARC

class FileStatus

   #-------------------------------------------------------------   
   
   # Class contructor
   def initialize(filename)
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

   #-------------------------------------------------------------

   def status
      aFile = queryInventory
      
      if aFile == nil then
         puts "#{@filename} not present in the archive"
         return false
      end
      
      
      puts "Filename     - #{aFile.filename}"
      puts "Type         - #{aFile.filetype}"
      puts "Path         - #{aFile.path}"
      puts "Size         - #{aFile.size}"
      puts "Disk usage   - #{aFile.size_in_disk}"
      puts "Start Val    - #{aFile.validity_start}"
      puts "Stop Val     - #{aFile.validity_stop}"
      puts "Archive Date - #{aFile.archive_date}"
      puts "Last Access  - #{aFile.last_access_date}"
      puts "Num Access   - #{aFile.access_counter}"

#       puts aFile.detection_date
#       puts aFile.archive_date
#       puts aFile.last_access_date
#       puts aFile.info
#       
   end
   #-------------------------------------------------------------


   #-------------------------------------------------------------

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
         puts("FileDeleter::checkModuleIntegrity FAILED !\n\n")
         exit(99)
      end

      @archiveRoot = ENV['MINARC_ARCHIVE_ROOT']
      return
   end
   #-------------------------------------------------------------

   def queryInventory
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
   #-------------------------------------------------------------

end # class

end # module
#=====================================================================


#-----------------------------------------------------------


