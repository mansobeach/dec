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
# analytic_E2E -p "START_UTC=2015-09-10T01:00:00;STOP_UTC=2015-09-10T02:00:00" -a ReprocessingSensing -A "BASELINE=02.04"

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
      
      super(["DATA-ARCHIVED"], parameters, debug)
      
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "Analytic_ReprocessingSensing debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Process optional arguments supplied to the analytic
   
   def processArguments     
      bArgument = false
      if @arguments == nil then
         @baseline = "N02.04"
         return
      end
      @arguments.each{|key, value|
         if key.upcase == "BASELINE" then
            @baseline = "N#{value}"
            bArgument = true
         end        
      }
      if bArgument == false then
         puts "Error in Analytic_ReprocessingSensing::processArguments"
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
      arrResults     = Array.new
     
      arrArchived    = self.filterExplicitReference(@hEvents["DATA-ARCHIVED"], @baseline)
      
      if arrArchived.empty? == true then
         puts
         puts "No data has been archived with baseline #{@baseline} in the period"
         puts
         return false
      end
       
      arrArchived       = self.filterExplicitReference(arrArchived, "MSI_L1C_DS_EPA_")
      arrArchived       = self.uniqueExplicitReference(arrArchived)
      
      if arrArchived == nil or arrArchived.empty? then
         puts
         puts "No L1C generated in PAC1 with baseline #{@baseline.slice(1,5)} archived during [#{queryStartStr},#{queryStopStr}]"
         puts
         return false
      end
      
      sensingStartStr   = self.dsGetSensingStart(arrArchived[0][:explicit_reference])
      sensingStartDate  = self.str2date(sensingStartStr)
      sensingStopStr    = self.dsGetSensingStart(arrArchived[0][:explicit_reference])
      sensingStopDate   = self.str2date(sensingStopStr)

      if @isDebugMode == true then
         puts "Archived #{arrArchived.length} DS generated at PAC1 with baseline #{@baseline.slice(1,5)}"
      end

      arrConsideredDS = Array.new

      arrArchived.each{|ds|
         
         startStr       = self.dsGetSensingStart(ds[:explicit_reference])
         startDate      = self.str2date(startStr)          
         creationStr    = self.dsGetCreationTime(ds[:explicit_reference])
         creationDate   = self.str2date(creationStr)
         
         if @isDebugMode == true then
            puts "#{ds[:explicit_reference]} -> #{startStr}"
         end
         
         # -----------------------------
         # filter unexpected events from contingency ?
         if (creationDate.to_time < queryStartDate.to_time) or (creationDate.to_time > queryStopDate.to_time) then
            puts "#{ds[:explicit_reference]} / #{creationDate} out of query period [#{queryStartDate},#{queryStopDate}]"
            next
         end
         # -----------------------------
         
         if startDate < sensingStartDate then
            sensingStartStr   = startStr
            sensingStartDate  = startDate
         end 
         
         if startDate > sensingStopDate then
            sensingStopStr   = startStr
            sensingStopDate  = startDate
         end 
         arrConsideredDS << ds[:explicit_reference]
      }

      if @isDebugMode == true then
         puts
         puts "Total DS considered for archiving #{arrConsideredDS.length}"
         puts
         puts "New Query on DATA-SENSING.DS #{sensingStartStr} - #{sensingStopStr}"
         puts
      end

      params = buildQueryParameters(sensingStartStr, sensingStopStr)

      super(["DATA-SENSING.DS"], params, @isDebugMode)
                 
      arrReprocessed     = @hEvents["DATA-SENSING.DS"]      
      arrReprocessed     = self.filterExplicitReference(arrReprocessed, @baseline)
      arrReprocessed     = self.filterExplicitReference(arrReprocessed, "MSI_L1C_DS_EPA_")
      arrReprocessed     = self.filterValue(arrReprocessed, "REP_OPDPC_")
      
      arrConsideredDS2   = Array.new
      @totalSensing      = 0

      arrReprocessed.each{|ds|  
         # puts "Reprocessed #{ds[:explicit_reference]} datastrips with baseline #{@baseline}"
                   
         creationStr    = self.dsGetCreationTime(ds[:explicit_reference])
         creationDate   = self.str2date(creationStr)
                
         # -----------------------------
         # filter DS not generated within the query period
         if (creationDate.to_time < queryStartDate.to_time) or (creationDate.to_time > queryStopDate.to_time) then
            # puts "#{ds[:explicit_reference]} / #{creationDate} out of query period [#{queryStartDate},#{queryStopDate}]"
            next
         end
         # -----------------------------
      
         event = self.findByExplicitReference(arrArchived, ds[:explicit_reference])
      
         if event != nil then
            computeSensing(ds)
            arrConsideredDS2 << ds[:explicit_reference]
            ds[:values] << "ARCHIVE_TIME=#{event[:start]}"
            arrResults << ds
         else
            puts "#{ds[:explicit_reference]} not archived !"
         end
      }

      if @isDebugMode == true then
         puts "Total DS considered for reprocessing #{arrConsideredDS2.length}"
         puts
      end

      if arrConsideredDS2.sort !=  arrConsideredDS.sort then
         puts "Archived #{arrConsideredDS.length} and Reprocessed #{arrConsideredDS2.length} DS does not fit :-( !"
         puts
         puts arrConsideredDS - arrConsideredDS2
      end

      writeToExcel(arrResults)

      puts
      puts "Total sensing #{(@totalSensing/60.0).round(2)} minutes reprocessed during period [#{queryStartStr},#{queryStopStr}] for baseline #{@baseline.slice(1,5)}"
      puts
   end
   #-------------------------------------------------------------
   
   def computeSensing(event)
      if @isDebugMode == true then
         puts "Compute Sensing : #{event[:explicit_reference]} [#{event[:start]},#{event[:stop]}] => #{event[:stop].to_time - event[:start].to_time}"
      end
      @totalSensing = @totalSensing + (event[:stop].to_time - event[:start].to_time)
   end
   #-------------------------------------------------------------
      
end # class

end # module
