#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_NOAA_RSGA_Daily class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_NOAA_RSGA_Daily.rb,v 1.21 2013/03/14 13:40:57 bolf Exp $
###
### Module AUX management
### 
###
#########################################################################

### curl ftp://ftp.swpc.noaa.gov/pub/latest/README

### RSGA / Report Solar Geophysical Activity

### MMM_SS_L_TTTTTT_yyyymmddThhmmss_YYYYMMDDTHHMMSS_ YYYYMMDDTHHMMSS_<instance ID>_GGG_<class ID>.<extension>
###
### MISSION:
### MMM     S3_      for both Sentinel 3A and 3B
### 
### FILETYPE: GN_1_SAC_AX
### SS      GN       Data consumer: GNSS
### L       1        for Level-1
### TTTTT   SAC_AX   Data Type ID; Data Type ID; Solar Activity Auxiliary Data
###
### START VALIDITY:
### yyyymmddThhmmss  Validity start time of the data contained in the file, in CCSDS compact format
### 
### STOP VALIDITY:
### YYYYMMDDTHHMMSS  Validity stop time of the data contained in the file, in CCSDS compact format
###
### CREATION DATE:
### YYYYMMDDTHHMMSS  creation date of the file, in CCSDS compact format
###
### <instance ID>    17 underscores "_"   N/A
###
### GGG              NOA   NOAA
###
### <class ID>       P_XX_NNN O_NR_POD (Operational ; NRT ; POD)
###
### <extension>      SEN3  Sentinel-3
###
### S3__GN_1_SAC_AX_20000101T000000_20130101T000000_20120901T030000___________________NOA_O_NR_POD.SEN3
###

require 'cuc/Converters'
require 'aux/Aux_Handler_Generic'


module AUX

AUX_Pattern_NOAA_RSGA_Daily = "????????RSGA.txt"

class AUX_Handler_NOAA_RSGA_Daily < AUX_Handler_Generic
   
   include CUC::Converters
   
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", isDebug = false)
      @target = target

      super(full_path, dir, isDebug)
            
      if target.upcase == "S3" then
         @mission    = "S3_"
         @fileType = "GN_1_SAC_AX"
      end
      
      if target.upcase == "POD" then
         @mission    = "POD"
         @fileType = "AUX_SAC_AX"
      end

      @instanceID = "____________________NOA_O_NR_POD"
      @extension  = "SEN3"
   end
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   ## -------------------------------------------------------------
   
   def rename
      @strCreationDate  = self.getCreationDateNow
      @newName          = "#{@mission}_#{@fileType}_#{@strValidityStart}_#{@strValidityStop}_#{@strCreationDate}_#{@instanceID}.#{@extension}"
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
   
   ## -----------------------------------------------------------

   def convert_S3
   end
   ## -------------------------------------------------------------

   def convert_POD
      raise "Not Implemented yet"
   end
   ## -------------------------------------------------------------

   def parse      
      @strValidityStart = "#{@filename.slice(0,8)}T000000"
      @strValidityStop  = "#{@filename.slice(0,8)}T000000"
      return
   end
   ## -------------------------------------------------------------
      
end # class

end # module

