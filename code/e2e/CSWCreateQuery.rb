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

require 'rexml/document'
require 'cuc/Converters'

module E2E

class CSWCreateQuery

   include CUC::Converters

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename, query, arguments, bCorrectUTC, debug = false)
      @filename            = filename
      @query               = query
      @queryAttribute      = "@e2espm/#{@query}"
      @arguments           = arguments
      @bCorrectUTC         = bCorrectUTC
      @isDebugMode         = debug
      if @isDebugMode == true then
         self.setDebugMode
         puts "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
         puts @filename
         puts @query
         puts "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
         # exit
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
      @xmlFile = REXML::Document.new
      # @xmlFile.encoding = "UTF-8"
      
      declaration = REXML::XMLDecl.new
      declaration.encoding = "UTF-8"
      
      # @xmlFile << REXML::XMLDecl.new
      @xmlFile << declaration

      root = @xmlFile.add_element("xdei:session")
   
      root.add_attribute("xmlns:xsl",  "http://www.w3.org/1999/XSL/Transform")
      root.add_attribute("xmlns:qrl",  "http://www.deimos-space.com/Quarc/Reporting/Language")
      root.add_attribute("xmlns:xdqi", "http://www.deimos-space.com/Quarc/Data/Ingestion/Interface")
      root.add_attribute("xmlns:xdei", "http://www.deimos-space.com/XML/Data/Extraction/Interface")
   
      directive = root.add_element("xdei:directive")
      
      request   = directive.add_element("xdei:request")
      
      events = request.add_element("getEvents")
      events.add_attribute("query_file", "\@e2espm/#{@query}")
      
      @arguments.each_pair{|key, val|
         arg = events.add_element("argument")
         arg.add_attribute("name", key)
         arg.text = val
      }

      directive.add_element("xdei:data")

      # --------------------------------------------------------------
      
      if @bCorrectUTC == true then
      
         if @isDebugMode == true then
            puts "adding directive to request get_predicted_orbit" 
         end
      
         directive = root.add_element("xdei:directive")
      
         request   = directive.add_element("xdei:request")
      
         events = request.add_element("getEvents")
         events.add_attribute("query_file", "\@e2espm/get_predicted_orbit")
      
         @arguments.each_pair{|key, val|
            arg = events.add_element("argument")
            arg.add_attribute("name", key)
            arg.text = val
         }

         directive.add_element("xdei:data")
      end

      # --------------------------------------------------------------

      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      
      File.open(@filename,"w") {|file| file.puts formatter.write(@xmlFile,"") }

#       if @isDebugMode == true then 
# 	      puts
# 	      puts @filename
#          puts
#          puts formatter.write(@xmlFile,"")
#          puts
#       end

      cmd = "xmllint --format #{@filename} > kako.xml"
      # puts cmd
      system(cmd)
      
      cmd = "mv kako.xml #{@filename}"
      # puts cmd
      system(cmd)
      
   end   
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
end # class

end # module
