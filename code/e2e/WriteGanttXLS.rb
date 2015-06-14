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

require 'date'
require 'writeexcel'
require 'write_xlsx'
require 'e2e/ReadGanttXML'
require 'e2e/ReadCSWResult'

module E2E


class WriteGanttXLS

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(debug = false)
      @isDebugMode         = debug
      if @isDebugMode == true then
         self.setDebugMode
      end
      @arrAttrNonReader    = ["filename", "isDebugMode", "arrAttrNonReader"]
      
      checkModuleIntegrity
      
      initColumns
      
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "WriteGanttXLS debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Process 
   def writeEvents(analytics)
      createNewExcel   
      createSheetEvents
   
      row = 1

      analytics.each{|element|
      
         if element.slice(0, 1) == "-" then
            next
         end
      
         puts element
      
         parser      = E2E::ReadGanttXML.new(element, @isDebugMode)    
         events      = parser.getEvents

         events.each{|event|
            writeRow(row, event)
            row = row + 1
         }
      }
      @workbook.close
   end
   #-------------------------------------------------------------
   
   def writeEventsCSWResult(analytics)
      createNewExcel   
      createSheetEvents
   
      row = 1

      analytics.each{|element|
      
         if element.slice(0, 1) == "-" then
            next
         end
      
         puts element
      
         parser      = E2E::ReadCSWResult.new(element, @isDebugMode)    
         events      = parser.getEvents

         events.each{|event|
            writeRow(row, event)
            row = row + 1
         }

      }
   
      @workbook.close
   
   end
   #-------------------------------------------------------------
   
