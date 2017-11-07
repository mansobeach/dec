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
require 'e2e/QuarcModel'

module E2E

class WriteXFBD

   include CUC::Converters

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename, debug = false)
      @filename            = filename
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
      puts "WriteXFBD debug mode is on"
   end
   #-------------------------------------------------------------
   
   def writeHeader(  
                     signature,
                     filename,
                     date_gen,
                     start,
                     stop
                     )
      
            @xmlRoot = @xmlFile.add_element("FBD")
   
            @xmlRoot.add_attribute("xmlns:xs",   "http://www.w3.org/2001/XMLSchema")
            @xmlRoot.add_attribute("xmlns:qil",  "http://www.deimos-space.com/Quarc/Ingestion/Language")
            @xmlRoot.add_attribute("xmlns:xdqi", "http://www.deimos-space.com/Quarc/Data/Ingestion/Interface")
            @xmlRoot.add_attribute("xmlns:xdei", "http://www.deimos-space.com/XML/Data/Extraction/Interface")

            header = @xmlRoot.add_element("header")

            xmlSignature         = header.add_element("DIM_signature")            
            xmlSignature.text    = signature
            
            xmlFilename          = header.add_element("File_Name")
            xmlFilename.text     = filename
            
            xmlDateGen           = header.add_element("generation_date")
            xmlDateGenUTC        = xmlDateGen.add_element("UTC")
            xmlDateGenUTC.text   = date_gen
                        
            xmlDateStart         = header.add_element("start")
            xmlDateStartUTC      = xmlDateStart.add_element("UTC")
            xmlDateStartUTC.text = start
            
            xmlDateStop          = header.add_element("stop")
            xmlDateStopUTC       = xmlDateStop.add_element("UTC")
            xmlDateStopUTC.text  = stop

      
   end
   #-------------------------------------------------------------
   
   def createBody
      @xmlBody = @xmlRoot.add_element("body")
   end
   #-------------------------------------------------------------

   def ingestAnnotation(annotation)
      xmlIngestAnnotation  = @xmlBody.add_element("ingest_annotation")
      xmlIngestAnnotation.add_attribute("explicit_reference",  annotation[:explicit_reference])
      xmlAnnotation        = xmlIngestAnnotation.add_element("annotation")
      xmlAnnotation.add_attribute("name",  annotation[:annotation_name])
      xmlValue             = xmlAnnotation.add_element("value")
      xmlValue.add_attribute("type",  annotation[:annotation_type])
      xmlValue.text        = annotation[:annotation_value]
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
         puts "WriteXFBD::checkModuleIntegrity FAILED !\n\n"
         exit(99)
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
