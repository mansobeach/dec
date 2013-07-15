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
# Example name : METEO_MONTHLY_STATS_temperature_outdoor_201302.xls

require 'cuc/Converters'

include CUC::Converters


class METEO_MONTHLY_XLS_Handler
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

      if name.include?("METEO_MONTHLY_STATS") and name.include?(".xls") == true then
         tmp = @filename.split("_")

         if tmp[4].include?(".xls") == true then
            @type    = "MONTHLY_#{tmp[3].gsub(".xls", "").upcase}_XLS"
            @start   = self.str2date(tmp[4].gsub(".xls", ""))
            theDate  = tmp[4].gsub(".xls", "")
         else
            @type    = "MONTHLY_#{tmp[3].upcase}_#{tmp[4].upcase}_XLS"
            @start   = self.str2date(tmp[5].gsub(".xls", ""))
            theDate  = tmp[5].gsub(".xls", "")
         end

#          puts tmp[3]
#          puts tmp[4]
#          puts tmp[5]
#          puts @type

         year     = theDate.slice(0,4)
         month    = theDate.slice(4,2)
         day      = Time.days_in_month(month.to_i, year.to_i).to_s
         theDate  = "#{year}#{month}#{day}T235959"

         @stop             = self.str2date(theDate)
         @generation_date  = Time.now
         @archive_path     = "#{archRoot}/#{@type}/#{year}"
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
