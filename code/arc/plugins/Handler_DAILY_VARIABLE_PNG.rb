#!/usr/bin/env ruby

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

# This class allows minarc to handle METEO CASALE daily variable chart files:
#
#  DAILY_<VARIABLE>_PNG_<STATIONID>
#  DAILY_<VARIABLE>_PNG_CASALE         DAILY_PRESSURE_CASALE_20130310.png
#
#  DAILY_<VNAME1-VNAME2>_PNG_<STATIONID>
#  DAILY_<VNAME1-VNAME2>_PNG_CASALE    
#  DAILY_TEMPERATURE-OUTDOOR_CASALE_20130310.png


require 'cuc/Converters'

include CUC::Converters


class Handler_DAILY_VARIABLE_PNG
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

      if name.include?("DAILY_") == true and name.include?(".png") == true then
         tmp               = @filename.split("_")
         @type             = "#{tmp[0]}_#{tmp[1]}_PNG_#{tmp[2]}"
         aDate             = tmp[3].split(".")[0]
         @start            = self.str2date("#{aDate}T000000")
         @stop             = self.str2date("#{aDate}T235959")
         @generation_date  = @start
         @archive_path     = "#{archRoot}/DAILY_#{tmp[1]}_PNG/#{tmp[2]}/#{tmp[3].slice(0,4)}/#{tmp[3].slice(4,2)}/"
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