private

   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      if bCheckOK == false then
         puts "WriteGanttXLS::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   # Creation of the Columns
   def initColumns
      @Column_Library               = 0
      @Column_Excel_Library         = 'A:A'
      @Column_Letter_Library        = 'A'

      @Column_Gauge                 = 1
      @Column_Excel_Gauge           = 'B:B'
      @Column_Letter_System         = 'B'

      @Column_System                = 2
      @Column_Excel_System          = 'C:C'
      @Column_Letter_System         = 'C'

      @Column_Start                 = 3
      @Column_Excel_Start           = 'D:D'
      @Column_Letter_Start          = 'D'

      @Column_End                   = 4
      @Column_Excel_End             = 'E:E'
      @Column_Letter_End            = 'E'

      @Column_Duration              = 5
      @Column_Excel_Duration        = 'F:F'
      @Column_Letter_Duration       = 'F'

      @Column_Value                 = 6
      @Column_Excel_Value           = 'G:G'

      @Column_Explicit_Ref          = 7
      @Column_Excel_Explicit_Ref    = 'H:H'
      @Column_Letter_Explicit_Ref   = 'H'
      
      @Column_Creation_Date         = 8
      @Column_Excel_Creation_Date   = 'I:I'
      
      
   end
   #-------------------------------------------------------------

   def createNewExcel
      # @workbook   = WriteExcel.new("#{Time.now.strftime("%Y%m%dT%H%M%S")}_e2e_events.xls")
      @workbook   = WriteXLSX.new("#{Time.now.strftime("%Y%m%dT%H%M%S")}_e2e_events.xlsx")    
      writeExcelProperties
      return @workbook
   end
   #-------------------------------------------------------------

   def writeExcelProperties
      @workbook.set_properties(
         :title    => 'Sentinel-2 PDGS Commissioning Report',
         :author   => 'Borja Lopez Fernandez',
         :manager  => 'Olivier Colin',
         :company  => 'European Space Agency (ESA)',
         :comments => 'Created with E2ESPM-ESRIN'
      )
   end
   #-------------------------------------------------------------

   def createSheetEvents
   
      @sheetGauges  = @workbook.add_worksheet
      @sheetGauges.freeze_panes(1, 0)
      
      format      = @workbook.add_format
      format.set_bold
      format.set_text_wrap
      format.set_align('vcenter')
      format.set_bg_color('lime')
      
      # ------------------------------------------      
            
      @sheetGauges.write(0, @Column_Library, "Library", format)
      @sheetGauges.set_column(@Column_Excel_Library, 10)
      
      # ------------------------------------------
      
      @sheetGauges.write(0, @Column_Gauge, "Gauge_Name", format)
      @sheetGauges.set_column(@Column_Excel_Gauge, 25)
      
      # ------------------------------------------
      
      @sheetGauges.write(0, @Column_System, "System", format)
      @sheetGauges.set_column(@Column_Excel_System, 10)
      
      # ------------------------------------------
      
      @sheetGauges.write(0, @Column_Start , "Start", format)
      @sheetGauges.set_column(@Column_Excel_Start , 18)
            
      @sheetGauges.write(0, @Column_End , "End", format)
      @sheetGauges.set_column(@Column_Excel_End , 18)
      
      # ------------------------------------------
      
      @sheetGauges.write(0, @Column_Duration, "Duration", format)
      @sheetGauges.set_column(@Column_Excel_Duration, 8)
      
      # ------------------------------------------
      
      @sheetGauges.write(0, @Column_Value, "Value", format)
      @sheetGauges.set_column(@Column_Excel_Value, 30)
      
      @sheetGauges.write(0, @Column_Explicit_Ref, "Explicit_Reference", format)
      @sheetGauges.set_column(@Column_Excel_Explicit_Ref, 70)
      
      @sheetGauges.write(0, @Column_Creation_Date, "Creation_Date", format)
      @sheetGauges.set_column(@Column_Excel_Creation_Date, 20)
      
   end
   #-------------------------------------------------------------

   def writeRow(row, event)
      #       puts "-------------------------------------------"
      #       puts event[:library]
      #       puts event[:gauge_name]
      #       puts event[:system]
      #       puts event[:start].slice(0, 23)
      #       puts event[:stop].slice(0, 23)
      #       puts event[:value]
      #       puts event[:explicit_reference]
      #       puts "-------------------------------------------"
      
      @sheetGauges.write(row, @Column_Library, event[:library])
      @sheetGauges.write(row, @Column_Gauge, event[:gauge_name])
      @sheetGauges.write(row, @Column_System, event[:system])

      # -------------
      # date time cells
      
      date_format = @workbook.add_format(
                           :num_format => 'dd/mm/yy hh:mm:ss',
                           :align      => 'left'
                           )
      
      strStart = ""
      strStop  = ""
      
      if event[:start].class.to_s == "DateTime" then
         # Handle dates as DateTime
         
         strStart = event[:start].strftime("%Y-%m-%dT%H:%M:%S")
         strStop  = event[:stop].strftime("%Y-%m-%dT%H:%M:%S")
      else
         # Handle dates as string
      
         strStart = event[:start].slice(0, 19)
         strStop  = event[:stop].slice(0, 19)      
      end

      if @isDebugMode == true then
         puts strStart
         puts strStop
      end
      
      # @sheetGauges.write_date_time(row, 3, strStart, date_format)
      # @sheetGauges.write_date_time(row, 4, strStop, date_format)
      
      @sheetGauges.write(row, 3, strStart)
      @sheetGauges.write(row, 4, strStop)

      # -------------
      
      my_cell    = %Q{#{@Column_Letter_End}#{row+1}}
      other_cell = %Q{#{@Column_Letter_Start}#{row+1}}
      
      my_formula = %Q{(TIME( MID(#{my_cell},12,2), MID(#{my_cell}, 15, 2), MID(#{my_cell}, 18, 2) ) - TIME( MID(#{other_cell},12,2), MID(#{other_cell}, 15, 2), MID(#{other_cell}, 18, 2) ) )*24*60*60  }
      
      numformat   = @workbook.add_format
      # numformat.set_bold
      numformat.set_text_wrap
      numformat.set_align('vcenter')
      # numformat.set_bg_color('lime')
      numformat.set_num_format('0.00')

      @sheetGauges.write_formula(row, @Column_Duration, my_formula, numformat)
      
      # -------------

      @sheetGauges.write(row, @Column_Value, event[:value])
      @sheetGauges.write(row, @Column_Explicit_Ref, event[:explicit_reference])
      
      # -------------
      
      other_cell = %Q{#{@Column_Letter_Explicit_Ref}#{row+1}}
      my_formula = %Q{MID(#{other_cell}, 26, 15)  }

      @sheetGauges.write_formula(row, @Column_Creation_Date, my_formula)
      
   end
   #-------------------------------------------------------------

   #-------------------------------------------------------------
   
end # class

end # module
