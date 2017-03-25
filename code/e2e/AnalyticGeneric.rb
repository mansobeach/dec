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

require 'e2e/WriteGanttXLS'
require 'e2e/ReadCSWResult'
require 'e2e/QuarcModel'


module E2E

class AnalyticGeneric

   include CUC::Converters

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(arrMOE, parameters, debug = false)

      if debug == true then
         setDebugMode
      end

      @hEvents       = Hash.new
      @hAnnotations  = Hash.new
      @arrMOE        = arrMOE
      @parameters    = parameters

      checkModuleIntegrity

      loadData(@arrMOE, @parameters)      
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "AnalyticGeneric debug mode is on"
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   def analysis
      puts
      puts "AnalyticGeneric::analysis is an abtract method"
      puts
      exit
   end
   
   #-------------------------------------------------------------
   


protected   
   
   
   #-------------------------------------------------------------
   
   def filterSystem(events, system)
      arr = Array.new
      events.each{|event|
         if event[:system] != system then
            next
         end
         arr << event
      }
      return arr
   end
   #-------------------------------------------------------------
 
   def filterGauge(events, gauge)
      arr = Array.new
      events.each{|event|
         if event[:gauge_name].include?(gauge) == false then
            next
         end
         arr << event
      }
      return arr
   end
 
   #-------------------------------------------------------------
   
   def filterValueInWindow(events, start, stop)
      arr = Array.new
      events.each{|event|
         if event[:start].to_time < start then
            next
         end
 
         # if events are sorted, it could already exit and return found results
         if event[:start].to_time > stop then
            next
         end

         arr << event
      }
      return arr   
   end
   #-------------------------------------------------------------
   
   def filterValue(events, value)
      arr = Array.new
      events.each{|event|
         if event[:value] != value then
            next
         end
         arr << event
      }
      return arr
   end
   #-------------------------------------------------------------

   def filterExplicitReference(events, er)
      arr = Array.new
      events.each{|event|
         if event[:explicit_reference].include?(er) == false then
            next
         end
         arr << event
      }
      return arr
   end
   #-------------------------------------------------------------
   
   def writeToHTML(events)
      # blah blah blah
   end
   #-------------------------------------------------------------
   
   def raiseAlert(message, alertCode)
      # blah blah blah
   end
   #-------------------------------------------------------------

   def writeToLog(message, severity)
      # blah blah blah
   end
   #-------------------------------------------------------------

   def writeToExcel(events)
      writer      = E2E::WriteGanttXLS.new(@isDebugMode)    
      writer.writeToExcel(events)
   end
   #-------------------------------------------------------------
   
      


   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      if bCheckOK == false then
         puts "AnalyticGeneric::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   def queryMOE(moe, parameters)
      if parameters == "" or parameters == nil then
         cmd = "queryMOE.rb -q #{moe} -p \"START_UTC=2000-07-07T00:00:00;STOP_UTC=2020-07-11T00:00:00\""
         cmd = "queryMOE.rb -q #{moe} -p \"START_UTC=2017-03-21T00:00:00;STOP_UTC=2020-07-11T00:00:00\""
      else
         cmd = "queryMOE.rb -q #{moe} -p \"#{parameters}\""
      end

      cmd = "#{cmd} -f /tmp/result_#{moe}.xml"

      if @isDebugMode == true then
         cmd = "#{cmd} -D"
         puts cmd
      end
      puts cmd
      system(cmd)
   end
   #-------------------------------------------------------------
   
   def loadMOE(moe)
      file_result          = "/tmp/result_#{moe}.xml"
      parser               = E2E::ReadCSWResult.new(file_result, @isDebugMode)
      @hEvents[moe]        = parser.getEvents
      @hAnnotations[moe]   = parser.getExplicitReferences
   end
   #-------------------------------------------------------------
   
   def loadData(arrMOE, arrParameter)
      arrMOE.each{|moe|
         queryMOE(moe, arrParameter)
         loadMOE(moe)
         # puts @hEvents[moe]
         # puts @hAnnotations[moe]
      }      
   end
   #-------------------------------------------------------------
   
   def getArguments(arg)
      if arg == nil then
         return nil
      end
      hParam = Hash.new
      arr = arg.split(";")
      arr.each{|value|
         key = value.split("=")[0]
         val = value.split("=")[1]
         hParam[key] = val   
      }
      return hParam
   end
#---------------------------------------------------------------------

   #-------------------------------------------------------------  
   
end # class

end # module
