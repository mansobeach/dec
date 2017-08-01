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

# X-band mission capacity

require 'e2e/AnalyticGeneric'
require 'mpl/ReadStationVisibility'

module E2E

class Analytic_E2E < AnalyticGeneric

   include CUC::Converters

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(arguments, parameters, debug = false)

      if debug == true then
         self.setDebugMode
      end

      super(nil, arguments, parameters, debug)
     
#       puts @parameters
#       puts @arguments
      
      processArguments
      
      @duty_limit = 25.0
      
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "Analytic_CapacityXband debug mode is on"
   end
   #-------------------------------------------------------------
   
   def processArguments
      @bArgument = false
      
      if @arguments == nil or @arguments == "" then
         return
      end
      
      @arguments.each{|key, value|
                 
         if key.dup.upcase! == "ORBIT_START_ABS" then
            @orbit_start_abs = value.to_i
            @bArgument = true
         end
         
         if key.dup.upcase! == "ORBIT_STOP_ABS" then
            @orbit_stop_abs = value.to_i
            @bArgument = true
         end
        
      }
      
      if @bArgument == false then
         puts "Arguments #{@arguments} not supported"
         exit(99)
      end
      
      
   end
   #-------------------------------------------------------------

   def usage
      puts "Analytic_CapacityXband::usage"
      puts "Optional arguments:"
      puts "orbit_start_abs=<value>"
      puts "orbit_stop_abs=<value>"
   end
   #-------------------------------------------------------------
      
   def analysis
      
      loadData
      
      puts "Analytic_CapacityXband::analysis"

      events  = self.sortEvent_by_start(@events)
      events  = self.removeEventOverlaps(events)

      prevOrbit = events[0][:value]
      
      sumTimeOrbit   = 0.0
      sumTimeTotal   = 0.0
      firstOrbit     = prevOrbit.to_i
      
      events.each{|event|
         if prevOrbit == event[:value] then
            sumTimeOrbit = sumTimeOrbit + ( event[:stop].to_time - event[:start].to_time )
         else
            if (sumTimeOrbit/60.0) > @duty_limit then
               puts "#{(sumTimeOrbit/(60.0)).round(2)} minutes exceeded the duty cycle / limit to #{@duty_limit}"
               sumTimeOrbit = 1500.0
            end
            puts "orbit #{prevOrbit} - #{(sumTimeOrbit/(60.0)).round(2)} minutes"
            sumTimeTotal   = sumTimeTotal + sumTimeOrbit
            sumTimeOrbit   = ( event[:stop].to_time - event[:start].to_time )
         end
         prevOrbit = event[:value]
      }
      puts "orbit #{prevOrbit} - #{(sumTimeOrbit/(60.0)).round(2)} minutes"
      
      lastOrbit = prevOrbit.to_i

      numOrbits = lastOrbit - firstOrbit + 1
      avgTime   = ((sumTimeTotal/60.0)/numOrbits).round(2)
      
      
      puts
      puts "Num Orbits #{numOrbits} / Average #{avgTime} minutes"

      puts "writing to excel raw visibilities"

      excel    = E2E::WriteGanttXLS.new
      excel.writeToExcel(@events)
      
      puts "writing to excel without overlaps"
      excel    = E2E::WriteGanttXLS.new
      excel.writeToExcel(events)
            
   end
   #-------------------------------------------------------------
   
   
private   

   #-------------------------------------------------------------
   
   def loadData
      prevDir = Dir.pwd
   
      Dir.chdir(ENV['DEC_BASE'])
      Dir.chdir("code/mpl")
   
      cmd = ""
      
      if @bArgument == true
         cmd = "mpl_xvstation_vistime --orbit-abs-start #{@orbit_start_abs} --orbit-abs-end #{@orbit_stop_abs}"
      else
         cmd = "mpl_xvstation_vistime --orbit-abs-start 10000 --orbit-abs-end 10143"
      end
      
      if @isDebugMode == true then
         puts
         puts Dir.pwd
         puts
         cmd = "#{cmd} -D"
         puts cmd
      end
      system(cmd)
      
      parse = MPL::ReadStationVisibility.new("../mpl/S2A_OPER_MPL_GNDVIS_GMASPABX.xml", true)
      eventsCGS4 = parse.getEvents

      parse = MPL::ReadStationVisibility.new("../mpl/S2A_OPER_MPL_GNDVIS_GMATERHX.xml", true)
      eventsCGS1 = parse.getEvents

      parse = MPL::ReadStationVisibility.new("../mpl/S2A_OPER_MPL_GNDVIS_GSVLBRHX.xml", true)
      eventsCGS2 = parse.getEvents

      @events   = eventsCGS1 + eventsCGS2 + eventsCGS4
      
      Dir.chdir(prevDir)
      
   end
   #-------------------------------------------------------------   
         
   
end # class

end # module
