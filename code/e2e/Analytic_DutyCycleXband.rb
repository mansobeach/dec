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

      super(["MISSION_DUMP_OPERATION"], arguments, parameters, debug)
      
      @window_length  = 6000
      @duty_cycle     = 1500
      @arrOps         = Array.new
      @bFuture        = false
      
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "Analytic_XbandDutyCycle debug mode is on"
   end
   #-------------------------------------------------------------

   def usage
      puts "Analytic_DutyCycleXband::usage"
   end
   #-------------------------------------------------------------
   
   def analysis
      analysis_S2A
   end
   #-------------------------------------------------------------
   
   def analysis_S2A
   
      events      = self.filterSystem(@hEvents["MISSION_DUMP_OPERATION"], "Sentinel2A")
   
=begin
      events      = self.filterSystem(@hEvents["MISSION_PLAN_MMFU_OPERATION"], "Sentinel2A")
      events      = self.filterGauge(events, "PLAYBACK")     
      event1      = self.filterValue(events, "REGULAR")
      event2      = self.filterValue(events, "NOMINAL")
      event3      = self.filterValue(events, "NRT")
      events      = event1 + event2 + event3

=end   
   
      if events == nil then
         return false
      end
   
      accumulated    = 0
      window_start   = events[0][:start].to_time
      window_stop    = window_start + @window_length
         
