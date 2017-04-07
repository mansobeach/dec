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

# Analytic_ReprocessingCompleteness
#
# Parameters (optional)
#
# BASELINE=02.04
#
# analytic_E2E -p "START_UTC=2015-09-10T01:00:00;STOP_UTC=2015-09-10T02:00:00" -a ReprocessingCompleteness -A "BASELINE=02.04"


require 'e2e/AnalyticGeneric'

module E2E

class Analytic_E2E < AnalyticGeneric

   include CUC::Converters

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(arguments, parameters, debug = false)
      
      @baseline   = nil
      @arguments  = self.getArguments(arguments)
      
      processArguments
      
      if debug == true then
         self.setDebugMode
      end
      
      super(["DATA-SENSING.DS"], parameters, debug)
      
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "Analytic_ReprocessingCompleteness debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Process optional arguments supplied to the analytic
   
   def processArguments
      
      if @arguments == nil then
         @baseline = "N02.04"
         return
      end
      
      bArgument = false
      
      @arguments.each{|key, value|
         if key.upcase == "BASELINE" then
            @baseline = "N#{value}"
            bArgument = true
         end        
      }
      
      if bArgument == false then
         puts "Error in Analytic_ReprocessingCompleteness::processArguments"
         puts "arguments not supported"
         puts @arguments
         puts
      end

   end
   #-------------------------------------------------------------
   
   def analysis
     
      arrReprocessed = self.filterExplicitReference(@hEvents["DATA-SENSING.DS"], @baseline)
      arrReprocessed = self.filterExplicitReference(arrReprocessed, "MSI_L1C_DS")
      
      arrPrevious    = self.removeExplicitReference(@hEvents["DATA-SENSING.DS"], @baseline)
      arrPrevious    = self.filterExplicitReference(arrPrevious, "MSI_L1C_DS")

      arrPrevious.each{|ds|
         
         puts "Checking #{ds[:explicit_reference]}"

         startSensing = self.dsGetSensingStart(ds[:explicit_reference])
         arrRepro     = self.filterExplicitReference(arrReprocessed, startSensing)
         
         if arrRepro.empty? == true then
            puts "Missing reprocessing of #{ds[:explicit_reference]} with baseline #{@baseline}"
         else
            puts "#{ds[:explicit_reference]} -> #{arrRepro[0][:explicit_reference]}"
         end 
         
         puts
      }

      puts
      puts

   end
   #-------------------------------------------------------------
   
   
   #-------------------------------------------------------------
      
end # class

end # module
