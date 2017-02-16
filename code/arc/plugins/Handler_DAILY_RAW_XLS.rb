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

# This class allows minarc to handle METEO CASALE Daily files.
# Example name : DAILY_RAW_XLS_<STATIONID>
# DAILY_RAW_XLS_CASALE                DAILY_RAW_CASALE_20130310.xls
# DAILY_RAW_XLS_LEON                  DAILY_RAW_LEON_20130310.xls


require 'cuc/Converters'

include CUC::Converters


class Handler_DAILY_RAW_XLS
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

      if name.include?("DAILY_RAW_") == true then
         tmp = File.basename(@filename, ".xls").split("_")
         @type             = "DAILY_RAW_XLS_#{tmp[2]}"
         @start            = self.str2date(tmp[3])
         @stop             = self.str2date("#{tmp[3]}T235959")
         @generation_date  = @start
         # Path is created with YYYY/MM structure with one file per day
         @archive_path     = "#{archRoot}/DAILY_RAW_XLS/#{tmp[2]}/#{tmp[3].slice(0,4)}/#{tmp[3].slice(4,2)}/"
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
