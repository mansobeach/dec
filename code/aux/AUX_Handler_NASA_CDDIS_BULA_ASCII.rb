#!/usr/bin/env ruby

### NASA CDDIS Bulletin A
### ftps://cddis.nasa.gov//products/iers/ser7.dat

require 'date'
require 'aux/AUX_Handler_Generic'

require 'aux/Formatter_EOFFS'

module AUX

AUX_Pattern_NASA_CDDIS_BULA_ASCII = "ser7.dat"

class AUX_Handler_NASA_CDDIS_BULA_ASCII < AUX_Handler_Generic
   
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)
      if isDebug == true then
         logger.debug("AUX_Handler_NASA_CDDIS_BULA_ASCII::initialize")
      end

      @target = target
      
      super(full_path, dir, logger, isDebug)
      
      parse

      case @target.upcase
         when "NAOS" then convert_NAOS
         when "S2"   then convert_S2
         when "S3"   then convert_S3
         when "POD"  then convert_POD
         else raise "#{@target.upcase} not supported"
      end

      @eoffs  = Formatter_EOFFS.new(full_path, @newName, target, dir, logger, isDebug)

      if isDebug == true then
         logger.debug("AUX_Handler_NASA_CDDIS_BULA_ASCII::initialize completed")
      end

   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("AUX_Handler_NASA_CDDIS_BULA_ASCII debug mode is on")
   end
   ## -------------------------------------------------------------
   
   ## -------------------------------------------------------------

   def convert
      
   end
   ## -------------------------------------------------------------

private

   @listFiles = nil
   
   ## -----------------------------------------------------------
   
   def convert_NAOS
      raise "not implemented for #{@target}"
   end
   ## -----------------------------------------------------------
   
   # S2__OPER_AUX_UT1UTC_ADG__20191024T000000_V20191025T000000_20201024T000000.TGZ
   def convert_S2
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_NASA_CDDIS_BULA_ASCII::convert_S2 #{Dir.pwd} #{@newName}")
      end
      @strCreation   = self.getCreationDate 
      @mission       = "S2_"
      @fileType      = "AUX_UT1UTC"
      @extension     = "TGZ"
      @newName       = "#{@mission}_#{@fileClass}_#{@fileType}_ADG__#{@strCreation}_V#{@strValidityStart}_#{@strValidityStop}"
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_NASA_CDDIS_BULA_ASCII::convert_S2 #{@newName}")
      end
   end
   ## -------------------------------------------------------------
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
         @logger.debug("AUX_Handler_NASA_CDDIS_BULA_ASCII::parse")
      end
      bFirstPrediction = false
      bEndPrediction   = false
      File.readlines(@full_path).each do |line|
        
         if line.include?("MJD      x(arcsec)   y(arcsec)   UT1-UTC(sec)") then
            bFirstPrediction = true
            next
         end

         if line.include?("These predictions are based on all announced leap seconds.") then
            break
         end

         if bFirstPrediction == true then
            bEndPrediction    = true
            bFirstPrediction  = false
            str               = line.strip!.slice(0,10)
            dateStart         = Date.strptime(str, "%Y  %m %d")
            @strValidityStart = "#{dateStart.year}#{dateStart.month.to_s.rjust(2, "0")}#{dateStart.day.to_s.rjust(2, "0")}T000000"
            next
         end

         if bEndPrediction == true then
            str              = line.strip!.slice(0,10)
            dateStop         = Date.strptime(str, "%Y  %m %d")
            @strValidityStop = "#{dateStop.year}#{dateStop.month.to_s.rjust(2, "0")}#{dateStop.day.to_s.rjust(2, "0")}T000000"
            next
         end

      end
   end
   ## -------------------------------------------------------------
      
end # class

end # module

