#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_NASA_CDDIS_BULC class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_NASA_CDDIS_BULC.rb,v 1.21 2013/03/14 13:40:57 bolf Exp $
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
         when "S3"   then convert_S3
         when "POD"  then convert_POD
         else raise "#{@target.upcase} not supported"
      end

   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   ## -------------------------------------------------------------
   
   # NS1_TEST_AUX_NBULC__20220707T000000_21000101T000000_0001.EOF
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
      @fileType   = "AUX_NBULC_"
      @extension  = "TXT"
      parse
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