#       puts
#       puts window_start
#       puts window_stop
#       puts
      
   
      events.each{|event|
      
         if accumulated < 0 then
            puts accumulated
            exit
         end
      
         
         puts "Total : #{accumulated}"
         
      
         duration = event[:stop].to_time - event[:start].to_time
            
         if duration > @duty_cycle then
            puts "Event starting #{event[:start]} does not respect 1.500s constraint"
         end

         if accumulated > @duty_cycle then
            puts "Accumulated duty cycle #{accumulated} with event starting #{event[:start]} does not respect 1.500s constraint"
            exit
         end
         
         
         if @isDebugMode == true then
            puts "--------------------"
            puts event[:start].to_time
            puts event[:stop].to_time
            puts duration
            puts "--------------------"
         end

         # ---------------------------------------
         #
         # Segment entirely outside the slidding window in the future
        
         
         if event[:start].to_time >= window_stop and \
            (event[:start].to_time - window_stop) <= @window_length then
         
         
            if @isDebugMode == true then
               puts
               puts "CASE#0 SHIFT WINDOW #{window_start} #{window_stop} / EV: #{event[:start].to_time} #{event[:stop].to_time}"
               puts
            end

            window_stop    = event[:start].to_time
            window_start   = window_stop - @window_length

            if @isDebugMode == true then
               puts
               puts "-------------------------------------------"
               puts "New Window #{window_start} - #{window_stop}"
               puts "-------------------------------------------"
               puts
            end

            @arrOps << event

            accumulated = computeDutyCycle(@arrOps, window_start)

            next   
         end
        
         # ---------------------------------------

          
         # ---------------------------------------
         #
         
         # Outside the slidding window
         # if event[:stop].to_time -  prev[:stop].to_time > @window_length then
         
         if event[:start].to_time - window_stop > @window_length then
         
            if @isDebugMode == true then
               puts
               puts "CASE#1 OUT WINDOW #{window_start} #{window_stop} / EV: #{event[:start].to_time} #{event[:stop].to_time}"
               puts
            end
         
            # No Pending events from previous iteration
            if @bFuture == false then
               @arrOps.clear
               @arrOps << event
               window_start = event[:start].to_time
               window_stop  = window_start + @window_length
               if @isDebugMode == true then       
                  puts
                  puts "-------------------------------------------"
                  puts "New Window #{window_start} - #{window_stop}"
                  puts "-------------------------------------------"
                  puts
               end
               accumulated  = duration            
            end
            
 
             # Pending events from previous iteration
            if @bFuture == true then
               @arrOps << event
               window_start = @bNewWindowStart
               window_stop  = window_start + @window_length            
               if @isDebugMode == true then   
                  puts
                  puts "Pending process of some FUTURE events"
                  puts
                  puts "-------------------------------------------"
                  puts "New Window #{window_start} - #{window_stop}"
                  puts "-------------------------------------------"
                  puts
               end
               accumulated  = computeDutyCycle(@arrOps, window_start)       
            end
                       
            next
         end
        
         # ---------------------------------------
        
         # ---------------------------------------
         #
         # Full coverage within the slidding window
        
         # if event[:stop].to_time - prev[:start].to_time < 1500 then
         
         if window_stop > event[:start].to_time and \
            (window_stop - event[:start].to_time) <= @window_length then
         
            if @isDebugMode == true then
               puts
               puts "CASE#2 FULL COVERAGE  WDW: #{window_start} - #{window_stop} / EV: #{event[:start].to_time} #{event[:stop].to_time}"
               puts
            end

            @arrOps << event

            accumulated = computeDutyCycle(@arrOps, window_stop - @window_length)

            next   
         end
        
         # ---------------------------------------
        
         # ---------------------------------------


         puts "CASE NOT SUPPORTED"
         exit
      }
      
      exit
   
   end
   
   #-------------------------------------------------------------
   
   def computeDutyCycle(events, start, stop = nil)
      
      @bFuture = false
      
      arrDel = Array.new
      
      if stop == nil then
         stop = start + @window_length
      end
      
      if @isDebugMode == true then
         puts
         puts "window duty cycle #{start} #{stop} / events #{events.length}"
         puts
      end
      
      accumulated = 0
      events.each{|event|
      
         if @isDebugMode == true then
            puts "dutycycle for #{event[:start].to_time} - #{event[:stop].to_time}"
         end
      
         if event[:start].to_time >= start and event[:stop].to_time <= stop then
            if @isDebugMode == true then
               puts "FULL    Event #{event[:start].to_time} -> #{(event[:stop].to_time - event[:start].to_time)}"
            end
            accumulated = accumulated + (event[:stop].to_time - event[:start].to_time)
            next
         end
 
         if event[:start].to_time < start and \
            event[:stop].to_time < start then
            if @isDebugMode == true then
               puts "REMOVED Event #{event[:start].to_time} - #{event[:stop].to_time}"
            end
            arrDel << event
            # @arrOps.delete(event)
            next
         end
         
         if event[:start].to_time < stop and \
            event[:stop].to_time > start and \
            event[:start].to_time < start then
            if @isDebugMode == true then
               puts "ENTRY PART Event #{event[:start].to_time} -> #{(event[:stop].to_time - start)}"
               # puts "PARTIAL Event #{event[:start].to_time} -> #{stop - (event[:start].to_time)}"
            end
#             puts stop
#             puts event[:stop].to_time
            accumulated = accumulated + (event[:stop].to_time - start)
            # accumulated = accumulated + (stop - event[:start].to_time)
            next
         end

         if event[:start].to_time < stop and \
            event[:stop].to_time > start and \
            event[:stop].to_time > stop then
            if @isDebugMode == true then
               # puts "ENTRY PART Event #{event[:start].to_time} -> #{(event[:stop].to_time - start)}"
               puts "EXIT PART Event #{event[:start].to_time} -> #{stop - (event[:start].to_time)}"
            end
#             puts stop
#             puts event[:stop].to_time
            # accumulated = accumulated + (event[:stop].to_time - start)
            accumulated = accumulated + (stop - event[:start].to_time)
            next
         end



         if event[:start].to_time >= stop then
            if accumulated != 0 then
               if @isDebugMode == true then
                  puts accumulated
                  puts "FUTURE  Event #{event[:start].to_time} - #{event[:stop].to_time}"
               end
               @bFuture = true
               @bNewWindowStart = event[:start].to_time
            else
               if @isDebugMode == true then
                  puts "RTIME   Event #{event[:start].to_time} - #{event[:stop].to_time}"
               end
               accumulated = accumulated + (event[:stop].to_time - event[:start].to_time)
            end
            next
         end
         
         puts
         puts "Error in computeDutyCycle"
         puts
         exit
         
      }
      
      @arrOps = @arrOps - arrDel
      
      return accumulated      
   end
   #-------------------------------------------------------------
   
         
   
end # class

end # module
