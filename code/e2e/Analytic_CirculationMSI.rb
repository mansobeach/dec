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

# Analytic_CirculationPDI
#
# Parameters (optional)
#
# CENTER=PAC1|PAC2
#
# analytic_E2E -p "START_UTC=2015-09-10T01:00:00;STOP_UTC=2015-09-10T02:00:00" -a CirculationMSI -A "CENTER=PAC1|PAC2"

require 'e2e/AnalyticGeneric'

module E2E

class Analytic_E2E < AnalyticGeneric

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(arguments, parameters, debug = false)
      
      @baseline   = nil
      @arguments  = self.getArguments(arguments)
      
      processArguments
      
      if debug == true then
         self.setDebugMode
      end
      
      @hEvents          = Array.new
      @hAnnotations     = Array.new
      
      super(["DATA-ARCHIVED"], parameters, debug)
            
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "Analytic_CirculationMSI debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Process optional arguments supplied to the analytic
   
   def processArguments
      @center = ""  
      if @arguments == nil then
         @center = "pac1"
         return
      end
      
      bArgument = false
      
      @arguments.each{|key, value|
         if key.upcase == "CENTER" then
            @center     = value.to_s.downcase
            bArgument   = true
         end        
      }
      
      if bArgument == false then
         puts "Error in Analytic_CirculationMSI::processArguments"
         puts "arguments not supported"
         puts @arguments
         puts
      end

   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   def analysis
      # -------------------------------- 
      # Keep the initial query period
      queryStartDate = @queryStartDate
      queryStopDate  = @queryStopDate
      queryStartStr  = @queryStartStr
      queryStopStr   = @queryStopStr
      # --------------------------------
      
      arrEvents      = self.filterExplicitReference(@hEvents["DATA-ARCHIVED"], "OPER_MSI_L")
      arrEvents      = self.removeExplicitReference(arrEvents, "MSI_L1A_DS")
      arrEvents      = self.removeSystem(arrEvents, "PAC1")
      arrEvents      = self.removeSystem(arrEvents, "PAC2")
      arrEvents      = self.removeExplicitReference(arrEvents, "DS_EPA_")
      arrEvents      = self.uniqueExplicitReference(arrEvents)   
      # writeToConsole(arrEvents)
      
      arrAnnotations = self.filterExplicitReference_Annotations(@hAnnotations["DATA-ARCHIVED"], "OPER_MSI_L")
      arrAnnotations = self.filterValue_Annotations(arrAnnotations, "REP_OPDC__")
      # writeToConsole_Annotations(arrAnnotations)
      
      arrMissingDC   = Array.new     
      numPAC         = 0
      totalDS        = arrEvents.length
      
      arrEvents.each{|event|
         puts "Analysis of #{event[:explicit_reference]}"
         annotations = findByExplicitReference_Annotations(arrAnnotations, event[:explicit_reference])
                  
         if annotations.empty? == false then         
            result = self.filterValue_Annotations(annotations, @center)
            if result.empty? == true then
               puts "#{event[:explicit_reference]} no evidence of circulation towards #{@center.upcase}"
               arrMissingDC << event[:explicit_reference]
            else
               # writeToConsole_Annotations(result)
               puts result[0][:value]
               numPAC = numPAC + 1
            end  
         else
            puts "#{event[:explicit_reference]} missing circulation report referring to this DS"
            arrMissingDC << event[:explicit_reference]
         end
      }
      
      puts
      puts 
      puts "Percentage #{((numPAC/totalDS.to_f)*100.0).round(2)}% / Total DS #{totalDS} / Circulated DS #{numPAC} / Missing #{totalDS-numPAC}"
      puts
      puts "Missing DC #{arrMissingDC.uniq.length}"
      puts
      
      # ----------------------------------------------------
      
      arrEvents      = self.filterSystem(@hEvents["DATA-ARCHIVED"], @center.upcase)
      arrEvents      = self.filterExplicitReference(arrEvents, "OPER_MSI_L")
      arrEvents      = self.removeExplicitReference(arrEvents, "MSI_L1A_DS")
      arrEvents      = self.removeExplicitReference(arrEvents, "DS_EPA_")
      arrEvents      = self.uniqueExplicitReference(arrEvents)

      # writeToConsole(arrEvents)


      puts "------------------------------------------------"
      puts "cross-check with DS archived at #{@center.upcase}"
      
      arrAnnotations = self.filterExplicitReference_Annotations(@hAnnotations["DATA-ARCHIVED"], "OPER_MSI_L")
      arrAnnotations = self.filterName_Annotations(arrAnnotations, "AI-#{@center.upcase}-ARCHIVING-TIME")
      arrArchived    = Array.new
      
      arrMissingDC.each{|ds|
         
         ev = self.findByExplicitReference(arrEvents, ds)
         
         if ev != nil then
            puts
            puts "#{ds} is however archived at #{@center.upcase}"
            puts ev
            puts
            arrArchived << ds
            next
         end
         
         an = findByExplicitReference_Annotations(arrAnnotations, ds)
         
         if an.empty? == false then
            puts
            puts "#{ds} is however archived at #{@center.upcase}"
            puts an
            puts
            arrArchived << ds            
            next
         end
         
      }
           
      puts
      puts arrArchived.length
      puts
      
      # ----------------------------------------------------
      puts
      puts "Final missing in center #{@center.upcase}:"

      arrMissingDC.each{|ds|
         if arrArchived.include?(ds) == false then
            puts "#{ds}" 
         end
      }       
      # ----------------------------------------------------
     
      puts 
      puts "Percentage #{((numPAC/totalDS.to_f)*100.0).round(2)}% / Total DS #{totalDS} / Circulated DS #{numPAC} / Missing #{totalDS-numPAC}"
      puts
      puts "Missing DC #{arrMissingDC.uniq.length}"
      puts
      
      # writeToExcel(arrResults)

   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
      
end # class

end # module
