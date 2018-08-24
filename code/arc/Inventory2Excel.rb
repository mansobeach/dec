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
require 'writeexcel'


module ARC

class Inventory2Excel

   include CUC::DirUtils
   #------------------------------------------------  
   
   # Class contructor
   def initialize(arrInvItems, fp_filename, debug = false)
      @arrInvItems         = arrInvItems
      @fp_filename         = fp_filename
      @isDebugMode         = debug
      checkModuleIntegrity
   end
   #------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "Inventory2Excel debug mode is on"
   end
   #------------------------------------------------

   # Main method of the class.
   def export(arrFields = Array.new)
      
      # Create new excel-sheet
      createNewExcel
      
      row = 1
      
      @arrInvItems.each{|item|
         if @isDebugMode == true then
            puts "#{item.filename} / #{item.path}"
         end
    
         arr = item.path.split("/").reverse[0] #.gsub!("_", " ").upcase.split(" ")
         
         # puts arr
         
         # exit
         
         str = ""
         
         1.upto((arr.length)-1) do |x| 
            str = "#{str} #{arr[x]}"
         end      
         
         @worksheet.write(row, 0, arr[0])
         @worksheet.write(row, 1, str)
         @worksheet.write(row, 2, item.filetype)
         @worksheet.write(row, 3, File.extname(item.filename).to_s.downcase.gsub!('.', ''))
         
         if item.filetype == "M2TS" or item.filetype == "AVI" or item.filetype == "MP4" then
            @worksheet.write(row, 4, item.filename.split("_")[1].split(".")[0].to_i)
         else
            @worksheet.write(row, 4, 0)
         end
         
         strLink = "file://#{item.path}/#{item.filename}"
         @worksheet.write_url(row, 5, strLink, item.filename)
          
         @worksheet.write_url(row, 6, "file://#{item.path}", str) 
          
         row = row + 1
         
      }
      
      closeExcel(row)
      
   end
   #------------------------------------------------

   #------------------------------------------------

private

   #-------------------------------------------------------------
   # Check that everything needed by the class is present.
   #-------------------------------------------------------------
   def checkModuleIntegrity
      return true
   end
   #--------------------------------------------------------
   
   def createNewExcel
      @workbook   = WriteExcel.new(@fp_filename)
      @worksheet  = @workbook.add_worksheet
      @worksheet.freeze_panes(1, 0)
      format      = @workbook.add_format
      format.set_bold
      format.set_text_wrap
      format.set_align('vcenter')
      format.set_bg_color('lime')
   
      @worksheet.write(0, 0, "DATE", format)
      @worksheet.set_column('A:A', 8, nil, true)
   
      @worksheet.write(0, 1, "EVENT", format)
      @worksheet.set_column('B:B', 40, nil, true)
      
      @worksheet.write(0, 2, "TYPE", format)
      @worksheet.set_column('C:C', 12)
      
      @worksheet.write(0, 3, "EXTENSION", format)
      @worksheet.set_column('D:D', 6)
      
      @worksheet.write(0, 4, "DURACION", format)
      @worksheet.set_column('E:E', 5, nil, true)
      
      @worksheet.write(0, 5, "FILE", format)
      @worksheet.set_column('F:F', 90)

      @worksheet.write(0, 6, "DIRECTORY", format)
      @worksheet.set_column('G:G', 40)
   
   end
   #-------------------------------------------------------------

   def closeExcel(iRow)
      strFilter = "A1:G#{iRow}"
      @worksheet.autofilter(strFilter)
      @workbook.close
   end
   #--------------------------------------------------------

end # class

end # module
#=================================================
