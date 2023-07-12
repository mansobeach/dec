#!/usr/bin/env ruby

#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Elecnor Deimos
# 
#
#
#########################################################################

require 'rexml/document'

require 'cuc/Converters'

require 'dec/DEC_Environment'
require 'aux/AUX_Environment'

module AUX

class WriteXMLFile_NAOS_AUX_BULC

   include CUC::Converters

   #-------------------------------------------------------------
  
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
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("WriteXMLFile_NAOS_AUX_BULC debug mode is on")
   end
   #-------------------------------------------------------------
   
   def writeFixedHeader(filename, validityStart, validityStop)
      
      @eeHeader   = @xmlRoot.add_element("tns:Earth_Explorer_Header")
      header      = @eeHeader.add_element("Fixed_Header")

      xmlFilename             = header.add_element("File_Name")
      xmlFilename.text        = filename

      xmlDescription          = header.add_element("File_Description")
      xmlDescription.text     = "IERS BULC for NAOS"

      xmlNotes                = header.add_element("Notes")
      xmlNotes.text           = "IERS BULC for NAOS"

      xmlMission              = header.add_element("Mission")
      xmlMission.text         = "NS1"

      xmlFileClass            = header.add_element("File_Class")
      xmlFileClass.text       = "OPER"

      # dirty life:
      # https://jira.elecnor-deimos.com/browse/NAOSMOC-326
      xmlFileType             = header.add_element("File_type")
      xmlFileType.text        = "AUX_BULC__"

      xmlValPeriod            = header.add_element("Validity_Period")

      xmlValStart             = xmlValPeriod.add_element("Validity_Start")            
      xmlValStart.text        = validityStart

      xmlValStop              = xmlValPeriod.add_element("Validity_Stop")            
      xmlValStop.text         = validityStop

      xmlFileversion          = header.add_element("File_Version")
      xmlFileversion.text     = "0001"

      xmlSource               = header.add_element("Source")
      
      xmlSystem               = xmlSource.add_element("System")
      xmlSystem.text          = "MOC"
      
      xmlCreator              = xmlSource.add_element("Creator")
      xmlCreator.text         = "DEC/AUX"

      xmlCreatorVersion       = xmlSource.add_element("Creator_Version")
      xmlCreatorVersion.text  = "#{DEC.class_variable_get(:@@version)}/#{AUX::VERSION}"

      xmlCreationDate         = xmlSource.add_element("Creation_Date")
      xmlCreationDate.text    = Time.now.utc.strftime("UTC=%Y-%m-%dT%H:%M:%S")

   end
   #-------------------------------------------------------------

   def writeVariableHeader(leapUTC, leapGPS)
      # dirty life
      # header          = @eeHeader.add_element("tns:Variable_Header")
      header          = @xmlRoot.add_element("tns:Variable_Header")
      utc             = header.add_element("tns:UTC-TAI")
      # dirty life
      # utc.add_attribute("unit",   "seconds")
      utc.text        = leapUTC
      gps             = header.add_element("tns:UTC-GPS")
      gps.text        = leapGPS
      # dirty life
      # gps.add_attribute("unit",   "seconds")
   end
   #-------------------------------------------------------------
   
   def writeDataBlock
      @dataBlock   = @xmlRoot.add_element("Data_Block")
   end
   #-------------------------------------------------------------
   
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
         raise "WriteXMLFile_NAOS_AUX_BULC::checkModuleIntegrity FAILED !"
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

      # <?xml version="1.0"?>
      # <Earth_Observation_File xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://eop-cfi.esa.int/CFI http://eop-cfi.esa.int/CFI/EE_CFI_SCHEMAS/EO_OPER_AUX_ORBRES_0300.XSD" schemaVersion="3.0" xmlns="http://eop-cfi.esa.int/CFI">
      
      # <tns:Earth_Explorer_File xmlns:tns="http://www.example.org/BulletinC" xmlns="http://www.example.org/NAOSCommon" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.example.org/BulletinC BulletinC_v1.xsd">
      
      @xmlRoot          = @xmlFile.add_element("tns:Earth_Explorer_File")
      @xmlRoot.add_namespace('xmlns:tns', 'http://www.example.org/BulletinC')
      @xmlRoot.add_namespace('http://www.example.org/NAOSCommon')
      @xmlRoot.add_namespace('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance')
      @xmlRoot.add_attribute('xsi:schemaLocation', 'http://www.example.org/BulletinC BulletinC_v1.xsd')

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
