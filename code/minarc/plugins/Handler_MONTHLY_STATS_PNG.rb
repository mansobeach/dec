#!/usr/bin/ruby

#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#
#########################################################################

# This class allows minarc to handle METEO CASALE Excel Monthly files.
#
# MONTHLY_STATS_<VARIABLE>_PNG_<STATIONID> 
# MONTHLY_STATS_<VNAME1-VNAME2>_PNG_<STATIONID> 
#
# Example name : MONTHLY_STATS_TEMPERATURE-OUTDOOR_PNG_CASALE_201302.PNG

require 'cuc/Converters'

include CUC::Converters


class Handler_MONTHLY_STATS_PNG
   @type             = ""
   @filename         = ""
   @validated        = false
   @start            = nil
   @stop             = nil
   @generation_date  = nil
   

   attr_reader :archive_path

   # Class constructor
   def initialize (name, destination = nil)
      archRoot       = ENV['MINARC_ARCHIVE_ROOT']
      @filename      = name
      @archive_path  = ""

      if name.include?("MONTHLY_STATS") and name.include?(".png") == true then
         tmp = @filename.split("_")
         theDate  = tmp[5].gsub(".png", "")
         @start   = self.str2date(theDate)
         year     = theDate.slice(0,4)
         month    = theDate.slice(4,2)
         day      = Time.days_in_month(month.to_i, year.to_i).to_s
         theDate  = "#{year}#{month}#{day}T235959"
         @stop    = self.str2date(theDate)

         @type          = "#{tmp[0]}_#{tmp[1]}_#{tmp[2]}_#{tmp[3]}_#{tmp[4]}"
         @archive_path  = "#{archRoot}/#{tmp[0]}_#{tmp[1]}_#{tmp[2]}_#{tmp[3]}/#{tmp[4]}/#{year}"
         
         @generation_date  = Time.now
         @validated        = true
      else
         @validated = false
         return   
      end
   end

   def isValid
      return @validated
   end

   def fileType
      return @type
   end

   def start_as_dateTime
      return @start
   end

   def stop_as_dateTime
      return @stop
   end

   def generationDate
      return @generation_date
   end
end
