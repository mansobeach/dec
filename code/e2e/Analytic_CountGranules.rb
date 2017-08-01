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
      
      @arguments = self.getArguments(arguments)
      
      processArguments
      
      if debug == true then
         self.setDebugMode
      end
      
      @hEvents          = Array.new
      @hAnnotations     = Array.new
      
      super(["ORBIT-PRED", "PDI-CIRCULATION.POD"], parameters, debug)
            
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "Analytic_DutyCyclePOD debug mode is on"
   end
   #-------------------------------------------------------------

   # Process optional arguments supplied to the analytic
   
   def processArguments
      return
   end
   #-------------------------------------------------------------
   
   def analysis
      analysis_mission("S2B")
      
      puts
      puts "------------------------------------"
      puts
      
      analysis_mission("S2A")
      
   end
   #-------------------------------------------------------------
   
   def analysis_mission(er)
      
      # -------------------------------- 
      # Keep the initial query period
      queryStartDate = @queryStartDate
      queryStopDate  = @queryStopDate
      queryStartStr  = @queryStartStr
      queryStopStr   = @queryStopStr
      # --------------------------------
      
      arrPOD      = self.filterExplicitReference(@hEvents["PDI-CIRCULATION.POD"], "#{er}_OPER_AUX_RESORB")
      arrPOD      = self.uniqueExplicitReference(arrPOD)   
      arrANX      = self.filterExplicitReference(@hEvents["ORBIT-PRED"], er)
        
      if arrPOD == nil or arrPOD.empty? == true then
         puts "No POD Restituted products found for #{er} / 0%"
         return false
      else
         if @isDebugMode == true then
            arrPOD.each{|pod|
               podTime = self.str2date(dsGetSensingStart(pod[:explicit_reference]) ).to_time
               puts "#{podTime} => #{pod[:explicit_reference]}"
            }
         end
      end
   
      numPOD = 0
         
      arrANX.each{|anx|
      
         if @isDebugMode == true then
            puts "Orbit #{anx[:value]} : #{anx[:start].to_time} - #{anx[:stop].to_time} [#{((anx[:stop].to_time - anx[:start].to_time)/60.0).round(2)} min]"
         end
               
         arr = filterTimeWindowER(arrPOD, anx[:start].to_time, anx[:stop].to_time)

         if arr == nil or arr.empty? == true then
            anx[:values] = [ "MISSING_#{er}_OPER_AUX_RESORB" ]
            puts "No POD Restituted products found for orbit #{anx[:value]}"
         else
            anx[:values] = [ arr[0][:explicit_reference] ]
            numPOD = numPOD + 1
            puts "Orbit #{anx[:value]} => #{arr[0][:explicit_reference]}"
         end
      
      }
 
      puts "----------------------------------------"     
      puts "Percentage #{er} #{((numPOD / arrANX.length.to_f)*100).to_f.round(2)} %"
      puts "----------------------------------------"
 
      self.writeToExcel(arrANX)
      
   end
   
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
      
end # class

end # module
