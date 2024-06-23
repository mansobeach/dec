#!/usr/bin/env ruby

###  IFREMER WAVEWATCH III model
##   ftp://ftp.ifremer.fr/ifremer/cersat/products/gridded/wavewatch3/HINDCAST/README
##   https://polar.ncep.noaa.gov/waves/wavewatch/
##   https://polar.ncep.noaa.gov/waves/products2.shtml?

require 'date'
require 'time'

require 'aux/AUX_Handler_Generic'
require 'aux/Formatter_SAFE'

module AUX

## pattern is without the compression
# IFR_WW3-GLOBAL-30MIN_20240623T09_G2024-06-17T13.nc
AUX_Pattern_IFREMER_WAVEWATCH_III = "IFR_WW3-GLOBAL-30MIN_*_G*.nc"

class AUX_Handler_IFREMER_WAVEWATCH_III < AUX_Handler_Generic
   
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)
      super(full_path, dir, logger, isDebug)
      if isDebug == true then
         @logger.debug("AUX_Handler_IFREMER_WAVEWATCH_III::initialize")
      end

      extractMetadata

      @safe  = Formatter_SAFE.new(full_path, @newName, target, dir, logger, isDebug)
      
      if isDebug == true then
         @logger.debug("AUX_Handler_IFREMER_WAVEWATCH_III::initialize completed")
      end

   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("AUX_Handler_IFREMER_WAVEWATCH_III debug mode is on")
   end
   ## -------------------------------------------------------------
   
   def rename
      @newName    = "#{@mission}_#{@fileType}_V#{@strValidityStart}_G#{@strGenerationDate}.#{@extension}"
      return
   end
   ## -------------------------------------------------------------

   def convert
      @strCreation = self.getCreationDate 
      parse
      return rename
   end
   ## -------------------------------------------------------------

private

   @listFiles = nil
   
   ## -----------------------------------------------------------
   
   def convert_S1
   end
   ## -----------------------------------------------------------

   def convert_S3
      raise "not implemented for #{@target}"
   end
   ## -------------------------------------------------------------

   def convert_POD
      raise "not implemented for #{@target}"
   end
   ## -------------------------------------------------------------

   # IFR_WW3-GLOBAL-30MIN_20240302T00_G2024-02-27T01.nc
   def extractMetadata
      @mission             = "S1_"
      valStart             = Time.strptime("#{@filename.slice(21, 11)}", "%Y%m%dT%H")
      valStop              = valStart
      @fileType            = "AUX_WAV"
      @extension           = "SAFE"
      @strValidityStart    = valStart.strftime("%Y%m%dT%H%M%S")
      @strGenerationDate   = Time.strptime("#{@filename.slice(34, 13)}", "%Y-%m-%dT%H").strftime("%Y%m%dT%H%M%S")
      @newName             = "#{@mission}_#{@fileType}_V#{@strValidityStart}_G#{@strGenerationDate}.#{@extension}"
   end
   ## -------------------------------------------------------------
   def parse
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_IFREMER_WAVEWATCH_III::parse")
      end
   end
   ## -------------------------------------------------------------
      
end # class

end # module

