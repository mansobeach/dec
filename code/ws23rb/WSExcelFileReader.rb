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

# Modified 20120508

require 'rubygems'
require 'spreadsheet'
require 'ws23rb/WS_PlugIn_Loader'

module WS23RB

class WSExcelFileReader

   attr_reader :date, :time, :temperature_indoor, :temperature_outdoor, :humidity_indoor,
       :dewpoint, :forecast, :humidity_outdoor, :pressure, :rain_1hour, :windchill,
       :wind_direction, :wind_speed
   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename = "", debug = false)
      @filename            = filename
      @isDebugMode         = debug
      @book                = Spreadsheet.open(@filename, 'r')
      @sheet               = @book.worksheet 0
      checkModuleIntegrity
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "WSExcelFileReader debug mode is on"
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------

   def readVariable(variable)
      field       = variable
      arrVariable = Array.new
      if @arrHeader.include?(variable) == false then
         if @isDebugMode == true then
            puts "#{variable} not present in #{@filename}"
         end
      else
         
         bFirst = true

         @sheet.each{|row|
            
            if bFirst == true then
               bFirst = false
               next
            end

            value = row[@hiColVbles[field]]

            if value == "ERROR" then
               next
            end

            if @isDebugMode == true then
               puts "#{row[@colDate]} - #{row[@colTime]} - #{value}"
            end

            arrVariable << [row[@colDate], row[@colTime], value]

         }

      end

      return arrVariable

   end
   #-------------------------------------------------------------

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

      @arrHeader     = @sheet.row(0)
      totCols        = @arrHeader.length
      @colDate       = nil
      @colTime       = nil
      @arrDateTime   = Array.new
      @hsColVbles    = Hash.new
      @hiColVbles    = Hash.new
      iCol           = 0
      sCol           = "A"

      @arrHeader.each{|field|
         
         @hsColVbles[field] = sCol
         @hiColVbles[field] = iCol

         if field.downcase == "date" then
            @colDate = iCol
         end

         if field.downcase == "time" then
            @colTime = iCol
         end

         iCol = iCol + 1
         sCol = sCol.succ
      }

      if @colDate == nil then
         puts "Error, column date not found in excel-sheet"
         bCheckOK = false
      end

      if @colTime == nil then
         puts "Error, column time not found in excel-sheet"
         bCheckOK = false
      end

      if bCheckOK == false then
        puts "WSExcelFileReader::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
   end
   #-------------------------------------------------------------



   #-------------------------------------------------------------

   

   #-------------------------------------------------------------

end # class

end # module
