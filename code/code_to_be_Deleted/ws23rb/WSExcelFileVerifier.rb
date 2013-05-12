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

class WSExcelFileVerifier

   attr_reader :date, :time, :temperature_indoor, :temperature_outdoor, :humidity_indoor,
       :dewpoint, :forecast, :humidity_outdoor, :pressure, :rain_1hour, :windchill,
       :wind_direction, :wind_speed
   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename = "", target = "", debug = false)
      @filename            = filename
      @targetName          = target
      @isDebugMode         = debug
      @book                = Spreadsheet.open(@filename)
      @sheet               = @book.worksheet 0
      checkModuleIntegrity
      @hErrors             = Hash.new
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "WSExcelFileVerifier debug mode is on"
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------

   def verify
      @hErrors = Hash.new
      verify_temperature
      verify_dewpoint
      return @hErrors
   end
   #-------------------------------------------------------------

   def createFlaggedExcel
      @hErrors.each{|row, column|
         if @isDebugMode == true then
            puts "Error in row #{row+1} column #{column+1}"
         end
         @sheet[row, column] = "ERROR"
      }
      saveUpdate
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
        puts "WSExcelFileVerifier::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
   end
   #-------------------------------------------------------------


   def verify_temperature
      @hiColVbles.each{|field,column|
     
        if field == "time" or field == "date" then
           next
        end

        if field.include?("temperature") == false then
           next
        end

        currTime        = Time.at(1970)
        currValue       = 0.0
        lastTrendValue  = 0.0
        bFirst          = true
        bOutTrend       = false
        bPrevError      = false

        @sheet.each{|row|

           if bFirst == true then
              bFirst = false
              next
           end

           rowDate = row[@colDate].to_s.delete("-")
           rowTime = row[@colTime].to_s.delete(":")

           rowYear  = rowDate.slice(0,4).to_i
           rowMonth = rowDate.slice(4,2).to_i
           rowDay   = rowDate.slice(6,2).to_i
           rowHour  = rowTime.slice(0,2).to_i
           rowMin   = rowTime.slice(2,2).to_i
           rowSec   = rowTime.slice(4,2).to_i

           prevTime = currTime
           currTime = Time.local(rowYear, rowMonth, rowDay, rowHour, rowMin, rowSec)

           if row[column] == "ERROR" then
              if @isDebugMode == true then
                 puts "skipping #{field} with ERROR at #{currTime}"
              end
              bPrevError = true
              next
           end

           prevValue = currValue
           currValue = row[column].to_f

           if bPrevError == true then
              bPrevError = false
              next
           end

           if bOutTrend == false then
              lastTrendValue = prevValue
           end

           if currTime.to_i > prevTime.to_i + 300 then
              if @isDebugMode == true then
                 puts "data gap between #{prevTime.strftime("%m/%d %H:%M:%S")} and #{currTime.strftime("%m/%d %H:%M:%S")}"
              end
              next
           end


           # Define threshold
           thresholdTemp = 0

           if currTime.to_i < prevTime.to_i + 301 then
              thresholdTemp = 2.8
           end

           if currTime.to_i < prevTime.to_i + 250 then
              thresholdTemp = 2.5
           end

           if currTime.to_i < prevTime.to_i + 150 then
              thresholdTemp = 1.8
           end

           if currTime.to_i < prevTime.to_i + 130 then
              thresholdTemp = 1.7
           end

           if currTime.to_i < prevTime.to_i + 100 then
              thresholdTemp = 1.5
           end

           if currTime.to_i < prevTime.to_i + 75 then
              thresholdTemp = 1.3
           end

           if currTime.to_i < prevTime.to_i + 65 then
              thresholdTemp = 1.1
           end


              if bOutTrend == true then
                 bOutTrend = false
                 
#                  if @isDebugMode == true then
#                     puts "#{field}: #{currValue} #{currTime}"
#                  end              
              
                 if (currValue - lastTrendValue).abs > thresholdTemp then
                    bOutTrend = true
                    # lastTrendValue = currValue
                    puts "#{field} [#{lastTrendValue} , #{currValue}] [#{prevTime.strftime("%H:%M:%S")} , #{currTime.strftime("%H:%M:%S")}] is out of trend #{thresholdTemp}"
                    @hErrors[row.idx] = column
                 else
                    lastTrendValue = currValue
                 end  
                 next
              end

              if (currValue - prevValue).abs > thresholdTemp then
                 puts "#{field} [#{prevValue} , #{currValue}] [#{prevTime.strftime("%H:%M:%S")} , #{currTime.strftime("%H:%M:%S")}] is out of trend #{thresholdTemp}"
                 bOutTrend = true
                 @hErrors[row.idx] = column
              end  
        
        }
      }
      return @hErrors
   end
   #-------------------------------------------------------------

   def verify_dewpoint
      @hiColVbles.each{|field,column|
     
        if field.include?("dewpoint") == false then
           next
        end

        currTime        = Time.at(1970)
        currValue       = 0.0
        lastTrendValue  = 0.0
        bFirst          = true

        bOutTrend = false

        @sheet.each{|row|

           if bFirst == true then
              bFirst = false
              next
           end

           rowDate = row[@colDate].to_s.delete("-")
           rowTime = row[@colTime].to_s.delete(":")

           rowYear  = rowDate.slice(0,4).to_i
           rowMonth = rowDate.slice(4,2).to_i
           rowDay   = rowDate.slice(6,2).to_i
           rowHour  = rowTime.slice(0,2).to_i
           rowMin   = rowTime.slice(2,2).to_i
           rowSec   = rowTime.slice(4,2).to_i

           prevTime = currTime
           currTime = Time.local(rowYear, rowMonth, rowDay, rowHour, rowMin, rowSec)

           if row[column] == "ERROR" then
              if @isDebugMode == true then
                 puts "skipping #{field} with ERROR at #{currTime}"
              end
              next
           end

           prevValue = currValue
           currValue = row[column].to_f

           if bOutTrend == false then
              lastTrendValue = prevValue
           end

           if currTime.to_i > prevTime.to_i + 300 then
              if @isDebugMode == true then
                 puts "data gap between #{prevTime.strftime("%m/%d %H:%M:%S")} and #{currTime.strftime("%m/%d %H:%M:%S")}"
              end
              next
           end


           # Define threshold
           thresholdTemp = 0

           if currTime.to_i < prevTime.to_i + 301 then
              thresholdTemp = 2.8
           end

           if currTime.to_i < prevTime.to_i + 250 then
              thresholdTemp = 2.5
           end

           if currTime.to_i < prevTime.to_i + 150 then
              thresholdTemp = 2.2
           end

           if currTime.to_i < prevTime.to_i + 130 then
              thresholdTemp = 2.0
           end

           if currTime.to_i < prevTime.to_i + 100 then
              thresholdTemp = 1.8
           end

           if currTime.to_i < prevTime.to_i + 75 then
              thresholdTemp = 1.7
           end

           if currTime.to_i < prevTime.to_i + 65 then
              thresholdTemp = 1.6
           end


              if bOutTrend == true then
                 bOutTrend = false
                 
#                  if @isDebugMode == true then
#                     puts "#{field}: #{currValue} #{currTime}"
#                  end              
              
                 if (currValue - lastTrendValue).abs > thresholdTemp then
                    bOutTrend = true
                    # lastTrendValue = currValue
                    puts "#{field} [#{lastTrendValue} , #{currValue}] [#{prevTime.strftime("%H:%M:%S")} , #{currTime.strftime("%H:%M:%S")}] is out of trend #{thresholdTemp}"
                    @hErrors[row.idx] = column
                 else
                    lastTrendValue = currValue
                 end  
                 next
              end

              if (currValue - prevValue).abs > thresholdTemp then
                 puts "#{field} [#{prevValue} , #{currValue}] [#{prevTime.strftime("%H:%M:%S")} , #{currTime.strftime("%H:%M:%S")}] is out of trend #{thresholdTemp}"
                 bOutTrend = true
                 @hErrors[row.idx] = column
              end  
        
        }
      }
      return @hErrors
   end
   #-------------------------------------------------------------

   #-------------------------------------------------------------

   
   def saveUpdate
      @book.write(@targetName)
   end

   #-------------------------------------------------------------

end # class

end # module
