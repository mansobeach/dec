#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for # class
###
### Module AUX management
### 
###
#########################################################################

### NASA IONEX global ionospheric model / predicted ionospheric maps
###  ftp://gdc.cddis.eosdis.nasa.gov/pub/gps/products/ionex/<YYYY>/<DOY>
##   /pub/gps/products/ionex/2024/169/c2pg1690.24i.Z

require 'date'

require 'aux/AUX_Handler_Generic'
require 'aux/Formatter_SAFE'

module AUX

## pattern is without the compression
AUX_Pattern_NASA_CDDIS_IONEX = "c?pg????.??i"

class AUX_Handler_NASA_CDDIS_IONEX < AUX_Handler_Generic
   
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)
      super(full_path, dir, logger, isDebug)
      @logger.debug("AUX_Handler_NASA_CDDIS_IONEX::initialize")

      extractMetadata

      @safe  = Formatter_SAFE.new(full_path, @newName, target, dir, logger, isDebug)
      
      @logger.debug("AUX_Handler_NASA_CDDIS_IONEX::initialize completed")

   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("AUX_Handler_NASA_CDDIS_IONEX debug mode is on")
   end
   ## -------------------------------------------------------------
   
   def rename
      @newName          = "#{@mission}_#{@fileType}_V#{@strValidityStart}_G#{@strGenerationDate}.#{@extension}"
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

   # "c?pg????.??i"
   def extractMetadata
      @mission             = "S1_"
      valStart             = Date.strptime("#{@filename.slice(9, 2)}#{@filename.slice(4, 3)}", "%y%j")
      valStop              = valStart.next_day(1)
      @fileType            = "AUX_TEC"
      @extension           = "SAFE"
      @strValidityStart    = valStart.strftime("%Y%m%dT%H%M%S")
      @strGenerationDate   = Time.now.strftime("%Y%m%dT%H%M%S")
      @newName             = "#{@mission}_#{@fileType}_V#{@strValidityStart}_G#{@strGenerationDate}.#{@extension}"
   end
   ## -------------------------------------------------------------
   def parse
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_NASA_CDDIS_IONEX::parse")
      end
   end
   ## -------------------------------------------------------------
      
end # class

end # module

