#!/usr/bin/env ruby

#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Deimos Space
# 
#
#
#########################################################################

require 'rexml/document'

require 'cuc/Converters'

module EOCFI

class ReadStationVisibility

   include REXML
   include CUC::Converters

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename, debug = false)
      @filename            = filename
      @isDebugMode         = debug
      if @isDebugMode == true then
         self.setDebugMode
      end
      @arrAttrNonReader    = ["filename", "isDebugMode", "arrAttrNonReader"]
      
      checkModuleIntegrity
      
      defineStructs
      
      @station_id = ""
      
      if filename != "" then
         ret = loadData
      end
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadStationVisibility debug mode is on"
   end
   #-------------------------------------------------------------
   
   def getEvents
      return @arrEvents
   end
   #-------------------------------------------------------------
   
private

   def initVariables
      return
   end
   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      if bCheckOK == false then
         puts "ReadStationVisibility::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def loadData
      begin
         fileDecode        = File.new(@filename)
         xmlFile           = REXML::Document.new(fileDecode)
         if @isDebugMode == true then
            puts "Parsing #{@filename}"
         end
      rescue Exception => e
         puts
         puts "ERROR XML Parsing #{@filename}"
         puts e
         puts
         return false
      end
            
      explicit_reference   = File.basename(@filename, ".*")
      gauge                = "Station_Visibility"
      library              = "dec/mpl"
      start                = nil
      stop                 = nil
      value                = nil
      
      
      XPath.each(xmlFile, "Earth_Explorer_File/Earth_Explorer_Header/Variable_Header/Station"){
         |station|
         @station_id = station.text
      }
      
      system              = @station_id
               
      XPath.each(xmlFile, "Earth_Explorer_File/Data_Block/List_Of_Segments/Segment"){
         |segment|
         
         values = Array.new
                 
         XPath.each(segment, "Start/UTC"){
            |thestart|                
            # start = thestart.text
            start = self.str2date(thestart.text)
         }

         XPath.each(segment, "Start/Orbit"){
            |orbit|                
            value = orbit.text
            values << orbit.text
         }

         XPath.each(segment, "Start/ANX_sec"){
            |anx|                
            values << anx.text
         }
 
         XPath.each(segment, "Stop/UTC"){
            |theend|                
            # stop = theend.text
            stop = self.str2date(theend.text)
         }
         
         XPath.each(segment, "Stop/Orbit"){
            |orbit|                
            values << orbit.text
         }

         XPath.each(segment, "Stop/ANX_sec"){
            |anx|                
            values << anx.text
         }

         @arrEvents << Struct::Event.new(library, gauge, system, start, stop, value, explicit_reference, values)        
      }

   end   
   #-------------------------------------------------------------
   
   def defineStructs
      
      if Struct::const_defined? "Event"
         Struct.const_get "Event"
      else
         Struct.new("Event", :library, :gauge_name, :system, :start, :stop, :value, :explicit_reference, :values)     
      end
   
      @arrEvents = Array.new
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
end # class

end # module
