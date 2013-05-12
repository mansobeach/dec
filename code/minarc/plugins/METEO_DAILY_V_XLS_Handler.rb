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
# Example name : METEO_CASALE_20120325T154814.xml

require 'cuc/Converters'

include CUC::Converters


class METEO_DAILY_V_XLS_Handler
   @type             = ""
   @filename         = ""
   @validated        = false
   @start            = nil
   @stop             = nil
   @generation_date  = nil
   

   attr_reader :archive_path

   # Class constructor
   def initialize (name)
      archRoot       = ENV['MINARC_ARCHIVE_ROOT']
      @filename      = name
      @type          = "METEO_DAILY_V_XLS"
      @archive_path  = ""

      if name.include?("EXCEL_METEO_CASALE_V") == true then
         tmp = File.basename(@filename, ".xls").split("_")
         @start            = self.str2date(tmp[4])
         @stop             = self.str2date("#{tmp[4]}T235959")
         @generation_date  = @start
         # Path is created with YYYY/MM structure with one file per day
         @archive_path     = "#{archRoot}/#{@type}/#{tmp[4].slice(0,4)}/#{tmp[4].slice(4,2)}/"
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
