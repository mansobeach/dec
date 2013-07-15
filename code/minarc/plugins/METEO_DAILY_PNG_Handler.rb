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
# Example name : METEO_CASALE_TODAY_wind_direction.png

require 'cuc/Converters'

include CUC::Converters


class METEO_DAILY_PNG_Handler
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
      @archive_path  = ""

      if name.include?("METEO_CASALE") and name.include?(".png") == true then
         tmp = @filename.split("_")

         if tmp[3].include?(".png") == true then
            @type = "DAILY_#{tmp[3].gsub(".png", "").upcase}_PNG"
         else
            @type = "DAILY_#{tmp[3].upcase}_#{tmp[4].gsub(".png", "").upcase}_PNG"
         end

         @start            =  self.str2date(tmp[2])
         @stop             = @start
         @generation_date  = @start
         @archive_path     = "#{archRoot}/#{@type}/#{tmp[2].slice(0,4)}/#{tmp[2].slice(4,2)}"
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
