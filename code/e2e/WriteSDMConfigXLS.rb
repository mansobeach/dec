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
require 'write_xlsx'
require 'e2e/ReadGanttXML'
require 'e2e/ReadCSWResult'

module E2E

class WriteSDMConfigXLS

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(debug = false)
      @isDebugMode         = debug

      if @isDebugMode == true then
         self.setDebugMode
      end
            
      checkModuleIntegrity
      
      createNewExcel
         
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "WriteSDMConfigXLS debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Write to disk and close the excel-sheet
   def writeToDisk  
      @workbook.close
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------

   def writeNewSheet(name, items)
   
      sheet       = @workbook.add_worksheet(name)
      sheet.freeze_panes(1, 0)
      
      format      = @workbook.add_format
      format.set_bold
      format.set_text_wrap
      format.set_align('vcenter')
      format.set_bg_color('cyan')
      
      if items.empty? == true then
         return
      end
            
      # ------------------------------------------
      
      # Create header
      column      = 0
      row         = 1
      items[0].each_key{|key|
         sheet.write(0, column, key, format)
         sheet.set_column(column, 50)
         column = column + 1
      }
      
      # ------------------------------------------      
      items.each{|item|
         column      = 0
         item.each_pair{|key, value|
            sheet.write(row, column, value)
            column = column + 1
         }
         row = row + 1
      }
      # ------------------------------------------ 
            
   end
   #-------------------------------------------------------------

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
   
   #-------------------------------------------------------------

   def createNewExcel
      @workbook   = WriteXLSX.new("sdm_config_#{Time.now.strftime("%Y%m%dT%H%M%S")}.xlsx")    
      writeExcelProperties
      return @workbook
   end
   #-------------------------------------------------------------

   def writeExcelProperties
      @workbook.set_properties(
         :title    => 'Sentinel-2 E2E SDM Configuration',
         :author   => 'Borja Lopez Fernandez',
         :manager  => 'Olivier Colin',
         :company  => 'European Space Agency (ESA)',
         :comments => 'Created with E2ESPM @ ESRIN'
      )
   end

 
   #-------------------------------------------------------------
   #-------------------------------------------------------------

   def writeRow(row, event)
#    puts event
#    puts event.class
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
      @sheetGauges.write(row, @Column_System, event[:system])
      
      if @bCorrected == true then
         @sheetGauges.write(row, @Column_Gauge, "CORRECTED_#{event[:gauge_name]}")
      else
         @sheetGauges.write(row, @Column_Gauge, event[:gauge_name])
      end
      

      # -------------
      # date time cells
      
      date_format = @workbook.add_format(
                     #      :num_format => 'dd/mm/yy hh:mm:ss',
                           :num_format => 'dd/mm/yy hh:mm:ss.000',
                           :align      => 'left'
                           )
      
      strStart = ""
      strStop  = ""
      
      if event[:start].class.to_s == "DateTime" then
         # Handle dates as DateTime
         strStart = event[:start].strftime("%Y-%m-%dT%H:%M:%S.%L")
      else
         # Handle dates as string with miliseconds format
         strStart = event[:start].slice(0, 23)
      end

      if event[:stop].class.to_s == "DateTime" then
         # Handle dates as DateTime         
         strStop  = event[:stop].strftime("%Y-%m-%dT%H:%M:%S.%L")
      else
         # Handle dates as string with miliseconds format
         strStop  = event[:stop].slice(0, 23)                     
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
      
      # my_formula = %Q{(TIME( MID(#{my_cell},12,2), MID(#{my_cell}, 15, 2), MID(#{my_cell}, 18, 2) ) - TIME( MID(#{other_cell},12,2), MID(#{other_cell}, 15, 2), MID(#{other_cell}, 18, 2) ) )*24*60*60  }
      
      # formula for to understak miliseconds accuracy of start & stop fields
      # and report duration in seconds with 2 decimals
      
      my_formula = %Q{( (  VALUE( MID(#{my_cell},12,2) )*3600000 + \
                           VALUE( MID(#{my_cell}, 15, 2) )*60000 + \
                           VALUE( MID(#{my_cell}, 18, 2) )*1000 + \
                           VALUE( RIGHT(#{my_cell}, 3) )  ) - \
                        (  VALUE( MID(#{other_cell},12,2) ) *3600000 + \
                           VALUE( MID(#{other_cell}, 15, 2) )*60000 + \
                           VALUE( MID(#{other_cell}, 18, 2) )*1000 + \
                           VALUE( RIGHT(#{other_cell}, 3) ) ) )/1000 }

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

      if event[:explicit_reference].slice(33,1) == "T" then
         @sheetGauges.write_formula(row, @Column_Creation_Date, my_formula)
      else
         @sheetGauges.write(row, @Column_Creation_Date, "N/A")
      end
      
      # ----------------------
      # optional values in the result
      writeValues(row, @Column_Creation_Date + 1, event[:values], event[:value])
      # ----------------------
      
   end
   #-------------------------------------------------------------

   # Dirty-patch to write the optional array of values in the last columns 
   def writeValues(row, column, values, value)
      values.each{|a_value|
#          if a_value == value then
#             next
#          end
         @sheetGauges.write(row, column, a_value)
         column = column + 1
      }
   end
   #-------------------------------------------------------------
   
end # class

end # module
