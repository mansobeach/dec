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
require 'ws23rb/WS_PlugIn_Loader'

module WS23RB

class WSExcelFileWriter

   attr_reader :date, :time, :temperature_indoor, :temperature_outdoor, :humidity_indoor,
       :dewpoint, :forecast, :humidity_outdoor, :pressure, :rain_1hour, :windchill,
       :wind_direction, :wind_speed
   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(targetFilename = "", debug = false)
      @targetFilename      = targetFilename
      @isDebugMode         = debug
      @book                = Spreadsheet::Workbook.new()
      @sheet               = @book.worksheet 0
      checkModuleIntegrity
      @targetbook          = Spreadsheet::Workbook.new()
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "WSExcelFileWriter debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Creates a new sheet
   def createNewSheet(name, arrHeader, bHeader = true)
      @targetsheet      = @targetbook.create_worksheet()
      @targetsheet.name = name
      if bHeader == false then
         @targetbook.write(@targetFilename)
         return @targetsheet
      end 
      iCol = 0
      arrHeader.each{|field|
         @targetsheet[0, iCol] = field
         iCol = iCol + 1
      }
      @targetbook.write(@targetFilename)
      return @targetsheet
   end
   #-------------------------------------------------------------

   # Write data
   def writeData(arrData, bHeader = true)
      nRow = 1
      if bHeader == false then
         nRow = 0
      end
      arrData.each{|row|
         nCol = 0
         row.each{|field|
            @targetsheet[nRow, nCol] = field
            nCol = nCol + 1
         }
         nRow = nRow + 1
      }
      @targetbook.write(@targetFilename)
   end

   #-------------------------------------------------------------

private

   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true

      if bCheckOK == false then
        puts "WSExcelFileWriter::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
   end
   #-------------------------------------------------------------
   



end # class

end # module
