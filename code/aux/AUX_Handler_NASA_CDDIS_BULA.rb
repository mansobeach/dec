#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_NASA_CDDIS_BULA class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_NASA_CDDIS_BULA.rb,v 1.21 2013/03/14 13:40:57 bolf Exp $
###
### Module AUX management
### 
###
#########################################################################

### NASA CDDIS Bulletin A
### https://cddis.nasa.gov//archive/products/iers/finals2000A.data

require 'aux/AUX_Handler_Generic'

module AUX

AUX_Pattern_NASA_CDDIS_BULA = "finals2000A.data"

class AUX_Handler_NASA_CDDIS_BULA < AUX_Handler_Generic
   
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)
      @target = target
      
      super(full_path, dir, logger, isDebug)
      
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
   
   # NS1_TEST_AUX_NBULA__20220707T000000_99999999T999999_0001.EOF
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
      @fileType   = "AUX_NBULA_"
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
      bFirstPrediction = false
      File.readlines(@full_path).each do |line|

         if line.slice(16,1) == 'P' and !bFirstPrediction then
            bFirstPrediction = true
            strDate           = line.slice(0,6).gsub!(" ", "0")
            if strDate == nil then
               strDate = line.slice(0,6)
            end
            dateStart         = str2date(strDate)
            @strValidityStart = "#{dateStart.year}#{dateStart.month.to_s.rjust(2, "0")}#{dateStart.day.to_s.rjust(2, "0")}T000000"       
         end

         if line.slice(16,1) == 'P' and bFirstPrediction then
            strDate           = line.slice(0,6).gsub!(" ", "0")
            if strDate == nil then
               strDate = line.slice(0,6)
            end
            dateStop          = str2date(strDate)
            @strValidityStop  = "#{dateStop.year}#{dateStop.month.to_s.rjust(2, "0")}#{dateStop.day.to_s.rjust(2, "0")}T000000"  
         end
         
      end
   end
   ## -------------------------------------------------------------
      
end # class

end # module

