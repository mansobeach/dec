#!/usr/bin/env ruby


# == Synopsis
#
# This is the command line tool to extract data from the wsStation
#
# == Usage
#  convertGantXML2Excel.rb   -f <gantx.xml>
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --Force               forces a new execution
#     --version             shows version number      
# 
# == Author
# Borja Lopez Fernandez
#
# == Copyright
# Casale Beach


require 'getoptlong'
require 'writeexcel'

require 'e2e/ReadGanttXML'


# MAIN script function
def main

   @locker        = nil
   @isDebugMode   = false
   @bForce        = false
   @filename      = ""

   opts = GetoptLong.new(
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",          GetoptLong::NO_ARGUMENT],
     ["--file", "-f",           GetoptLong::REQUIRED_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt     
            when "--Debug"   then @isDebugMode = true
            when "--Force"   then @bForce    = true
            when "--file"    then @filename  = arg.to_s
            when "--version" then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--usage"   then fullpathFile = `which #{File.basename($0)}` 
                                  system("head -20 #{fullpathFile}")
                                  exit
            when "--help"    then fullpathFile = `which #{File.basename($0)}` 
                                  system("head -20 #{fullpathFile}")
                                  exit                    
         end
      end
   rescue Exception
      exit(99)
   end

   if @filename == "" then
      fullpathFile = `which #{File.basename($0)}` 
      system("head -20 #{fullpathFile}")
      exit
   end

   parser      = E2E::ReadGanttXML.new(@filename, @isDebugMode) 
   
   events      = parser.getEvents
   
   createNewExcel
   
   createSheetEvents
   
   row = 1

   
   events.each{|event|
#       puts "-------------------------------------------"
#       puts event[:library]
#       puts event[:gauge_name]
#       puts event[:system]
#       puts event[:start].slice(0, 23)
#       puts event[:stop].slice(0, 23)
#       puts event[:value]
#       puts event[:explicit_reference]
#       puts "-------------------------------------------"
      
      @sheetGauges.write(row, 0, event[:library])
      @sheetGauges.write(row, 1, event[:gauge_name])
      @sheetGauges.write(row, 2, event[:system])

      # -------------
      # date time cells
      
      date_format = @workbook.add_format(
                           :num_format => 'dd/mm/yy hh:mm:ss',
                           :align      => 'left'
                           )
      
      strStart = event[:start].slice(0, 19)
      strStop  = event[:stop].slice(0, 19)
      
      puts strStart
      puts strStop
      
#       @sheetGauges.write_date_time(row, 3, strStart, date_format)
#       @sheetGauges.write_date_time(row, 4, strStop, date_format)
      
      @sheetGauges.write(row, 3, strStart)
      @sheetGauges.write(row, 4, strStop)

      
      # -------------

      @sheetGauges.write(row, 5, event[:value])
      @sheetGauges.write(row, 6, event[:explicit_reference])
      
      row = row + 1
      
   }
   
   @workbook.close
      
   bReturn     = true

   if bReturn == true then
      exit(0)
   else
      exit(99)
   end

end
#---------------------------------------------------------------------

   #-------------------------------------------------------------

   def createNewExcel
      @workbook   = WriteExcel.new("e2e_events.xls")   
      return @workbook
   end
   #-------------------------------------------------------------

   def createSheetEvents
      @sheetGauges  = @workbook.add_worksheet
      @sheetGauges.freeze_panes(1, 0)
      format      = @workbook.add_format
      format.set_bold
      @sheetGauges.write(0, 0, "Library", format)
      @sheetGauges.write(0, 1, "Gauge_Name", format)
      @sheetGauges.write(0, 2, "System", format)
      
      # ------------------------------------------
      
      @sheetGauges.write(0, 3, "Start", format)
      @sheetGauges.write(0, 4, "End", format)
      
      # ------------------------------------------
      
      @sheetGauges.write(0, 5, "Value", format)
      @sheetGauges.write(0, 6, "Explicit_Reference", format)
   end
   #-------------------------------------------------------------
   




#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================

