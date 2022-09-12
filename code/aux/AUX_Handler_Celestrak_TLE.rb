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
      # to distinguish TLE by Celestrak
      @fileVersion = "0000"

      # This needs to become a configuration item
      
      case @target.upcase
         when "NAOS" then convert_NAOS
         when "S3"   then convert_S3
         when "POD"  then convert_POD
         when "KSAT" then convert_KSAT
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
   
   # NAOS1_20220707T000000.tle
   # NS1_OPER_AUX_TLE____20220707T000000_21000101T000000_0001.EOF
   def rename
      if @strValidityStop == nil and @fileType == nil then
         @newName = "#{@mission}_#{@strValidityStart}.#{@extension}"
      else
         @newName = "#{@mission}_#{@fileClass}_#{@fileType}_#{@strValidityStart}_#{@strValidityStop}_#{@fileVersion}.#{@extension}"
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
      @strValidityStart = %Q{#{Date.today.strftime("%Y%m%d")}T000000}
      @strValidityStop  = %Q{#{(Date.today+10).strftime("%Y%m%d")}T000000}
      @mission          = "NS1"
      @fileType         = "AUX_TLE___"
      @extension        = "TXT"
   end
   ## -----------------------------------------------------------
   
   def convert_KSAT
      @strValidityStart = %Q{#{Date.today.strftime("%Y%m%d")}T000000}
      @mission          = "NAOS1"
      @extension        = "tle"
      @strValidityStop  = nil
      @fileType         = nil
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

