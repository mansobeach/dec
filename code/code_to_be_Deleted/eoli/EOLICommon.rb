#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #EOLIDataProcessor module
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> EOLI Client Component
# 
# CVS:
#
# = This module has a set of functions for converting data, etc ... 
#
#########################################################################


module EOLICommon

   #-------------------------------------------------------------
   
   # Convert the EOLI date string YYYY-MM-SS+hh:mm:ss 
   # in a Ruby Time object in UTC.
   def getUTCTime(strEOLIDate)
      aDate  = strEOLIDate
      year   = aDate.slice(0,4).to_i
      month  = aDate.slice(5,2).to_i
      day    = aDate.slice(8,2).to_i
      hour   = aDate.slice(11,2).to_i
      min    = aDate.slice(14,2).to_i
      sec    = aDate.slice(17,2).to_i
      return Time.utc(year, month, day, hour, min, sec)
   end
   #-------------------------------------------------------------
   
   # Get a String with the EOLI Date format
   def getStrTime(utcTime)
      utcTime.utc
      return utcTime.strftime("%Y-%m-%d+%H:%M:%S")
   end
   #-------------------------------------------------------------

   # Get a String with the Earth Explorer Date format
   def getStrUTCTime(atime)
      atime.utc
      return atime.strftime("%Y-%m-%dT%H:%M:%S")
   end
   #-------------------------------------------------------------

   # Get a String with the File UNIX Earth Explorer Date format
   # from a UTC Date
   def getStrUTCEETime(atime)
      atime.utc
      return atime.strftime("%Y%m%dT%H%M%S")
   end
   #-------------------------------------------------------------
   
   # It converts EOLI Date Response YYYY-MM-DD HH:mm:SS.ss
   # into YYYY-MM-DD+HH:mm:SS
   def getStrTime2(strEOLIDate)
      if strEOLIDate.length == 22 then
         return %Q{#{strEOLIDate.slice(0,10)}+#{strEOLIDate.slice(11,8)}}
      else
         return strEOLIDate
      end
   end
   #-------------------------------------------------------------
  
end
