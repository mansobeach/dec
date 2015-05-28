#!/usr/bin/env ruby

#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#
#########################################################################

require 'nokogiri'
require 'cuc/Converters'

module E2E

class CSWCreateQuery

   include CUC::Converters

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename, query, arguments, debug = false)
      @filename            = filename
      # @filename            = "query.xml"
      @query               = query
      @queryAttribute      = "@e2espm/#{@query}"
      @arguments           = arguments
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
      puts "CSWCreateQuery debug mode is on"
   end
   #-------------------------------------------------------------
   
   def getEvents
      return @arrEvents
   end
   #-------------------------------------------------------------
   
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
         puts "CSWCreateQuery::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def createXML
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
         xml.send(:'xdei:session', 'xmlns:xsl' => 'http://www.w3.org/1999/XSL/Transform', 'xmlns:qrl' => 'http://www.deimos-space.com/Quarc/Reporting/Language', 'xmlns:xdqi' => 'http://www.deimos-space.com/Quarc/Data/Ingestion/Interface', 'xmlns:xdei' => 'http://www.deimos-space.com/XML/Data/Extraction/Interface'){
            xml.send(:'xdei:directive') {
               xml.send(:'xdei:request') {
                  # xml.getEvents("query_file" => @queryAttribute){
                  xml.send('getEvents', 'query_file' => @queryAttribute){
                     @arguments.each_pair{|key, val|
                        xml.argument(val, :name => key)
                        # xml.argument(:name => key).text(val)
                     }
                  }
               }
            }         
         }
      end
      
      if @isDebugMode == true then 
	      puts
	      puts @filename
         puts
         puts builder.to_xml
         puts
      end
            
      File.open(@filename, "w") { |f| f.print(builder.to_xml) }
      
   end   
   #-------------------------------------------------------------
      
   #-------------------------------------------------------------
   
end # class

end # module
