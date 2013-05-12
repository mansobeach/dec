#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #GapsExtractor class
#
# === Written by DEIMOS Space S.L. (rell)
#
# === SMOS NRTP Orchestrator
# 
# CVS: $Id: GapsExtractor.rb,v 1.2 2008/07/02 16:40:14 decdev Exp $
#
# module ORC
#
#########################################################################

require "cuc/DirUtils"
require "orc/ORC_DataModel"
require "rexml/document"

class GapsExtractor

   include CUC::DirUtils
   include REXML

   @type  = ""
   @start = nil
   @stop  = nil

   #================ Class contructor ================#

   def initialize(arrFiles, type, searchStart, searchEnd)
      if arrFiles != nil then
         @arrFiles = arrFiles
      else
         @arrFiles = Array.new
      end

      @type  = type
      @start = searchStart
      @stop  = searchEnd
      
   end

   #==================================================#

   def generateReport(reportName = "")

      @reportFullName = reportName

      arrBounds = Array.new
      arrBounds.push(@start)
      arrBounds.push(@stop)

      #Extract all bounds from file list
      @arrFiles.each{|aFile|
         
         start_bound = DateTime.parse(aFile.sensing_start.strftime("%Y%m%dT%H%M%S"))
         end_bound   = DateTime.parse(aFile.sensing_stop.strftime("%Y%m%dT%H%M%S"))

         # Consider this start-date as a bound if not already present
         if start_bound >= @start and start_bound <= @stop and arrBounds.include?(start_bound) == false then
            arrBounds.push(start_bound)
         end

         # Consider this end-date as a bound if not already present
         if end_bound >= @start and end_bound <= @stop and arrBounds.include?(end_bound) == false then
            arrBounds.push(end_bound)
         end

      }
      arrBounds.sort!

      #Create all the Intervals
      arrIntervals = Array.new

      (0..(arrBounds.length - 2)).each{|i|
         arrIntervals.push(Interval.new(i+1, arrBounds[i], arrBounds[i+1]))
      }

      # fill the intervals with apropriate files
      arrIntervals.each{|interval|
         @arrFiles.each{|aFile|
            interval.submitFile(aFile)
         }
      }

      writeReport(arrIntervals)
   end
   #-------------------------------------------------------------

   def extractIntervalsToConsole()
      arrBounds = Array.new

      #Extract all bounds from file list
      @arrFiles.each{|aFile|
         
         start_bound = DateTime.parse(aFile.sensing_start.strftime("%Y%m%dT%H%M%S"))
         end_bound   = DateTime.parse(aFile.sensing_stop.strftime("%Y%m%dT%H%M%S"))

         # Consider this start-date as a bound if not already present
         if arrBounds.include?(start_bound) == false then
            arrBounds.push(start_bound)
         end

         # Consider this end-date as a bound if not already present
         if arrBounds.include?(end_bound) == false then
            arrBounds.push(end_bound)
         end

      }
      arrBounds.sort!

      #Create all the Intervals
      arrIntervals = Array.new

      (0..(arrBounds.length - 2)).each{|i|
         arrIntervals.push(Interval.new(i+1, arrBounds[i], arrBounds[i+1]))
      }

      # fill the intervals with apropriate files
      arrIntervals.each{|interval|
         @arrFiles.each{|aFile|
            interval.submitFile(aFile)
         }
      }

      puts
      puts "Production timeline intervals for file-type '#{@type}'" 
      arrIntervals.each{|interval|
         puts interval.to_s
      }
      puts

   end

private

   def writeReport(arrIntervals)
         
      doc = Document.new 
      doc.add_element 'Timeline_Gaps_Report'
      doc << XMLDecl.new

#       # First Section : file names
#       efileList = Element.new "List_of_Files"
#       @arrFiles.each{|aFile|
#          eTmpName = Element.new "Name"
#          eTmpName.text = aFile.filename
#          efileList.elements << eTmpName
#       }
#       doc.root.elements << efileList

      #Second section : gaps
      offset = 0
      eGapsList = Element.new "List_of_Gaps"
      eGapsList.attributes["type"]    = @type
      eGapsList.attributes["stop"]    = @stop.strftime("%Y%m%dT%H%M%S")
      eGapsList.attributes["start"]   = @start.strftime("%Y%m%dT%H%M%S")
      
      arrIntervals.each{|interval|
         if interval.isEmpty? then
            eGap = Element.new "Gap"
            eGap.attributes["stop"]   = interval.getEndTime.strftime("%Y%m%dT%H%M%S")
            eGap.attributes["start"]  = interval.getStartTime.strftime("%Y%m%dT%H%M%S")
            eGap.attributes["number"] = (interval.getNum - offset).to_s

            eGapsList.elements << eGap
         else
            offset = offset + 1
            next
         end
      }
      doc.root.elements << eGapsList       

      file = File.open(@reportFullName, "w")
      doc.write(file, 2)
      file.close
   end
   #-------------------------------------------------------------

   class Interval

      def initialize(num, startTime, endTime)
         @num = num
         @startTime = startTime
         @endTime = endTime
         @arrContent = Array.new
      end

      def submitFile(aFile)

         file_start = DateTime.parse(aFile.sensing_start.strftime("%Y%m%dT%H%M%S"))
         file_stop = DateTime.parse(aFile.sensing_stop.strftime("%Y%m%dT%H%M%S"))

         if file_start <= @startTime and file_stop >= @endTime then
            @arrContent.push(aFile.id)
            return true
         else
            return false
         end
      end

      def isEmpty?
         return @arrContent.empty?
      end

      def getContent
         return @arrContent.sort
      end
   
      def getNum
         return @num
      end

      def getStartTime
         return @startTime
      end

      def getEndTime
         return @endTime
      end

      def to_s
         return "Interval #{@num} : #{@startTime} <--> #{@endTime} " + (@arrContent.empty? == true ? "(empty)" : "(#{@arrContent.length})")
      end

   end #Interval

end #

