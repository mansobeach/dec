#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #StatisticDCC class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Collector Component
# 
# CVS: $Id: StatisticDCC.rb,v 1.29 2008/11/27 13:59:32 decdev Exp $
#
# Module Data Collector Component
# This class polls a given Interface and gets all registered available files
# via FTP or SFTP.
#
#########################################################################

require 'filesize'

require 'dbm/DatabaseModel'

module DCC

class StatisticDCC

   #-------------------------------------------------------------   
   
   # Class contructor
   def initialize
      checkModuleIntegrity
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "StatisticDCC debug mode is on"
   end
   #-------------------------------------------------------------

   #-------------------------------------------------------------

   def lastHour
      lastHourFiles     = ReceivedFile.where('reception_date > ?', 1.hours.ago)
      lastHourCount     = lastHourFiles.count
      lastHourSize      = lastHourFiles.sum(:size)
      prettyHourSize    = Filesize.from("#{lastHourSize} B").pretty
      
      if ReceivedFile.last == nil then
         puts "No files received"
         return
      end
            
      puts      
      puts "Last received file #{ReceivedFile.last.reception_date}"
      
      puts
      puts "New #{lastHourCount} files received during last hour"
      
      puts
      puts "Received #{prettyHourSize}"
      
      puts  
      puts "Total received #{ReceivedFile.count} files"
      
#       puts 
#             
#       arrTypes = ArchivedFile.select(:filetype).distinct
#             
#       arrTypes.each{|record|
#          # puts record.filetype
#          
#          arrFiles = ArchivedFile.where(filetype: record.filetype).order('archive_date ASC')
#          
#          puts "#{record.filetype} / #{arrFiles.count} files"
#          
#          # puts ArchivedFile.all.group(:filetype).count
#          
#       }
#       
#       puts
      
   end
   #-------------------------------------------------------------

   def statusType(filetype)
      # puts ArchivedFile.all.group(:filetype).count
      
      arrFiles = ArchivedFile.where(filetype: filetype).order('archive_date ASC')
      
      puts "Archived #{arrFiles.count} files of type #{filetype}"
      
      puts
      
      puts "Last archive by #{arrFiles.last.archive_date}" 
      
      puts
      
      puts "First archive by #{arrFiles.first.archive_date}" 
      
      puts
            
      sizefile = Filesize.from("#{arrFiles.sum(:size)} B").pretty 
      
      puts "Size of the files #{sizefile}"
      
      puts
      
      sizedisk = Filesize.from("#{arrFiles.sum(:size_in_disk)} B").pretty 
      
      puts "Disk occupation #{sizedisk}"
      
      puts
      
      puts "Ratio #{(arrFiles.sum(:size).to_f/arrFiles.sum(:size_in_disk).to_f)*100}"
      
      puts
      
      return
      
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
   #-------------------------------------------------------------

end # class

end # module
#=====================================================================


#-----------------------------------------------------------


