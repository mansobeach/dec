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
   def initialize(filename = "", prefix = nil, chartName = nil, debug = false)
      @filename            = filename
      @prefix              = prefix
      @chartName           = chartName
      @isDebugMode         = debug
      @book                = Spreadsheet.open(@filename)

      @sheet               = @book.worksheet 0

      checkModuleIntegrity

      if @book.worksheets.length > 1 then
         @bMultipleSheets = true
         loadMData
      else
         @bMultipleSheets = false
         loadData
      end


   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "CharterFromWSExcelFile debug mode is on"
   end
   #-------------------------------------------------------------
   
   def generateMCharts
      generateMGraphics
   end
   #-------------------------------------------------------------

   def generateCharts
      
      if @bMultipleSheets == true then
         generateMCharts
         return
      end

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

   def loadMData
      strVble        = ""
      @arrVbles      = Array.new
      @arrFields     = Array.new
      idx            = 0

      @book.worksheets.each{|sheet|

         if @isDebugMode == true then
            puts "processing sheet #{sheet.name}"
         end

         @arrVbles[idx] = Array.new         
         arrHeader      = sheet.row(0)
         @arrFields << arrHeader
         iCol           = 0
         totCols        = arrHeader.length
         @colDate       = nil
         @colTime       = nil
         @arrDateTime   = Array.new

         arrHeader.each{|field|
            @arrVbles[idx] << eval("arrData#{iCol} = Array.new")
         
            if field.downcase == "date" then
               @colDate = iCol
            end

            if field.downcase == "time" then
               @colTime = iCol
            end

            iCol = iCol + 1
         }
         
         iCol = 0
      
         sheet.each{|row|
            row.each{|col|
               if col == nil then
                  iCol = iCol + 1
                  next
               end   
               if col.to_s.include?(".") == true then
                  @arrVbles[idx][iCol%totCols] << col.to_s.to_f
               else
                  @arrVbles[idx][iCol%totCols] << col
               end            
               iCol = iCol + 1
            }
         }
         idx = idx + 1

      }
      @arrFields = @arrFields.flatten.uniq
      @arrFields.delete("date")
      @arrFields.delete("time")
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
#          if @isDebugMode == true then
#             puts strValue 
#          end
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
   
   def generateMGraphics
      arrDates    = Array.new
      firstDate   = nil
      lastDate    = nil
      filename    = ""

      title       = ""
      arrTitle    = Array.new

      @arrFields.each{|aField|
       
         str = String.new(aField)
       
         if str.downcase.include?("min_") == true then
            arrTitle << str.gsub!("min_", "")
         end
  
         if str.downcase.include?("max_") == true then
            arrTitle << str.gsub!("max_", "")
         end
       
      }

      arrTitle = arrTitle.uniq

      title = "#{arrTitle}#{title}"

      g = Gruff::Line.new
      
      g.replace_colors ['blue', 'red']

      @arrVbles.each{|sheet|
         
         sheet.each{|column|

            if column[0] == "date" then
               firstDate = column[1]
               lastDate  = column[-1]
               arrDates  = column
            end

            if column[0] == "date" or column[0] == "time" then
               next
            end

            arrData  = column
            field    = arrData[0]

            arrData.delete_at(0)

            label = ""

            if field.include?("temperature") == true then
               label = "#{field} in degrees Celsius"
            else
               label = "#{field} TBD_Units"
            end

            g.data(label, arrData)
         }
      }


      hAttr    = Hash.new
      idx      = 0
      prevDate = ""
      prevTime = ""
      prvDate  = ""
 
      arrDates.delete("date")

      bMultiMonth = false

      if arrDates[0].slice(5,2) != arrDates[-1].slice(5,2) then
         bMultiMonth = true
         if @isDebugMode == true then
            puts "Multi-month excel-sheet detected"
         end
      end

      arrDates.each{|aDate|
         if aDate.slice(8,2) == prevDate then
            hAttr[idx] = " "
         else
            str = " "

            if prvDate.slice(5,2) != aDate.slice(5,2) and bMultiMonth == true then
               str = String.new(aDate.to_s)
               str = str.delete!("-")
               str = Date::MONTHNAMES[str.slice(4,2).to_i].to_s.slice(0,3)
            else
               if bMultiMonth == false then
                  str = aDate.slice(8,2)
               end
            end
 
            hAttr[idx]  = str
            prevDate    = aDate.slice(8,2)
         end
         prvDate = aDate
         idx = idx + 1
      }

      g.labels = hAttr

      if firstDate != lastDate then
         filename = "#{firstDate.delete!("-")}_#{lastDate.delete!("-")}.png"
      else
         filename = "DAILY_#{firstDate}.png"
      end

      # Logic filename to be revisited
      #
      if @prefix != nil then
         filename = "#{@prefix}_#{filename}"
      end

      if lastDate.include?(firstDate.slice(0,6)) == true and firstDate != lastDate then
         title = "#{title} #{Date::MONTHNAMES[firstDate.slice(4,2).to_i].upcase} #{firstDate.slice(0,4)}"
      else
         title = "#{title} Evolution"
      end

      g.title = title

      g.title_font_size    = 14
      g.legend_font_size   = 12
      g.marker_font_size   = 12

      g.hide_dots          = true
      g.dot_radius         = 1
      g.line_width         = 5


      if @chartName != nil then
         if @isDebugMode == true then
            puts "Saving #{@chartName}"
         end
         g.write(@chartName)    
      else
         if @isDebugMode == true then
            puts "Saving #{filename}"
         end
         g.write(filename)      
      end
      


   end
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

      g.baseline_color = "blue"
     

      bStats = false

      if field.downcase.include?("min_") == true then
         bStats = true
#          g.theme = {
#             :colors => %w(blue purple), # green white red #cccccc),
#             :marker_color => 'black',
#             :background_colors => ['black', '#4a465a']
# #            :background_colors => %w(black grey)
#             # :background_colors => %w(white grey)
#          }
      end


#       g.theme_37signals
# 
#       g.theme_greyscale
# 
#       g.theme_odeo

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
      prevDate = ""
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

      # MIN - MAX charts
      if bStats == true then
         hAttr    = Hash.new
         idx      = 0

         @arrVbles[@colDate].each{|aDate|
            puts aDate
            
            if aDate.slice(8,2) == prevDate then
               hAttr[idx] = " "
            else
               hAttr[idx]  = aDate.slice(8,2)
               prevDate    = aDate.slice(8,2)
            end
            idx = idx + 1
         }
      end


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
