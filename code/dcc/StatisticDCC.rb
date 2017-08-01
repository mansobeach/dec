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

   def lastHour(iHours = 1)
      lastHourFiles     = ReceivedFile.all.where('reception_date > ?', iHours.to_i.hours.ago)
      lastHourCount     = lastHourFiles.count
      lastHourSize      = lastHourFiles.sum(:size)
      prettyHourSize    = Filesize.from("#{lastHourSize} B").pretty
      
      if ReceivedFile.last == nil then
         puts "No files received"
         return
      end
                  
      lastHourFiles     = ReceivedFile.select("filename, interface_id").where('reception_date > ?', iHours.hours.ago).group(:interface_id, :filename).order('interface_id asc')
      
      puts
      
      lastHourFiles.load.to_a.each{|item|
         puts "#{item.interface.name.to_s.ljust(15)} - #{item.filename}"
      }
      puts

      puts      
      puts "Last received file #{ReceivedFile.last.reception_date}"
      
      puts
      puts "New #{lastHourCount} files received during last #{iHours} hour(s)"
      
      puts
      puts "Received #{prettyHourSize}"
      
      puts
      puts
      
   end
   #-------------------------------------------------------------

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
   #-------------------------------------------------------------

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


