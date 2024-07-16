#!/usr/bin/env ruby

###  OSI-SAF Ice coverage products
##   https://osi-saf.eumetsat.int/

require 'date'
require 'time'

require 'aux/AUX_Handler_Generic'
require 'aux/Formatter_SAFE'

module AUX

## pattern is without the compression
# ice_edge_nh_polstere-100_multi_202406121200.nc
AUX_Pattern_OSISAF_ICE = "ice_edge_?h_polstere-100_multi_*"

class AUX_Handler_OSISAF_ICE < AUX_Handler_Generic
   
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)
      super(full_path, dir, logger, isDebug)
      if isDebug == true then
         @logger.debug("AUX_Handler_OSISAF_ICE::initialize")
      end

      extractMetadata

      @safe  = Formatter_SAFE.new(full_path, @newName, target, dir, logger, isDebug)
      
      if isDebug == true then
         @logger.debug("AUX_Handler_OSISAF_ICE::initialize completed")
      end

   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("AUX_Handler_OSISAF_ICE debug mode is on")
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

   # ice_edge_nh_polstere-100_multi_202406121200.nc
   def extractMetadata
      @mission             = "S1_"
      valStart             = Time.strptime("#{@filename.slice(31, 12)}", "%Y%m%d%H%M")
      valStop              = valStart
      @fileType            = "AUX_ICE"
      @extension           = "SAFE"
      @strValidityStart    = valStart.strftime("%Y%m%dT%H%M%S")
      @strGenerationDate   = Time.strptime("#{@filename.slice(31, 12)}", "%Y%m%d%H%M").strftime("%Y%m%dT%H%M%S")
      @newName             = "#{@mission}_#{@fileType}_V#{@strValidityStart}_G#{@strGenerationDate}.#{@extension}"
   end
   ## -------------------------------------------------------------
   def parse
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_OSISAF_ICE::parse")
      end
   end
   ## -------------------------------------------------------------
      
end # class

end # module

