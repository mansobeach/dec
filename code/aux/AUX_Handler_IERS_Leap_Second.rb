#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_IERS_Leap_Second class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Hander_IERS_Leap_Second.rb,v 1.21 2013/03/14 13:40:57 bolf Exp $
###
### Module AUX management
### 
###
#########################################################################

### IERS Bulletin-C / Leap Second TAI-UTC

### MMM_SS_L_TTTTTT_yyyymmddThhmmss_YYYYMMDDTHHMMSS_ YYYYMMDDTHHMMSS_<instance ID>_GGG_<class ID>.<extension>
###
### MISSION:
### MMM     S3_      for both Sentinel 3A and 3B
### 
### FILETYPE: GN_1_LSC_AX
### SS      GN       Data consumer: GNSS
### L       1        for Level-1
### TTTTT   LSC_AX   Data Type ID; Leap Seconds Auxiliary Data
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
### GGG              USN   US-Navy
###
### <class ID>       P_XX_NNN O_NR_POD (Operational ; NRT ; POD)
###
### <extension>      SEN3  Sentinel-3
###
### S3__GN_1_LSC_AX_20000101T000000_20130101T000000_20120901T030000___________________USN_O_NR_POD.SEN3
###

require 'aux/AUX_Handler_Generic'

module AUX

AUX_Pattern_IERS_Leap_Second = "leap_second.*"

class AUX_Handler_IERS_Leap_Second < AUX_Handler_Generic
   
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", isDebug = false)
      @target = target
      # puts "AUX_Handler_IERS_Leap_Second::initialize"
      super(full_path, dir, isDebug)
      
      @input_file_pattern  = "leap_second"
      @strValidityStart    = ""
      @strValidityStop     = ""
      
      if target.upcase == "S3" then
         @mission    = "S3_"
         @fileType = "GN_1_LSC_AX"
      end
      
      if target.upcase == "POD" then
         @mission    = "POD"
         @fileType = "AUX_LSC_AX"
      end

      @input_file_pattern = "leap_second"

      @instanceID = "____________________USN_O_NR_POD"
      @extension  = "SEN3"
   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   ## -------------------------------------------------------------
   
   def rename
      @strCreationDate  = self.getCreationDate
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

   @listFiles = nil
   @mailer    = nil

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
      File.readlines(@full_path).each do |line|
         
         # Read validity stop
         if line.include?("File expires on") == true then
            fields   = line.split(" ")
            day      = fields[4]
            month    = Date::MONTHNAMES.index(fields[5]).to_s.rjust(2, "0") 
            year     = fields[6]
            @strValidityStop = "#{year}#{month}#{day}T000000"
            if @isDebugMode == true then
               puts "Validity Stop: #{@strValidityStop}"
            end
         end
         
         # Read first line of data to get validity start
         if line[0] != "#" then
            fields = line.split(" ")
            day      = fields[1].to_s.rjust(2, "0")
            month    = fields[2].to_s.rjust(2, "0")
            year     = fields[3]
            @strValidityStart = "#{year}#{month}#{day}T000000"
            if @isDebugMode == true then
               puts "Validity Start: #{@strValidityStart}"
            end            
            break
         end
      end
   end
   ## -------------------------------------------------------------
      
end # class

end # module

