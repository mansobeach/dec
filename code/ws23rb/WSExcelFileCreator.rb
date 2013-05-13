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

class WSExcelFileCreator

   attr_reader :date, :time, :temperature_indoor, :temperature_outdoor, :humidity_indoor,
       :dewpoint, :forecast, :humidity_outdoor, :pressure, :rain_1hour, :windchill,
       :wind_direction, :wind_speed
   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename = "", targetFilename = "", debug = false)
      @filename            = filename
      @targetFilename      = targetFilename
      @isDebugMode         = debug
      @book                = Spreadsheet.open(@filename)
      @sheet               = @book.worksheet 0
      checkModuleIntegrity
      @targetbook          = Spreadsheet::Workbook.new()
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "WSExcelFileCreator debug mode is on"
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------

   def createDailySheets
      firstDate         = @sheet[1, @colDate].to_s.delete("-")
      createNewSheet(firstDate)
      
      @arrTargetDailySheets   = Array.new
      @arrTargetDailySheets   << firstDate
      nextDate                = firstDate
      prevDate                = nextDate
      theMin                  = 0
      theMax                  = 0
      theAvg                  = 0
      x                       = 0
      y                       = 0
      iRow                    = 0

      @sheet.each{|row|
         if x == 0 then
            x = x + 1
            next
         end
         prevDate = nextDate
         nextDate = row[@colDate].to_s.delete("-")

         if (prevDate != nextDate) then
            y = 0
            @arrHeader.each{|field|
               @hStatsVbles[y] << [prevDate, @hMinValues[y], @hMaxValues[y], @hAvgValues[y]/x.to_f]
               if @isDebugMode == true then
                   puts "New entry for #{field} in #{nextDate}"
                   puts @hStatsVbles[y].length
               end
             
               @hMinValues[y] = 9999.9
               @hMaxValues[y] = -1
               @hAvgValues[y] = 0.0

               y = y + 1
            }
            @arrTargetDailySheets  << nextDate
            createNewSheet(nextDate)
            x = 1
        
            if x != 1 then
               iRow = iRow + 1
            end
         end
        
         # -------------------------------------------------
         # For each row
         
         y = 0
         
         row.each{|col|
            currentValue = nil

            if col.to_s.upcase == "ERROR" then
               @targetsheet[x, y] = col
               y = y + 1
               next
            end

            if y != @colDate and y != @colTime then
               currentValue = col.to_f
            else
               currentValue = col
            end

            @targetsheet[x, y] = currentValue

            if y == @colDate or y == @colTime then
               # puts "skipping time or date"
               y = y + 1
               next
            end

            # Update minimum value
            if @hMinValues[y] > currentValue.to_f then
               @hMinValues[y] = currentValue.to_f
               if @isDebugMode == true then
                  puts "New minimum #{@hiColVbles.index(y)} is #{@hMinValues[y]}"
               end
            end

            # Update maximum value
            if @hMaxValues[y] < currentValue.to_f then
               @hMaxValues[y] = currentValue.to_f
               if @isDebugMode == true then
                  puts "New maximum #{@hiColVbles.index(y)} is #{@hMaxValues[y]}"
               end
            end

            # Update sum value
            @hAvgValues[y] = @hAvgValues[y] + currentValue.to_f 
            
            y = y + 1
         }
         x = x + 1
         # -------------------------------------------------

      }

      y = 0
      
      @arrHeader.each{|field|
         @hStatsVbles[y] << [prevDate, @hMinValues[y], @hMaxValues[y], @hAvgValues[y]/x.to_f]
         if @isDebugMode == true then
            puts "New entry for #{field} in #{nextDate}"
            puts @hStatsVbles[y].length
         end    
         y = y + 1
      }

      @targetbook.write(@targetFilename)
   end
   #-------------------------------------------------------------



   #-------------------------------------------------------------
   
   def createStatisticSheets
      @hStatsVbles.each{|key, value|
         if key == @colDate or key == @colTime then
            next
         end
                  
         if @isDebugMode == true then
            puts "creating sheet statistics_#{@hiColVbles.index(key)}"
         end
         sheet = createNewSheet("statistics_#{@hiColVbles.index(key)}", false)
         
         sheet[0, 0] = "date"
         sheet[0, 1] = "#{@hiColVbles.index(key)}_min"
         sheet[0, 2] = "#{@hiColVbles.index(key)}_max"
         sheet[0, 3] = "#{@hiColVbles.index(key)}_avg"

         row = 1
         
         value.each{|entry|
            sheet[row, 0] = entry[0]
            sheet[row, 1] = entry[1]
            sheet[row, 2] = entry[2]
            sheet[row, 3] = entry[3]
            row = row + 1
         }

         
      }
      
      @targetbook.write(@targetFilename)

         # Version with formulas
#          @arrTargetDailySheets.each{|dateSheet|
#             sheet[row, 0] = "=\'#{dateSheet}\'!#{@hsColVbles["date"]}2"
#             sheet[row, 1] = "=MIN(\'#{dateSheet}\'!#{@hsColVbles[col]}2:\'#{dateSheet}\'!#{@hsColVbles[col]}1000)"
#             sheet[row, 2] = "=AVG(\'#{dateSheet}\'!#{@hsColVbles[col]}2:\'#{dateSheet}\'!#{@hsColVbles[col]}1000)"
#             sheet[row, 3] = "=MAX(\'#{dateSheet}\'!#{@hsColVbles[col]}2:\'#{dateSheet}\'!#{@hsColVbles[col]}1000)"
#             row = row + 1
#          }

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
      @hStatsVbles   = Hash.new
      @hMinValues    = Hash.new
      @hMaxValues    = Hash.new
      @hAvgValues    = Hash.new
      iCol           = 0
      sCol           = "A"
      @arrHeader.each{|field|
         
         @hsColVbles[field]      = sCol
         @hiColVbles[field]      = iCol

         @hStatsVbles[iCol]      = Array.new

         @hMinValues[iCol] = 9999.9
         @hMaxValues[iCol] = -1
         @hAvgValues[iCol] = 0.0

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
        puts "WSExcelFileCreator::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   # Creates a new sheet
   def createNewSheet(name, bHeader = true)
      @targetsheet      = @targetbook.create_worksheet()
      @targetsheet.name = name
      if bHeader == false then
         @targetbook.write(@targetFilename)
         return @targetsheet
      end 
      iCol = 0
      @arrHeader.each{|field|
         @targetsheet[0, iCol] = field
         iCol = iCol + 1
      }
      @targetbook.write(@targetFilename)
      return @targetsheet
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------

end # class

end # module
