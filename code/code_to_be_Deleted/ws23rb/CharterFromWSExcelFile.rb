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
require 'spreadsheet'
require 'gruff'
require 'ws23rb/WS_PlugIn_Loader'

module WS23RB

class CharterFromWSExcelFile

   attr_reader :date, :time, :temperature_indoor, :temperature_outdoor, :humidity_indoor,
       :dewpoint, :forecast, :humidity_outdoor, :pressure, :rain_1hour, :windchill,
       :wind_direction, :wind_speed
   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename = "", prefix = "", debug = false)
      @filename            = filename
      @prefix              = prefix
      @isDebugMode         = debug
      @book                = Spreadsheet.open(@filename)
      @sheet               = @book.worksheet 0
      checkModuleIntegrity
      loadData
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "CharterFromWSExcelFile debug mode is on"
   end
   #-------------------------------------------------------------
   
   def generateCharts
      arrHeader      = @sheet.row(0)
      iCol           = 0
      arrHeader.each{|field|
         if field.downcase != "date" and field.downcase != "time" then
            generateGraphic(field, iCol)
         end
         iCol = iCol + 1
      }

   end
   #-------------------------------------------------------------

   def loadData
      strVble        = ""
      @arrVbles      = Array.new
      arrHeader      = @sheet.row(0)
      iCol           = 0
      totCols        = arrHeader.length
      @colDate       = nil
      @colTime       = nil
      @arrDateTime   = Array.new

      arrHeader.each{|field|
         @arrVbles << eval("arrData#{iCol} = Array.new")
         
         if field.downcase == "date" then
            @colDate = iCol
         end

         if field.downcase == "time" then
            @colTime = iCol
         end

         iCol = iCol + 1
      }

      if @colDate == nil then
         puts "Error, column date not found in excel-sheet"
         exit(99)
      end

      if @colTime == nil then
         puts "Error, column time not found in excel-sheet"
         exit(99)
      end
     

      iCol = 0
      @sheet.each{|row|
         row.each{|col|
            if col == nil then
               iCol = iCol + 1
               next
            end
            if col.to_s.include?(".") == true then
               @arrVbles[iCol%totCols] << col.to_s.to_f
            else
               @arrVbles[iCol%totCols] << col
            end            
            iCol = iCol + 1
         }
      }

      arrDates = @arrVbles[@colDate]
      arrTimes = @arrVbles[@colTime]

      arrDates.delete_at(0)
      arrTimes.delete_at(0)

      index = 0
      arrDates.each{|aDate|
         strValue = "#{aDate} #{arrTimes[index]}"
         @arrDateTime << strValue
         if @isDebugMode == true then
            puts strValue 
         end
         index = index + 1
      }

   end
   #-------------------------------------------------------------
   
private

   def initVariables
      return
   end
   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      if bCheckOK == false then
        puts "CharterFromWSExcelFile::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   # Load the file into the internal struct File defined in the
   def generateGraphic(field, column)

      if @isDebugMode == true then
         puts field
      end

      tot = @arrVbles[@colDate].size      
      arrData = @arrVbles[column]
      arrData.delete_at(0)

      if arrData[0].class.to_s.downcase == "string" then
         if @isDebugMode == true then
            puts "skipping #{field}"
         end
         return
      end

      g = Gruff::Line.new
      g.title = "#{field.to_s.upcase} Evolution #{@arrVbles[@colDate][0]}"

      arrData.delete("ERROR")
      
      field_unit = ""

      plugIn = WS23RB::WS_PlugIn_Loader.new(field, @isDebugMode)
      if plugIn.isPlugInLoaded? == false then
          plugIn = nil
      else
         field_unit = "in #{plugIn.unit}"
      end

      g.data("#{field} #{field_unit}", arrData)

      hAttr    = Hash.new
      idx      = 0
      prevTime = ""

      @arrVbles[@colTime].each{|aTime|
         if aTime.slice(0,2) == prevTime then
            hAttr[idx] = " "
         else
            hAttr[idx]  = aTime.slice(0,2)
            prevTime    = aTime.slice(0,2)
         end
         idx = idx + 1
      }

      g.labels = hAttr

      g.legend_font_size   = 10
      g.marker_font_size   = 12
      g.title_font_size    = 16

      g.write("#{@prefix}#{field}.png")      
      
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------

end # class

end # module
