#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_Celestrak_SFS class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_Celestrak_SFS.rb,v 
###
### Module AUX management
### 
###
#########################################################################

### Celestrak Space Weather SFS
### https://celestrak.org/SpaceData/SW-Last5Years.txt

require 'aux/AUX_Handler_Generic'

module AUX

AUX_Pattern_Celestrak_SFS = "SW-Last5Years.txt"

class AUX_Handler_Celestrak_SFS < AUX_Handler_Generic
   
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
      @fileType   = "AUX_SFS___"
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
      bStart         = false
      strStartDate   = ""
      strStopDate    = ""
      File.readlines(@full_path).each do |line|
         if line.include?("BEGIN DAILY_PREDICTED") == true then
            # @logger.debug("start daily predicition")
            bStart = true
            next
         end

         if bStart == true then
            strStartDate = line.slice(0,10)
            # @logger.debug(strStartDate)
            bStart = false
         end

         if line.include?("END DAILY_PREDICTED") == true then
            # @logger.debug("end daily predicition")
            # @logger.debug(strStopDate)
            break
         end
         strStopDate = line.slice(0,10)
      end
      @strValidityStart = %Q{#{strStartDate.gsub(" ", "")}T000000}
      @strValidityStop  = %Q{#{strStopDate.gsub(" ", "")}T000000}
   end
   ## -------------------------------------------------------------
      
end # class

end # module

