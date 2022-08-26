#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_Celestrak_TLE class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_Celestrak_TLE.rb,v 
###
### Module AUX management
### 
###
#########################################################################

### Celestrak TLE

require 'aux/AUX_Handler_Generic'

module AUX

AUX_Pattern_Celestrak_TLE = "*CATNR=?????"

class AUX_Handler_Celestrak_TLE < AUX_Handler_Generic
   
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)
      @target = target
      
      super(full_path, dir, logger, isDebug)
      
      # Override the fileversion into "0000"
      @fileVersion = "0000"

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
      @logger.debug("AUX_Handler_Celestrak_TLE debug mode is on")
   end
   ## -------------------------------------------------------------
   
   # NS1_TEST_AUX_TLE____20220707T000000_21000101T000000_0000.EOF
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
      @strValidityStart = %Q{#{Date.today.strftime("%Y%m%d")}T000000}
      @strValidityStop  = %Q{#{(Date.today+10).strftime("%Y%m%d")}T000000}
      @mission          = "NS1"
      @fileType         = "AUX_TLE___"
      @extension        = "TXT"
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
         @logger.debug("AUX_Handler_Celestrak_TLE::parse")
      end
   end
   ## -------------------------------------------------------------
      
end # class

end # module

