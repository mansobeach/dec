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

# Analytic_DutyCycleMSI
#
# Parameters (optional)
#
# MISSION=S2A|S2B


require 'e2e/AnalyticGeneric'

module E2E

class Analytic_E2E < AnalyticGeneric

   include CUC::Converters

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(arguments, parameters, debug = false)
      
      if debug == true then
         self.setDebugMode
      end
      super(["MISSION_PLAN_MSI_OPERATION", "ORBIT-PRED"], arguments, parameters, debug)
      
      @switchesTotal       = 0       
      @switchesOrbit       = 0
      @limitDutyCycle      = 46.0
      
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "Analytic_DutyCycleMSI debug mode is on"
   end
   #-------------------------------------------------------------
   
   def usage
      puts "Analytic_DutyCycleMSI::usage"
      puts "Optional arguments:"
      puts "mission=s2a|s2b"
   end
   #-------------------------------------------------------------
   
   def analysis
      
      if @arguments == nil then
         analysis_duty_cycle("Sentinel2A", "S2A")
         return
      end
      
      bArgument = false
      
      @arguments.each{|key, value|
         
         if key.upcase == "MISSION" and value.upcase == "S2A" then
            analysis_duty_cycle("Sentinel2A", "S2A")
            bArgument = true
         end
         
         if key.upcase == "MISSION" and value.upcase == "S2B" then
            analysis_duty_cycle("Sentinel2B", "S2B")
            bArgument = true
         end
        
      }
      
      if bArgument == false then
         puts "Error in Analytic_DutyCycleMSI::analysis"
         puts "arguments not supported"
         puts @arguments
         puts
      end

      exit
      
   end
   #-------------------------------------------------------------
   
   def analysis_duty_cycle(ev_system, er)
   
      arrEventMSI = self.filterSystem(@hEvents["MISSION_PLAN_MSI_OPERATION"], ev_system)
      arrANX      = self.filterExplicitReference(@hEvents["ORBIT-PRED"], er)
      
      arrViolated = Array.new
        
      if arrEventMSI == nil or arrANX == nil then
         return false
      end
   
      @totalImaging  = 0
      @numOrbits     = arrANX.length
   
      arrANX.each{|anx|
      
         @orbitImaging  = 0
      
         events      = self.filterValueInWindow(arrEventMSI, anx[:start].to_time, anx[:stop].to_time)
         dutyCycle   = (accumulatedDutyCycle(events)/60.0).round(2)
         puts "Orbit #{anx[:value]} : #{anx[:start].to_time} - #{anx[:stop].to_time} [#{((anx[:stop].to_time - anx[:start].to_time)/60.0).round(2)} min] => duty #{dutyCycle} minutes / imaging #{(@orbitImaging/60.0).round(2)} minutes / #{@switchesOrbit} switches"
      
         if dutyCycle > @limitDutyCycle then
            arrViolated << events
         end
      
      }
      
      puts
      puts "Avg sensing orbit #{((@totalImaging/60.0)/@numOrbits.to_f).round(2)} minutes"
      puts

      puts "Avg switches orbit #{(@switchesTotal/@numOrbits.to_f).round(2)}"
      puts
      
      if arrViolated.empty? == false then
         puts "Violated constraints in:"
         arrViolated.each{|constraint|
            puts constraint
         }
         self.writeToExcel(arrViolated.flatten!)
      end
      
      
   end
   
   #-------------------------------------------------------------
   
   def accumulatedDutyCycle(events)
      accumulated    = 0
      @switchesOrbit = 0
      events.each{|event|
         
         # puts event[:value]
         
         if @isDebugMode == true then
            puts "#{event[:start].to_time} - #{event[:stop].to_time} : #{event[:value]} / #{event[:stop].to_time - event[:start].to_time}"
         end
         
         if event[:value] == "IMAGING" or event[:value] == "IDLE" then
            accumulated = accumulated +  (event[:stop].to_time - event[:start].to_time)
         end
         
         if event[:value] == "STANDBY" then
            @switchesTotal = @switchesTotal + 1
            @switchesOrbit = @switchesOrbit + 1
         end
         
         if event[:value] == "IMAGING" then
            @totalImaging = @totalImaging +  (event[:stop].to_time - event[:start].to_time)
            @orbitImaging = @orbitImaging +  (event[:stop].to_time - event[:start].to_time)
         end
         
         
      }
      return accumulated
   end
   #-------------------------------------------------------------
      
end # class

end # module
