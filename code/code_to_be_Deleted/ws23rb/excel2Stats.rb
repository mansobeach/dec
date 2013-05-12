#!/usr/bin/env ruby

# == Synopsis
#
# This is a command line tool processes the input excel-file
# and generates another excel with daily sheets and summary sheets with stastistics
#
# == Usage
#   excel2Statistics.rb -s <input_excel.xls>
#     --source <filename>   input excel file
#     --excel <filename>    output excel file
#     --prefix              prefix name to the generated chart filenames
#     --silent              it executes in silent mode
#     --list                shows available meteo variables
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --version             shows version number      
# 
# == Author
# Borja Lopez Fernandez
#
# == Copyright
# Casale & Beach
#
require 'rubygems'
require 'getoptlong'
require 'rdoc/usage'
require 'ws23rb/WSExcelFileCreator'

# MAIN script function
def main

   #=======================================================================

   def SIGTERMHandler
      puts "\n[#{File.basename($0)} SIGTERM signal received ... sayonara, baby !\n"
      exit(0)
   end
   #=======================================================================

   
   @isDebugMode      = false 
   @excelName        = ""
   @sourceExcelName  = ""
   @bIsSilent        = false
   
   opts = GetoptLong.new(
     ["--directory", "-d",      GetoptLong::REQUIRED_ARGUMENT],
     ["--excel", "-e",          GetoptLong::REQUIRED_ARGUMENT],
     ["--source", "-s",         GetoptLong::REQUIRED_ARGUMENT],
     ["--prefix", "-p",         GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--Silent", "-S",         GetoptLong::NO_ARGUMENT],
     ["--list", "-l",           GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt     
            when "--Debug"   then @isDebugMode = true
            when "--version" then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--source" then
                  @sourceExcelName = arg
            when "--excel" then
                  @excelName = arg
            when "--prefix" then
                  @prefixName = arg
            when "--Silent"    then 
                  @bIsSilent = true 
            when "--usage"   then RDoc::usage("usage")
            when "--help"    then RDoc::usage                         
         end
      end
   rescue Exception
      exit(99)
   end


   if @excelName == "" or @sourceExcelName  == "" then
      RDoc::usage("usage")
   end
   
   if File.exist?(@sourceExcelName) == false then
      puts "#{@sourceExcelName} not found !"
      exit(99)
   end

   performProcessing

end

#---------------------------------------------------------------------

def performProcessing
   handler = WS23RB::WSExcelFileCreator.new(@sourceExcelName, @excelName, @isDebugMode)
   handler.createDailySheets
   handler.createStatisticSheets
end
#---------------------------------------------------------------------


#---------------------------------------------------------------------

#---------------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
