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


module E2E

class ReadGanttXML

   include REXML

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
         ret = loadData
      end
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadGanttXML debug mode is on"
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
         puts "ReadGanttXML::checkModuleIntegrity FAILED !\n\n"
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
            puts "\nParsing #{@filename}"
         end
      rescue Exception => e
         puts
         puts "ERROR XML Parsing #{@filename}"
         puts e
         puts
         return false
      end
      
      XPath.each(xmlFile, "GanttX/Tasks/Task"){
         |task|
         
         library  = nil
         event    = nil
         
         XPath.each(task, "Parameters/Library"){
            |lib|
            library = lib.text
         }
         
         if library == "TLM" then
            event = decodeTLM(task)
            @arrEvents << event
            next
         end
 
         if library == "L0_Completeness" or library == "L0" then
            event = decodeL0(task)
            @arrEvents << event
            next
         end

         if library == "Completeness" or library == "L0" then
            event = decodeL0Completeness(task)
            @arrEvents << event
            next
         end

         if library == "DATA_CIRCULATION" then
            event = decodeCirculation(task)
            @arrEvents << event
            next
         end
         
         puts "Gantt Library #{library} is NOT implemented yet !"
         exit
              
      }

   end   
   #-------------------------------------------------------------
   
   
   def defineStructs
      Struct.new("Event", :library, :gauge_name, :system, :start, :stop, :value, :explicit_reference)     
      @arrEvents = Array.new
   end
   #-------------------------------------------------------------
   # L0_Completeness
   
   def decodeL0(task)
      library     = nil
      gauge       = nil
      system      = nil
      start       = nil
      stop        = nil
      value       = nil
      explicit_reference = nil
  
      XPath.each(task, "Start/"){
         |thestart|                
         # puts thestart.text
         start = thestart.text
      }

      XPath.each(task, "End/"){
         |theend|                
         # puts theend.text
         stop = theend.text
      }

      XPath.each(task, "Parameters/"){
         |param|                

            XPath.each(param, "Library/"){
               |lib|
               library = lib.text
           }    
                           
           XPath.each(param, "CENTRE/"){
              |centre|                
              system = centre.text    
           }

           XPath.each(param, "PRODUCT/"){
               |product|                
               explicit_reference = product.text
           }

           gauge = "DATA-VALIDITY"            

#            XPath.each(param, "PARAM/"){
#                  |param| 
#                  
#                  value = param.text               
#            }

           XPath.each(param, "DETECTOR/"){
                 |detector| 
                 
                 value = detector.text               
           }



           XPath.each(param, "COMPLETENESS/"){
                 |completeness| 
                 
                 value = "#{value} ; #{completeness.text}"               
           }

#             XPath.each(param, "Timeline/"){
#                      |timeline|                
#                      puts timeline.text
#             }
      }
   
      return Struct::Event.new(library, gauge, system, start, stop, value, explicit_reference)
          
   end
   #-------------------------------------------------------------
   # Telemetry Analysis

   def decode(task)
 
      library     = nil
      gauge       = nil
      system      = nil
      start       = nil
      stop        = nil
      value       = nil
      explicit_reference = nil
  
      XPath.each(task, "Start/"){
         |thestart|                
         # puts thestart.text
         start = thestart.text
      }

      XPath.each(task, "End/"){
         |theend|                
         # puts theend.text
         stop = theend.text
      }

      XPath.each(task, "Parameters/"){
         |param|                

            XPath.each(param, "Library/"){
               |lib|
               
               library = lib.text
               
           }    
                           
            XPath.each(param, "DFEP_REP/"){
                     |reference|                
                     # puts explicit_reference.text
                     system = reference.text.slice(20, 4)
                     explicit_reference = reference.text
            }

            XPath.each(param, "PARAM/"){
                     |gauge_name|                
                     # puts gauge_name.text
                     gauge = gauge_name.text
            }

            XPath.each(param, "APID/"){
                     |gauge_value|                
                     # puts gauge_value.text
                     value = gauge_value.text
            }

            XPath.each(param, "Timeline/"){
                     |timeline|                
                     puts timeline.text
            }  
               
      }
   
      return Struct::Event.new(library, gauge, system, start, stop, value, explicit_reference)
      
   end
   #-------------------------------------------------------------

   # L0_Completeness
   
   def decodeL0Completeness(task)
      library     = nil
      gauge       = nil
      system      = nil
      start       = nil
      stop        = nil
      value       = nil
      explicit_reference = nil
  
      XPath.each(task, "Start/"){
         |thestart|                
         # puts thestart.text
         start = thestart.text
      }

      XPath.each(task, "End/"){
         |theend|                
         # puts theend.text
         stop = theend.text
      }

      XPath.each(task, "Parameters/"){
         |param|                

            XPath.each(param, "Library/"){
               |lib|
               library = lib.text
           }    
                           
           XPath.each(param, "Centre/"){
              |centre|                
              system = centre.text    
           }

           XPath.each(param, "PRODUCT/"){
               |product|                
               explicit_reference = product.text
           }

           gauge = "L0-COMPLETENESS"            

#            XPath.each(param, "PARAM/"){
#                  |param| 
#                  
#                  value = param.text               
#            }


           XPath.each(param, "Timeline/"){
                 |timeline| 
                 
                 value = timeline.text               
           }

#             XPath.each(param, "Timeline/"){
#                      |timeline|                
#                      puts timeline.text
#             }
      }
   
      return Struct::Event.new(library, gauge, system, start, stop, value, explicit_reference)
          
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   # DATA_CIRCULATION
   
   def decodeCirculation(task)
      library     = nil
      gauge       = nil
      system      = nil
      start       = nil
      stop        = nil
      value       = nil
      explicit_reference = nil
  
      XPath.each(task, "Start/"){
         |thestart|                
         # puts thestart.text
         start = thestart.text
      }

      XPath.each(task, "End/"){
         |theend|                
         # puts theend.text
         stop = theend.text
      }

      XPath.each(task, "Parameters/"){
         |param|                

            XPath.each(param, "Library/"){
               |lib|
               library = lib.text
           }    
                           
           XPath.each(param, "SOURCE_CENTRE/"){
              |centre|                
              system = centre.text    
           }

           XPath.each(param, "PDI/"){
               |pdi|                
               explicit_reference = pdi.text
           }

           gauge = "DATA-CIRCULATION"            

#            XPath.each(param, "PARAM/"){
#                  |param| 
#                  
#                  value = param.text               
#            }

           XPath.each(param, "DESTINATION_CENTRE/"){
                 |destination| 
                 
                 value = "Destination=#{destination.text}"               
           }



      }
   
      return Struct::Event.new(library, gauge, system, start, stop, value, explicit_reference)
          
   end
   #-------------------------------------------------------------




   #-------------------------------------------------------------
   
end # class

end # module
