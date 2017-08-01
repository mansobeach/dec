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
require 'e2e/FunctionEvents'


module E2E

class AnalyticGeneric

   include CUC::Converters
   include E2E::FunctionEvents

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(arrMOE, arguments, parameters, debug = false)

      if debug == true then
         setDebugMode
      end

      @hEvents          = Hash.new
      @hAnnotations     = Hash.new
      @hParams          = Hash.new
      @arrMOE           = arrMOE
      @arguments        = self.getArguments(arguments)
      @parameters       = parameters
      @queryStartDate   = nil
      @queryStopDate    = nil
      
      checkModuleIntegrity
      
      processParameters
            
      if @arrMOE != nil then
         loadData(@arrMOE, @parameters)
      end    
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "AnalyticGeneric debug mode is on"
   end
   #-------------------------------------------------------------
 
   def usage
      puts "AnalyticGeneric::usage"
   end   
   #-------------------------------------------------------------
   
   # I'd love to do the dirty thing and call again the class constructor
   
   def analysis(arrMOE, parameters, debug = false)
      if debug == true then
         setDebugMode
      end

      @hEvents          = Hash.new
      @hAnnotations     = Hash.new
      @hParams          = Hash.new
      @arrMOE           = arrMOE
      @parameters       = parameters
      @queryStartDate   = nil
      @queryStopDate    = nil
      
      checkModuleIntegrity
      
      processParameters
            
      loadData(@arrMOE, @parameters)      

   end
   
   #-------------------------------------------------------------
   


protected   
   
   
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
         if event[:value].include?(value) == false then
            next
         end
         arr << event
      }
      return arr
   end
   #-------------------------------------------------------------

   def filterName_Annotations(annotations, name)
      arr = Array.new
      annotations.each{|annotation|
         if annotation[:annotation].include?(name) == false then
            next
         end
         arr << annotation
      }
      return arr
   end
   #-------------------------------------------------------------

   def filterValue_Annotations(annotations, value)
      arr = Array.new
      annotations.each{|annotation|
         if annotation[:value].include?(value) == false then
            next
         end
         arr << annotation
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
   
   def filterTimeWindowER(events, start, stop)
      arr = Array.new
      events.each{|event|
         annotation_time = self.str2date(dsGetSensingStart(event[:explicit_reference]) ).to_time
         
#          puts "--------------------------------"
#          puts event[:explicit_reference]
#          puts annotation_time
#          puts start
#          puts stop
#          puts "--------------------------------"
         
         if annotation_time < start or annotation_time > stop then
            next
         end
         arr << event
      }
      return arr
   end
   #-------------------------------------------------------------

   def filterExplicitReference_Annotations(annotations, er)
      arr = Array.new
      annotations.each{|annotation|
         if annotation[:explicit_reference].include?(er) == false then
            next
         end
         arr << annotation
      }
      return arr
   end
   #-------------------------------------------------------------

   def removeSystem(events, system)
      arr = Array.new
      events.each{|event|
         if event[:system].include?(system) == true then
            next
         end
         arr << event
      }
      return arr
   end
   #-------------------------------------------------------------
   
   def removeExplicitReference(events, er)
      arr = Array.new
      events.each{|event|
         if event[:explicit_reference].include?(er) == true then
            next
         end
         arr << event
      }
      return arr
   end
   #-------------------------------------------------------------
   
   def uniqueExplicitReference(events)
      arr   = Array.new
      arrER = Array.new
      events.each{|event|
         if arrER.include?(event[:explicit_reference]) == true then
            next
         end
         arr << event
         arrER << event[:explicit_reference]
      }
      return arr   
   end
   #-------------------------------------------------------------
   
   def findByExplicitReference(events, er)
       events.each{|event|
         if event[:explicit_reference].include?(er) == true then
            return event
         end
      }
      return nil
   end
   #-------------------------------------------------------------

   def findByExplicitReference_Annotations(annotations, er)
       arr   = Array.new
       annotations.each{|annotation|
         if annotation[:explicit_reference].include?(er) == true then
            arr << annotation
         end
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
   
   def writeToConsole(events)
      events.each{|event|
         puts "------------------------------"
         puts ":system              => #{event[:system]}"
         puts ":value               => #{event[:value]}"
         puts ":explicit_reference  => #{event[:explicit_reference]}"
         puts ":values              => #{event[:values]}"
         puts "------------------------------"
      }
   end

   #-------------------------------------------------------------
   
   def writeToConsole_Annotations(annotations)
      annotations.each{|annotation|
         puts "------------------------------"
         puts ":explicit_reference  => #{annotation[:explicit_reference]}"
         puts ":annotation          => #{annotation[:annotation]}"
         puts ":value               => #{annotation[:value]}"
         puts "------------------------------"
      }
   end

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
   
   def buildQueryParameters(start, stop)
      return "START_UTC=#{convertDsDate2Query(start)};STOP_UTC=#{convertDsDate2Query(stop)}"
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
   
   #-------------------------------------------------------------
   
   def processParameters
      if @parameters == nil or @parameters == "" then
         return
      end
      
      @hParams = Hash.new
      arr = @parameters.split(";")
      
      arr.each{|value|
         key = value.split("=")[0]
         val = value.split("=")[1]
         @hParams[key] = val   
      }
      # ------------------------------------------
      @hParams.each{|key, value|
         if key.upcase == "START_UTC" then
            @queryStartStr    = value
            @queryStartDate   = self.str2date(value)
         end
         
         if key.upcase == "STOP_UTC" then
            @queryStopStr    = value
            @queryStopDate   = self.str2date(value)
         end
      }
      # ------------------------------------------
            
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
   #-------------------------------------------------------------

   # S2A_OPER_MSI_L0__DS_SGS__20150910T042806_S20150910T013228_N01.03
   # S2A_OPER_AUX_RESORB_OPOD_20170421T235116_V20170421T194903_20170421T231233.EOF
   def dsGetCreationTime(dsName)
      return dsName.slice(25, 15)
   end
   #-------------------------------------------------------------  
   
   # S2A_OPER_MSI_L0__DS_SGS__20150910T042806_S20150910T013228_N01.03
   # S2A_OPER_AUX_RESORB_OPOD_20170421T235116_V20170421T194903_20170421T231233.EOF
   def dsGetSensingStart(dsName)
      return dsName.slice(42, 15)
   end
   #-------------------------------------------------------------  
   # from   20150910T042806
   # to:    2015-09-10T04:28:06
   def convertDsDate2Query(str)
      queryStr = "#{str.slice(0,4)}-#{str.slice(4,2)}-#{str.slice(6,2)}T#{str.slice(9,2)}:#{str.slice(11,2)}:#{str.slice(13,2)}"
      return queryStr
   end
   #-------------------------------------------------------------  
   
end # class

end # module
