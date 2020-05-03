#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #StatisticDCC class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Collector Component
# 
# CVS: $Id: StatisticDDC.rb,v 1.29 2008/11/27 13:59:32 decdev Exp $
#
# Module Data Distributor Component
#
#########################################################################

require 'filesize'
require 'json'

require 'dec/DEC_DatabaseModel'

module DDC

class StatisticDDC

   ## -----------------------------------------------------------
   
   # Class contructor
   def initialize
      checkModuleIntegrity
   end
   ## -----------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
   end
   ## -----------------------------------------------------------

   def lastHour(iHours = 1)
      lastHourFiles     = SentFile.all.where('delivery_date > ?', iHours.to_i.hours.ago)#.to_a
      lastHourCount     = lastHourFiles.count
      lastHourSize      = lastHourFiles.sum(:size)
      prettyHourSize    = Filesize.from("#{lastHourSize} B").pretty
      
      if SentFile.last == nil then
         # puts "No files sent"
         return
      end
                  
      lastHourFiles     = SentFile.select("filename, interface_id, interface, delivery_date, size, delivered_using").where('delivery_date > ?', iHours.hours.ago).group(:interface_id, :filename).order('interface_id asc')
      
      arrFiles          = Array.new
      
      lastHourFiles.load.to_a.each{|item|
         hFile = Hash.new
         hFile[:filename]  = item.filename
         hFile[:size]      = item.size
         hFile[:interface] = item.interface
         hFile[:protocol]  = item.delivered_using
         hFile[:date]      = item.delivery_date
         arrFiles << hFile
      }

#      puts      
#      puts "Last sent file #{SentFile.last.delivery_date}"
#      
#      puts
#      puts "New #{lastHourCount} files sent during last #{iHours} hour(s)"
#      
#      puts
#      puts "Sent #{prettyHourSize}"
#      
#      puts
#      puts
      
      return arrFiles
      
   end
   
   ## -----------------------------------------------------------


private

   ## -----------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
   end
   ## -----------------------------------------------------------

end # class

end # module


