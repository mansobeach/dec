#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_IERS_BULA_ASCII class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_IERS_BULA.rb
###
### Module AUX management
### 
###
#########################################################################

### IERS Bulletin A
### https://datacenter.iers.org/data/latestVersion/bulletinA.txt

### https://datacenter.iers.org/data/xml/bulletina-xxxv-040.xml
### 6 October 2022 Vol. XXXV No. 040
### 2022 - XXXV
### 2021 - XXXIV
### 2020 - XXXIII
### (...)

require 'aux/AUX_Handler_Generic'

module AUX

AUX_Pattern_IERS_BULA_ASCII = "bulletinA.txt"

class AUX_Handler_IERS_BULA_ASCII < AUX_Handler_Generic
   
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
      @logger.debug("AUX_Handler_IERS_BULA_ASCII debug mode is on")
   end
   ## -------------------------------------------------------------
   
   # NS1_TEST_AUX_BULA___20220707T000000_20230706T000000_0001.EOF
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
   
   ## -----------------------------------------------------------
   
   def convert_NAOS
      @mission    = "NS1"
      @fileType   = "AUX_BULA__"
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
         @logger.debug("AUX_Handler_IERS_BULA_ASCII::parse")
      end
      dateStart         = nil
      dateStop          = nil
      bFirstPrediction  = true
      File.readlines(@full_path).each do |line|
         strDate = line.slice(7, 10)
         begin
            someDate         = str2date(strDate)
            if bFirstPrediction == true then
               bFirstPrediction = false
               dateStart = someDate
            end
            dateStop = someDate
         rescue Exception => e
         end
      end
      @strValidityStart = "#{dateStart.year}#{dateStart.month.to_s.rjust(2, "0")}#{dateStart.day.to_s.rjust(2, "0")}T000000"
      @strValidityStop  = "#{dateStop.year}#{dateStop.month.to_s.rjust(2, "0")}#{dateStop.day.to_s.rjust(2, "0")}T000000"
   end
   ## -------------------------------------------------------------
      
end # class

end # module

