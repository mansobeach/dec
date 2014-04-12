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

# This class allows minarc to handle METEO CASALE realtime files.
# REALTIME_XML_<STATIONID>
# REALTIME_XML_CASALE                 REALTIME_CASALE_20130324T041313.xml
# REALTIME_XML_LEON                   REALTIME_LEON_20130324T041313.xml


require 'cuc/Converters'

include CUC::Converters


class Handler_REALTIME_XML
   @type             = ""
   @filename         = ""
   @validated        = false
   @start            = nil
   @stop             = nil
   @generation_date  = nil
   

   attr_reader :archive_path

   # Class constructor
   
   # Name now must be a full_path one
   def initialize (name, destination = nil)
      archRoot       = ENV['MINARC_ARCHIVE_ROOT']
      @filename      = File.basename(name)
      @archive_path  = ""

      if name.include?("REALTIME_") == true then
         tmp               = @filename.split("_")
         @type             = "REALTIME_XML_#{tmp[1]}"
         @start            =  self.str2date(tmp[2])
         @stop             = @start
         @generation_date  = @start
         @archive_path     = "#{archRoot}/REALTIME_XML/#{tmp[1]}/#{tmp[2].slice(0,4)}/#{tmp[2].slice(4,2)}/#{tmp[2].slice(6,2)}"
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
