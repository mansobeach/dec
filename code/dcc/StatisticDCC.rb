#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #StatisticDCC class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Collector Component
# 
# Git: $Id: StatisticDCC.rb,v 1.29 2008/11/27 13:59:32 decdev Exp $
#
# Module Data Collector Component
#
#########################################################################

require 'filesize'

require 'dec/DEC_DatabaseModel'

module DCC

class StatisticDCC

   # -------------------------------------------------------------   
   
   # Class contructor
   def initialize
      checkModuleIntegrity
      @numFiles   = 0
      @sumSize    = 0
      @hours      = 0
      @rate       = 0
   end
   # -------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "StatisticDCC debug mode is on"
   end
   # -------------------------------------------------------------

   def stats
      hStats = Hash.new
      hStats[:numFiles] = @numFiles
      hStats[:hours]    = @hours
      hStats[:rate]     = "#{Filesize.from(%Q{#{@rate} B}).pretty}/s"
      hStats[:volume]   = Filesize.from("#{@sumSize} B").pretty
      return hStats
   end

   # -------------------------------------------------------------

   def lastHour(iHours = 1)
      @hours            = iHours
      lastHourFiles     = ReceivedFile.all.where('reception_date > ?', iHours.to_i.hours.ago)
      lastHourCount     = lastHourFiles.count
      lastHourSize      = lastHourFiles.sum(:size)
      prettyHourSize    = Filesize.from("#{lastHourSize} B").pretty      
      arrFiles          = Array.new
      
      lastHourFiles.load.to_a.each{|item|
            
         hFile = Hash.new
         hFile[:filename]  = item.filename
         hFile[:interface] = item.interface.name
         hFile[:date]      = item.reception_date
         hFile[:protocol]  = item.protocol
         hFile[:size]      = item.size
         arrFiles << hFile
         @sumSize          = @sumSize + item.size
         @numFiles         = @numFiles + 1
      }
      
      @rate = @sumSize / 3600.0      
      return arrFiles
      
   end
   # -------------------------------------------------------------

   def customQuery
      lastHourFiles     = ReceivedFile.all.where('reception_date > ?', 7.days.ago)
      lastHourCount     = lastHourFiles.count
      lastHourSize      = lastHourFiles.sum(:size)
      prettyHourSize    = Filesize.from("#{lastHourSize} B").pretty
      
      if ReceivedFile.last == nil then
         puts "No files received"
         return
      end
                  
      lastHourFiles     = ReceivedFile.select("filename, interface_id").where('reception_date > ?', 7.days.ago).group(:interface_id, :filename).order('interface_id asc')
      
      puts
      
      lastHourFiles.load.to_a.each{|item|
         puts "#{item.interface.name.to_s.ljust(15)} - #{item.filename}"
      }
      puts

      puts      
      puts "Last received file #{ReceivedFile.last.reception_date}"
      
      puts
      puts "New #{lastHourCount} files received during last 7 days"
      
      puts
      puts "Received #{prettyHourSize}"
      
      puts
      puts
      
   end
   # -------------------------------------------------------------

private


   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
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

end # class

end # module
# =====================================================================

