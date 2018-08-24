#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #ReportEditor class
#
# === Written by DEIMOS Space S.L. (rell)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: ReportEditor.rb,v 1.6 2008/11/26 12:40:02 decdev Exp $
#
# module MINARC
#
#########################################################################


require "rexml/document"

require 'cuc/DirUtils'

module ARC

class ReportEditor

   include CUC::DirUtils
   include REXML

   #================ Class contructor ================#

   def initialize(arrFiles)
      if arrFiles != nil then
         @arrFiles = arrFiles
      else
         @arrFiles = Array.new
      end
   end

   #==================================================#

   def generateReport(reportName = "")

      @reportFullName = reportName

      arrBounds = Array.new

      f_start = nil
      f_stop  = nil

      #Extract all bounds from file list
      @arrFiles.each{|aFile|
         
         # discard files with no valid start validity date
         if aFile.validity_start == nil then
            next
         else
            f_start = DateTime.parse(aFile.validity_start.strftime("%Y%m%d_%H%M%S"))
         end

         # Fix empty end validity dates
         if aFile.validity_stop == nil then
            f_stop = DateTime.parse("20800101_120000")
         else
            f_stop = DateTime.parse(aFile.validity_stop.strftime("%Y%m%d_%H%M%S"))
         end

         # Consider this start-date as a bound if not already present
         if arrBounds.include?(f_start) == false then
            arrBounds.push(f_start)
         end

         # Consider this end-date as a bound if not already present
         if arrBounds.include?(f_stop) == false then
            arrBounds.push(f_stop)
         end

      }
      arrBounds.sort!

      #One-bound-only patch
      if arrBounds.size == 1 then
         arrBounds.push(arrBounds[0])
      end

      #Create all the Intervals
      arrIntervals = Array.new

      (0..(arrBounds.length - 2)).each{|i|
         arrIntervals.push(Interval.new(i+1, arrBounds[i], arrBounds[i+1]))
      }

      # fill the intervals with apropriate files
      arrIntervals.each{|interval|
         @arrFiles.each{|aFile|
            
            # discard files with no valid start validity date
            if aFile.validity_start == nil then
               next
            end   

            interval.submitFile(aFile)
         }
      }

      writeReport(arrIntervals)
   end
   #-------------------------------------------------------------

private

   def writeReport(arrIntervals)
         
      doc = Document.new 
      doc.add_element 'MINARC_Report'
      doc << XMLDecl.new

      # First Section : file names
      efileList = Element.new "List_of_Files"
      @arrFiles.each{|aFile|
         eTmpName = Element.new "Name"
         eTmpName.text = aFile.filename
         efileList.elements << eTmpName
      }
      doc.root.elements << efileList

      #Second section : coverage segments
      offset = 0
      eCoverSegList = Element.new "List_of_CoverageSegments"
      arrIntervals.each{|interval|
         if interval.isEmpty? == false then
            arrSegFiles = interval.getContent
            eSegment = Element.new "CoverageSegment"
            eSegment.attributes["stop"]   = interval.getEndTime.strftime("%Y%m%dT%H%M%S")
            eSegment.attributes["start"]  = interval.getStartTime.strftime("%Y%m%dT%H%M%S")
            eSegment.attributes["number"] = (interval.getNum - offset).to_s
            arrSegFiles.each{|aFileName|
               eTmpName = Element.new "Name"
               eTmpName.text = aFileName
               eSegment.elements << eTmpName
            }
            eCoverSegList.elements << eSegment
         else
            offset = offset + 1
            next
         end
      }
      doc.root.elements << eCoverSegList       

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

         f_start = DateTime.parse(aFile.validity_start.strftime("%Y%m%d_%H%M%S"))
         # Fix empty end validity dates
         if aFile.validity_stop == nil then
            f_stop = DateTime.parse("20800101_120000")
         else
            f_stop = DateTime.parse(aFile.validity_stop.strftime("%Y%m%d_%H%M%S"))
         end 

         if f_start <= @startTime and f_stop >= @endTime then
            @arrContent.push(aFile.filename)
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

end #ReportEditor

end #module
