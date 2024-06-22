#!/usr/bin/env ruby

require 'rexml/document'

require 'cuc/Converters'
require 'aux/AUX_Environment'

module AUX

class WriteXMLFile_SAFE_Manifest

   include CUC::Converters

   # -------------------------------------------------------------
  
   # Class constructor
   def initialize(filename, logger, debug = false)
      @filename            = filename
      @logger              = logger
      @isDebugMode         = debug
      if @isDebugMode == true then
         self.setDebugMode
      end
     
      checkModuleIntegrity
      
      createXML
   end
   # -------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("WriteXMLFile_EOCFI_AUX_ORBRES debug mode is on")
   end
   # -------------------------------------------------------------
   
   def writeFixedHeader(filename, validityStart, validityStop)
      
      @eeHeader   = @xmlRoot.add_element("Earth_Observation_Header")
      header      = @eeHeader.add_element("Fixed_Header")

      xmlFilename             = header.add_element("File_Name")
      xmlFilename.text        = filename

      xmlDescription          = header.add_element("File_Description")
      xmlDescription.text     = "OSV Orbit File"

      xmlNotes                = header.add_element("Notes")
      xmlNotes.text           = "Radio number#1"

      xmlMission              = header.add_element("Mission")
      xmlMission.text         = "NAOS"

      xmlFileClass            = header.add_element("File_Class")
      xmlFileClass.text       = "GSOV"

      xmlFileType             = header.add_element("File_Type")
      xmlFileType.text        = "AUX_ORBRES"

      xmlValPeriod            = header.add_element("Validity_Period")

      xmlValStart             = xmlValPeriod.add_element("Validity_Start")            
      xmlValStart.text        = "UTC=#{validityStart.slice(0,19)}"

      xmlValStop              = xmlValPeriod.add_element("Validity_Stop")            
      xmlValStop.text         = "UTC=#{validityStop.slice(0,19)}"

      xmlFileversion          = header.add_element("File_Version")
      xmlFileversion.text     = "0001"

      xmlFileversion          = header.add_element("EOFFS_Version")
      xmlFileversion.text     = "3.0"

      xmlSource               = header.add_element("Source")
      
      xmlSystem               = xmlSource.add_element("System")
      xmlSystem.text          = "MOC"
      
      xmlCreator              = xmlSource.add_element("Creator")
      xmlCreator.text         = "AUX"

      xmlCreatorVersion       = xmlSource.add_element("Creator_Version")
      xmlCreatorVersion.text  = "#{AUX::VERSION}"

      xmlCreationDate         = xmlSource.add_element("Creation_Date")
      xmlCreationDate.text    = Time.now.utc.strftime("UTC=%Y-%m-%dT%H:%M:%S")

   end
   # -------------------------------------------------------------

   def writeVariableHeader
      header          = @eeHeader.add_element("Variable_Header")
      frame           = header.add_element("Ref_Frame")
      frame.text      = "EARTH_FIXED"
      time            = header.add_element("Time_Reference")
      time.text       = "UTC"
   end
   # -------------------------------------------------------------
   
   # GPS time = TAI - 19s (always).
   # @diffUTC2GPS = @diffTAI2UTC - 19

   def writeDataBlock(arrOSV)
      @dataBlock   = @xmlRoot.add_element("Data_Block")
      @dataBlock.add_attribute("type", "xml")
      listOSV = @dataBlock.add_element("List_of_OSVs")
      listOSV.add_attribute("count", arrOSV.length)
      arrOSV.each{
         |sourceOSV|
         xmlOSV   = listOSV.add_element("OSV")

         # TAI is 37s ahead / need to 
         tai      = xmlOSV.add_element("TAI")
         tai.text = "TAI=#{sourceOSV[:epoch]}000"

         utc      = xmlOSV.add_element("UTC")
         utc.text = "UTC=#{sourceOSV[:epoch]}000"

         ut1      = xmlOSV.add_element("UT1")
         ut1.text = "UT1=#{sourceOSV[:epoch]}000"

         abs_orbit = xmlOSV.add_element("Absolute_Orbit")
         abs_orbit.text = "+00000"

         x      = xmlOSV.add_element("X")
         x.add_attribute("unit", "m")
         x.text = (sourceOSV[:x].to_f*1000).to_s

         y      = xmlOSV.add_element("Y")
         y.add_attribute("unit", "m")
         y.text = (sourceOSV[:y].to_f*1000).to_s

         z      = xmlOSV.add_element("Z")
         z.add_attribute("unit", "m")
         z.text = (sourceOSV[:z].to_f*1000).to_s

         vx      = xmlOSV.add_element("VX")
         vx.add_attribute("unit", "m/s")
         vx.text = (sourceOSV[:x_dot].to_f*1000).to_s

         vy      = xmlOSV.add_element("VY")
         vy.add_attribute("unit", "m/s")
         vy.text = (sourceOSV[:y_dot].to_f*1000).to_s

         vz      = xmlOSV.add_element("VZ")
         vz.add_attribute("unit", "m/s")
         vz.text = (sourceOSV[:z_dot].to_f*1000).to_s

         quality = xmlOSV.add_element("Quality")
         quality.text = "0000000000000"
      }
   end
   # -------------------------------------------------------------
   
   def write
      writeFile
   end
   
private

   #-------------------------------------------------------------

   def initVariables
      return
   end
   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      if bCheckOK == false then
         raise "WriteXMLFile_EOCFI_AUX_ORBRES::checkModuleIntegrity FAILED !"
      end
   end
   #-------------------------------------------------------------
   
   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def createXML
      @xmlFile = REXML::Document.new
      # @xmlFile.encoding = "UTF-8"
      
      declaration = REXML::XMLDecl.new
      declaration.encoding = "UTF-8"
      
      # @xmlFile << REXML::XMLDecl.new
      @xmlFile << declaration
     
      # <Earth_Observation_File xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://eop-cfi.esa.int/CFI http://eop-cfi.esa.int/CFI/EE_CFI_SCHEMAS/EO_OPER_AUX_ORBRES_0300.XSD" schemaVersion="3.0" xmlns="http://eop-cfi.esa.int/CFI">

      @xmlRoot = @xmlFile.add_element("Earth_Observation_File")
      @xmlRoot.add_namespace('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance')
      @xmlRoot.add_attribute('xsi:schemaLocation', 'http://eop-cfi.esa.int/CFI http://eop-cfi.esa.int/CFI/EE_CFI_SCHEMAS/EO_OPER_AUX_ORBRES_0300.XSD')
      @xmlRoot.add_attribute('schemaVersion', '3.0')
      @xmlRoot.add_namespace('http://eop-cfi.esa.int/CFI')
   end   
   #-------------------------------------------------------------
   
   def writeFile

      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      
      fh = File.new(@filename,"w")
      fh.puts formatter.write(@xmlFile,"")
      fh.close
      
      cmd = "xmllint --format #{@filename} > .kako.xml"
      # puts cmd
      system(cmd)
      
      cmd = "mv .kako.xml #{@filename}"
      # puts cmd
      system(cmd)

   end
   #-------------------------------------------------------------
   
end # class

end # module
