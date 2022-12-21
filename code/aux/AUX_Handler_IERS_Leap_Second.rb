#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_IERS_Leap_Second class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Hander_IERS_Leap_Second.rb
###
### Module AUX management
### 
###
#########################################################################

###
## https://aviation.stackexchange.com/questions/90839/what-are-satellite-time-gps-time-and-utc-time
## GPS time = TAI - 19s (always).

### IERS Bulletin-C / Leap Second TAI-UTC
## https://hpiers.obspm.fr/iers/bul/bulc/Leap_Second.dat

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

require 'cuc/Converters'

require 'aux/AUX_Handler_Generic'
require 'aux/WriteXMLFile_NAOS_AUX_BULC'

module AUX

AUX_Pattern_IERS_Leap_Second = "leap_second.dat"

class AUX_Handler_IERS_Leap_Second < AUX_Handler_Generic
   
   include CUC
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)

      @target = target
      
      super(full_path, dir, logger, isDebug)
      
      case @target.upcase
         when "NAOS" then initMetadata_NAOS
         when "S3"   then initMetadata_S3
         when "POD"  then initMetadata_POD
         else raise "#{@target.upcase} not supported"
      end
 
      @strValidityStart    = ""
      @strValidityStop     = ""
      
   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   ## -------------------------------------------------------------
   
   # NS1_TEST_AUX_BULC___20220707T000000_21000101T000000_0001.EOF
   def rename
      @newName          = "#{@mission}_#{@fileClass}_#{@fileType}_#{@strValidityStart}_#{@strValidityStop}_#{@fileVersion}.#{@extension}"
      super(@newName)
      return @full_path_new
   end
   ## -------------------------------------------------------------

   def convert
      parse

      case @target.upcase
         when "NAOS" then return convertNAOS
         else 
            if @isDebugMode == true then
               @logger.debug("no file internal conversion for #{@target.upcase}") 
            end
      end

      return rename
   end
   ## -------------------------------------------------------------

private

   ## -----------------------------------------------------------

   def initMetadata_NAOS
      @mission       = "NS1"
      @fileType      = "AUX_BULC__"
      @extension     = "EOF"
      @diffTAI2UTC   = nil
      @diffUTC2GPS   = nil
   end
   ## -----------------------------------------------------------
   
   def initMetadata_S3
      @mission    = "S3_"
      @fileType   = "GN_1_LSC_AX"
      @instanceID = "____________________USN_O_NR_POD"
      @extension  = "SEN3"
      raise "not implemented for #{@target}"
   end
   ## -------------------------------------------------------------
   
   def initMetadata_POD
      @mission    = "POD"
      @fileType   = "AUX_LSC_AX"
      raise "not implemented for #{@target}"
   end
   ## -------------------------------------------------------------

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
               @logger.debug("Validity Stop: #{@strValidityStop}")
            end
         end
         
         # Read last line of data to get validity start
         if line[0] != "#" then
            fields = line.split(" ")
            day            = fields[1].to_s.rjust(2, "0")
            month          = fields[2].to_s.rjust(2, "0")
            year           = fields[3]
            @diffTAI2UTC   = fields[4].to_i
            @strValidityStart = "#{year}#{month}#{day}T000000"
            if @isDebugMode == true then
               @logger.debug("Validity Start: #{@strValidityStart}")
               @logger.debug("TAI-UTC => #{@diffTAI2UTC} seconds")
            end
            # break
         end
      end
   end
   ## -------------------------------------------------------------
   
   def convertNAOS
      
      if @isDebugMode == true then
         @logger.debug("BEGING convertNAOS")
      end
      
      filename    = "#{@mission}_#{@fileClass}_#{@fileType}_#{@strValidityStart}_#{@strValidityStop}_#{@fileVersion}"
      auxBULC     = WriteXMLFile_NAOS_AUX_BULC.new("#{@targetDir}/#{filename}.EOF", @logger, @isDebugMode)

      if @isDebugMode == true then
         auxBULC.setDebugMode
      end

      valStart = str2date(@strValidityStart).strftime("UTC=%Y-%m-%dT%H:%M:%S")
      valStop  = str2date(@strValidityStop).strftime("UTC=%Y-%m-%dT%H:%M:%S")

      auxBULC.writeFixedHeader(filename, valStart, valStop)

      ## GPS time = TAI - 19s (always).
      @diffUTC2GPS = @diffTAI2UTC - 19

      auxBULC.writeVariableHeader(@diffTAI2UTC, @diffUTC2GPS)

      auxBULC.writeDataBlock

      auxBULC.write

      @logger.info("[AUX_001] #{filename}.EOF generated from #{@filename}")

      if @isDebugMode == true then
         @logger.debug("END convertNAOS")
      end

      return "#{filename}.EOF"
   end
   ## -------------------------------------------------------------

end # class

end # module

