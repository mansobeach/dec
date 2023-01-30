#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_CCSDS_OEM class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_CCSDS_OEM.rb
###
### Module AUX management
### 
###
#########################################################################

require 'rexml/document'

require 'cuc/Converters'

require 'aux/AUX_Handler_Generic'
require 'aux/WriteXMLFile_EOCFI_AUX_ORBRES'

module AUX

AUX_Pattern_CCSDS_OEM = "*ORB_OEM*.OEM"

class AUX_Handler_CCSDS_OEM < AUX_Handler_Generic
   
   include REXML
   include CUC
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)

      @target = target
      
      super(full_path, dir, logger, isDebug)
      
      Struct.new("OEM_OSV", :epoch, :x, :y, :z, :x_dot, :y_dot, :z_dot)

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
         when "NAOS" then return convertEOCFI
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
      @fileType      = "AUX_ORBRES"
      @fileClass     = "GSOV"
      # file deviates from the EOFFS hence it is flagged as xml
      # @extension     = "EOF"
      @extension     = "EOF"
   end
   ## -----------------------------------------------------------
   
   def initMetadata_S3
      @mission    = "S3_"
      @fileType   = "AUX_ORBRES"
      @instanceID = "____________________USN_O_NR_POD"
      @extension  = "SEN3"
      raise "not implemented for #{@target}"
   end
   ## -------------------------------------------------------------
   
   def initMetadata_POD
      @mission    = "POD"
      @fileType   = "AUX_ORBRES"
      raise "not implemented for #{@target}"
   end
   ## -------------------------------------------------------------

   ## -------------------------------------------------------------

   def parse

      if @isDebugMode == true then
         @logger.debug("AUX_Handler_CCSDS_OEM::parse")
      end

      @arrOSV           = Array.new
      fileOEM           = File.new(@full_path)
      xmlFile           = REXML::Document.new(fileOEM)
      path              = "/oem/body/segment/metadata"

      # ----------------
      # metadata

      XPath.each(xmlFile, path){
         |entry|

         XPath.each(entry, "START_TIME"){
            |start|
            @strValidityStart = start.text
            if @isDebugMode == true then
               @logger.debug("START_TIME  : #{@strValidityStart}")
            end
         }

         XPath.each(entry, "STOP_TIME"){
            |stop|
            @strValidityStop = stop.text
            if @isDebugMode == true then
               @logger.debug("STOP_TIME   : #{@strValidityStop}")
            end
         }

      }
      # ----------------

      path  = "/oem/body/segment/data/stateVector"

      XPath.each(xmlFile, path){
         |osv|

         osv_epoch   = nil
         osv_x       = nil
         osv_y       = nil
         osv_z       = nil
         osv_x_dot   = nil
         osv_y_dot   = nil
         osv_z_dot   = nil


         XPath.each(osv, "EPOCH"){
            |epoch|
            osv_epoch = epoch.text
            if @isDebugMode == true then
               @logger.debug("parsing OSV @ epoch: #{osv_epoch}")
            end
         }

         XPath.each(osv, "X"){
            |x|
            osv_x = x.text
         }

         XPath.each(osv, "Y"){
            |y|
            osv_y = y.text
         }

         XPath.each(osv, "Z"){
            |z|
            osv_z = z.text
         }

         XPath.each(osv, "X_DOT"){
            |x_dot|
            osv_x_dot = x_dot.text
         }

         XPath.each(osv, "Y_DOT"){
            |y_dot|
            osv_y_dot = y_dot.text
         }

         XPath.each(osv, "Z_DOT"){
            |z_dot|
            osv_z_dot = z_dot.text
         }

         @arrOSV  << Struct::OEM_OSV.new(osv_epoch, osv_x, osv_y, osv_z, osv_x_dot, osv_y_dot, osv_z_dot)

      }

      # ----------------
      
   end
   ## -------------------------------------------------------------
   
   # reference 

   def convertEOCFI
      
      if @isDebugMode == true then
         @logger.debug("BEGIN convertNAOS")
      end
      
      valStart = str2date(@strValidityStart).strftime("%Y%m%dT%H%M%S")
      valStop  = str2date(@strValidityStop).strftime("%Y%m%dT%H%M%S")

      if @isDebugMode == true then
         @logger.debug("Num of OSVs: #{@arrOSV.length}")
      end

      filename    = "#{@mission}_#{@fileClass}_#{@fileType}_#{valStart}_#{valStop}_#{@fileVersion}"
      auxORBRES   = WriteXMLFile_EOCFI_AUX_ORBRES.new("#{@targetDir}/#{filename}.#{@extension}", @logger, @isDebugMode)   

      auxORBRES.writeFixedHeader(filename, @strValidityStart, @strValidityStop)

      auxORBRES.writeVariableHeader

      auxORBRES.writeDataBlock(@arrOSV)

      auxORBRES.write

      @logger.info("[AUX_001] #{filename}.#{@extension} generated from #{@filename}")

      if @isDebugMode == true then
         @logger.debug("END convertNAOS")
      end

      return "#{filename}.#{@extension}"
   end
   ## -------------------------------------------------------------

end # class

end # module

