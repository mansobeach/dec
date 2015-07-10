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

class ReadCSWResult

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
      
      if filename != "" then
         ret = loadDataEvents
         ret = loadDataExplicitReference
      end
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadCSWResult debug mode is on"
   end
   #-------------------------------------------------------------
   
   # xdqi directive get timeline/events
   def getEvents
      return @arrEvents
   end
   #-------------------------------------------------------------
   
   # xdqi directive getExplicitReferences
   def getExplicitReferences
      return @arrERs
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
         puts "ReadCSWResult::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def loadDataEvents
      begin
         fileDecode        = File.new(@filename)
         xmlFile           = REXML::Document.new(fileDecode)
         if @isDebugMode == true then
            puts "\nParsing #{@filename}"
         end
      rescue Exception => e
         puts
         puts "ERROR XML Parsing #{@filename}"
         puts e
         puts
         return false
      end
      
      XPath.each(xmlFile, "xdqi:session/xdqi:directive/xdqi:request/getObject"){
         |query|
         # puts query.attributes["script"]
         # puts query.attributes["object"]
         @library = "#{query.attributes["script"]} - #{query.attributes["object"]}"
      }
      
      XPath.each(xmlFile, "xdqi:session/xdqi:directive/xdqi:data/timeline"){
         |timeline|         
#          puts timeline         
#          nCount = timeline.attributes.get_attribute( "count" )
#          puts nCount.class
                           
         XPath.each(timeline, "event"){
            |event|            
            @arrEvents << decode_event(event)
         }
      }
   end   
   #-------------------------------------------------------------
   
   
   def defineStructs
      Struct.new("Event", :library, :gauge_name, :system, :start, :stop, :value, :explicit_reference, :values)     
      @arrEvents  = Array.new
      
      Struct.new("Explicit_Reference", :explicit_reference, :annotation, :value)     
      @arrERs     = Array.new
   end
   #-------------------------------------------------------------
   # decode_event
   
   def decode_event(event)
      library     = nil
      gauge       = nil
      system      = nil
      start       = nil
      stop        = nil
      value       = nil
      values      = Array.new
      explicit_reference   = nil  
      explicit_reference   = event.attributes["explicit_reference"]
     
      XPath.each(event, "gauge/"){
         |the_gauge|         
         gauge       = the_gauge.attributes["name"]
         system      = the_gauge.attributes["system"]   
         
         # ------------------------------------
         # single value reported
         
         XPath.each(the_gauge, "value/"){
            |the_value|         
            value = the_value.text               
         }
         
         # ------------------------------------
         
         # ------------------------------------
         # Array of values
         
         XPath.each(the_gauge, "values/"){
            |some_values|
            
            XPath.each(some_values, "value/"){
               |a_value|
               values << a_value.text               
            }
                          
         }
         
         values.uniq!
         
         # ------------------------------------
  
         
      }
 
      XPath.each(event, "start/UTC"){
         |thestart|                
         # puts thestart.text
         start = self.str2date(thestart.text)
      }

      XPath.each(event, "stop/UTC"){
         |theend|                
         # puts theend.text
         stop = self.str2date(theend.text)
      }
      
      return Struct::Event.new(@library, gauge, system, start, stop, value, explicit_reference, values)
          
   end
   #-------------------------------------------------------------

   # loadData
   def loadDataExplicitReference
      begin
         fileDecode        = File.new(@filename)
         xmlFile           = REXML::Document.new(fileDecode)
         if @isDebugMode == true then
            puts "\nParsing #{@filename}"
         end
      rescue Exception => e
         puts
         puts "ERROR XML Parsing #{@filename}"
         puts e
         puts
         return false
      end
      
      XPath.each(xmlFile, "xdqi:session/xdqi:directive/xdqi:request/getObject"){
         |query|
         # puts query.attributes["script"]
         # puts query.attributes["object"]
         @library = "#{query.attributes["script"]} - #{query.attributes["object"]}"
      }
      
      XPath.each(xmlFile, "xdqi:session/xdqi:directive/xdqi:data/explicit_references"){
         |explicit_references|         
        #  puts explicit_references
        #  exit    
        #  nCount = explicit_reference.attributes.get_attribute( "count" )
#          puts nCount.class
                           
         XPath.each(explicit_references, "explicit_reference"){
            |explicit_reference|
             
#              puts "-----------------------------------"
#              puts explicit_reference
            
            decode_explicit_reference(explicit_reference)
                    
            # @arrEvents << decode_event(event)
         }
         
      }
   end   
   #-------------------------------------------------------------

   # decode_explicit_reference
   
   def decode_explicit_reference(e_r)
      library     = nil
      gauge       = nil
      system      = nil
      start       = nil
      stop        = nil
      value       = nil
      explicit_reference   = nil  
      explicit_reference   = e_r.attributes["text"]     
      # puts explicit_reference
      
      XPath.each(e_r, "annotations/"){
         |annotations|         
         
         XPath.each(annotations, "annotation/"){
            |annotation|
            
            # puts annotation
                   
            name = annotation.attributes["name"]
            
            # puts name
            
            XPath.each(annotation, "value/"){
               |val|
               
               value = nil
               
               if name.include?("TIME") == true then
                  value = str2strexceldate(val.text)
               else
                  value = val.text
               end
               
               @arrERs << Struct::Explicit_Reference.new(explicit_reference, name, value) 
               
               # exit
               
            }
                                    
         }
      }
      
   end
   #-------------------------------------------------------------


   
   #-------------------------------------------------------------
   
end # class

end # module
