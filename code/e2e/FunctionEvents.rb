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

require 'rubygems'
require 'date'

module E2E

module FunctionEvents

   #-------------------------------------------------------------

   def sortEvent_by_start(events)
      return events.sort!{|a,b| a[:start] <=> b[:start] }
   end
   #-------------------------------------------------------------

   def removeEventOverlaps(events)
      arrEv       = Array.new
      prevStart   = events[0][:start]
      prevStop    = events[0][:stop]
      bFirst      = true
   
      events.each{|event|
         start = event[:start]
         stop  = event[:stop]
      
#          puts "-------------"
#          puts prevStop
#          puts start
#          puts "-------------"
      
         if (bFirst == false) and (start < prevStop) then
#             puts "overlap detected"
#             puts "[#{prevStart},#{prevStop}] [#{start},#{stop}]"
            
            if prevStop > stop then
#                puts "Segment entirely contained in previous one / removing"
               next
            end
            
            
            arrEv << Struct::Event.new(event[:library], 
                                       event[:gauge_name], 
                                       event[:system], 
                                       prevStop, 
                                       event[:stop], 
                                       event[:value], 
                                       event[:explicit_reference],
                                       event[:values]
                                       )
            prevStart = start
            prevStop  = stop
            next
         end
      
         arrEv       << event
         bFirst      = false
         prevStart   = start
         prevStop    = stop

      }
      return arrEv
   end

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


end # module

end # module
