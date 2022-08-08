#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_NASA_MSFC_ForecastSolarFlux class
###
### === Written by DEIMOS Space S.L.
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_NASA_MSFC_ForecastSolarFlux.rb Exp $
###
### Module AUX management
### 
###
#########################################################################

### NASA Earth Science Forecast Solar Flux
### https://www.nasa.gov/msfcsolar
### https://www.nasa.gov/sites/default/files/atoms/files/jun2022f10_prd.txt

require 'aux/AUX_Handler_Generic'

module AUX

AUX_Pattern_NASA_MSFC_ForecastSolarFlux = "*f10_prd.txt"

class AUX_Handler_NASA_MSFC_ForecastSolarFlux < AUX_Handler_Generic
   
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)
      @target = target
      
      super(full_path, dir, logger, isDebug)
      
#      if isDebug == true then
#         setDebugMode
#      end

      case @target.upcase
         when "NAOS" then convert_NAOS
         when "S3"   then convert_S3
         when "POD"  then convert_POD
         else raise "#{@target.upcase} not supported"
      end

   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("AUX_Handler_NASA_MSFC_ForecastSolarFlux debug mode is on")
   end
   ## -------------------------------------------------------------
   
   def rename
      @newName          = "#{@mission}_#{@fileClass}_#{@fileType}_#{@strValidityStart}_#{@strValidityStop}_#{@fileVersion}.#{@extension}"
      super(@newName)
      return @full_path_new
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
   
   def convert_NAOS
      @mission    = "NS1"
      @fileType   = "AUX_SFL___"
      @extension  = "TXT"
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

   def parse
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_NASA_MSFC_ForecastSolarFlux::parse")
      end
      bFirst      = true
      dateStart   = nil
      dateStop    = nil
      File.readlines(@full_path).each do |line|
         if line.slice(0,2) != ' 2' then
            next
         end
         
         strYear  = line.slice(1,4)
         strMonth = line.slice(13,3)

         if bFirst == true then
            dateStart   = str2date("#{strYear}#{strMonth}")
            dateStop    = dateStart
            bFirst      = false
            next
         end
         dateStop  = str2date("#{strYear}#{strMonth}")
      end

      @strValidityStart = "#{dateStart.year}#{dateStart.month.to_s.rjust(2, "0")}01T000000"
      @strValidityStop  = "#{dateStop.year}#{dateStop.month.to_s.rjust(2, "0")}01T000000"

   end
   ## -------------------------------------------------------------
      
end # class

end # module

