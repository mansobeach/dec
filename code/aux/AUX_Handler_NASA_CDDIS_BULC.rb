#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_NASA_CDDIS_BULC class
###
### === Written by DEIMOS Space S.L.
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_NASA_CDDIS_BULC.rb,v 1.21 
###
### Module AUX management
### 
###
#########################################################################

### NASA CDDIS Bulletin C
### https://cddis.nasa.gov/archive/products/iers/tai-utc.dat

require 'aux/AUX_Handler_Generic'

module AUX

AUX_Pattern_NASA_CDDIS_BULC = "tai-utc.dat"

class AUX_Handler_NASA_CDDIS_BULC < AUX_Handler_Generic
   
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)
      @target = target
      
      super(full_path, dir, logger, isDebug)
      
      # This needs to become a configuration item
      
      case @target.upcase
         when "NAOS" then convert_NAOS
         when "S2"   then convert_S2
         when "S3"   then convert_S3
         when "POD"  then convert_POD
         else raise "#{@target.upcase} not supported"
      end

   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("AUX_Handler_NASA_CDDIS_BULC debug mode is on")
   end
   ## -------------------------------------------------------------
   

   # S2__OPER_AUX_UT1UTC_PDMC_YYYYMMDDTHHMMSS_VYYYYMMDDTHHMMSS_YYYYMMDDTHHMMSS.txt
   # S2__OPER_AUX_UT1UTC_PDMC_YYYYMMDDTHHMMSS_VYYYYMMDDTHHMMSS_YYYYMMDDTHHMMSS.txt
   # S2__OPER_AUX_UT1UTC_PDMC_20240513T000000_V20170101T000000_21000101T000000.txt
   # NS1_TEST_AUX_NBULC__20220707T000000_21000101T000000_0001.EOF
   def rename

      case @target.upcase
         when "NAOS" then @newName           = "#{@mission}_#{@fileClass}_#{@fileType}_#{@strValidityStart}_#{@strValidityStop}_#{@fileVersion}.#{@extension}"
         when "S2"   then @newName           = "#{@mission}_#{@fileClass}_#{@fileType}_PDMC_#{@strCreation}_V#{@strValidityStart}_#{@strValidityStop}.#{@extension}"
         else @newName                       = "#{@mission}_#{@fileClass}_#{@fileType}_#{@strValidityStart}_#{@strValidityStop}_#{@fileVersion}.#{@extension}"
      end
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
      @fileType   = "AUX_NBULC_"
      @extension  = "TXT"
   end
   ## -----------------------------------------------------------

   # # S2__OPER_AUX_UT1UTC_PDMC_YYYYMMDDTHHMMSS_VYYYYMMDDTHHMMSS_YYYYMMDDTHHMMSS.txt
   def convert_S2
      @mission    = "S2_"
      @fileType   = "AUX_UT1UTC"
      @extension  = "txt"
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
         @logger.debug("AUX_Handler_NASA_CDDIS_BULC::parse")
      end
      File.readlines(@full_path).each do |line|
         strDate           = line.slice(1,11)
         dateStart         = str2date(strDate)
         @strValidityStart = "#{dateStart.year}#{dateStart.month.to_s.rjust(2, "0")}#{dateStart.day.to_s.rjust(2, "0")}T000000"
      end
      @strValidityStop = "21000101T000000"
   end
   ## -------------------------------------------------------------
      
end # class

end # module

