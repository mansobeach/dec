#!/usr/bin/env ruby

# == Synopsis
#
# This is a command line tool that performs regular tasks triggering command received
#
# == Usage
# reProcessAllMeteoFiles.rb  --directory <DIR> | --time <start>,<stop> --parameters par1,par2 [--Patern <PATTERN>] 
#     --time <start>,<stop> time specified as YYYYMMDDThhmmss
#     --excel <filename>    it generates an excel file with requested parameters
#     --Silent              it executes in silent mode
#     --Verify              it verifies the values according to threshold configuration
#     --List                shows available meteo variables
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
require 'getoptlong'
require 'rdoc/usage'
require 'spreadsheet'
require 'ws23rb/ReadWSXMLFile'
require 'ws23rb/WS_PlugIn_Loader'

# MAIN script function
def main

   #=======================================================================

   def SIGTERMHandler
      puts "\n[#{File.basename($0)} #{@@mnemonic}] SIGTERM signal received ... sayonara, baby !\n"
      exit(0)
   end
   #=======================================================================

   
   @isDebugMode      = false 
   @directory        = ""
   @tmpDir           = ""
   @pattern          = ""
   @parameters       = nil
   @timeInterval     = nil
   @excelName        = ""
   @bIsSilent        = false
   @bVerify          = false
   @plugIn           = false
   
   opts = GetoptLong.new(
     ["--directory", "-d",      GetoptLong::REQUIRED_ARGUMENT],
     ["--Pattern", "-P",        GetoptLong::REQUIRED_ARGUMENT],
     ["--parameters", "-p",     GetoptLong::REQUIRED_ARGUMENT],
     ["--time", "-t",           GetoptLong::REQUIRED_ARGUMENT],
     ["--excel", "-e",          GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--Silent", "-S",         GetoptLong::NO_ARGUMENT],
     ["--Verify", "-V",         GetoptLong::NO_ARGUMENT],
     ["--List", "-L",           GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt     
            when "--Debug"   then @isDebugMode = true
            when "--version" then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--directory" then
               @directory = arg
            when "--excel" then
               @excelName = arg
            when "--parameters" then
               @parameters = arg.split(",")
            when "--time" then
               @timeInterval = arg.split(",")
            when "--Pattern" then
               @pattern = arg
            when "--Silent"    then 
                  @bIsSilent = true
            when "--Verify"    then 
                  @bVerify = true
            when "--List" then
                  parser = ReadWSXMLFile.new
                  puts parser.listOfMeteoVariables
                  exit(0)
            when "--usage"   then RDoc::usage("usage")
            when "--help"    then RDoc::usage                         
         end
      end
   rescue Exception
      exit(99)
   end

   if @directory == "" and @timeInterval == nil then
      RDoc::usage("usage")
   end
 
   if @parameters != nil then
      checkParameters
   else
      RDoc::usage("usage")
   end
   
   if @timeInterval != nil then
      retrieveFromArchive
   end 

   @currentExecDir = Dir.pwd

   ret = performProcessing

#    if @tmpDir != "" then
#       cmd = "rm -rf #{@tmpDir}"
#       system(cmd)
#    end

   if ret == false then
      exit(99)
   end

end

#---------------------------------------------------------------------

def retrieveFromArchive

   if @isDebugMode == true then
      puts "Retrieving files from archive ..."
      puts
   end

   @tmpDir = "/tmp/#{Time.now.usec}"

   cmd = "mkdir -p #{@tmpDir}"
   system(cmd)

   cmd = "minArcRetrieve.rb -t METEO_DAILY_XML -H -s #{@timeInterval[0]} -e #{@timeInterval[1]} -L #{@tmpDir}"

   if @isDebugMode == true then
      puts cmd
   end

   system(cmd)

   @directory = @tmpDir

end
#---------------------------------------------------------------------

def performProcessing
   row      = 1
   column   = 0
   tot_cols = @parameters.length
   index    = tot_cols
   prevDir  = Dir.pwd
   Dir.chdir(@directory)

   arrFiles = Dir["REALTIME*.xml"].sort

   if arrFiles.empty? == true then
      puts "No files found for reprocessing"
      Dir.chdir(prevDir)
      return false
   end

   if @excelName != "" then
      initExcelFile
   end

   arrFiles.each{|aFile|

      if @isDebugMode == true then
         puts "Processing #{aFile}"
      end

      if File.extname(aFile) != ".xml" then
         puts "Skipping #{aFile}"
         next
      end 

      parser = ReadWSXMLFile.new("#{@directory}/#{aFile}") 
      
      @parameters.each{|param|

         val = parser.method(param).call()

         # ---------------------------------------
         
         if (param == "date" or param == "time") and (val == nil or val == "") then
            break
         end
         
         # ---------------------------------------
         # Quality Control on the parameters

         if @bVerify == true then
            @plugIn = WS23RB::WS_PlugIn_Loader.new(param, @isDebugMode)
            if @plugIn.isPlugInLoaded? == false then
               @plugIn = nil
            else
               if val == nil or val == "" then
                  puts "Flagging #{param} with empty value"
                  val = "ERROR"
                  # next
               else
                  if val == "N/A" then
                     puts "Discarding #{param} = #{val}"
                     val = "ERROR"
                  else
                     ret = @plugIn.verifyThresholds(val)
                     if ret == false then
                        puts "Discarding #{param} = #{val}"
                        val = "ERROR"
                     # next
                     end
                  end
               end
            end
         end
         # ---------------------------------------

         if @excelName != "" then
            @worksheet[row, column] = val
            row      = (index + 1) / tot_cols
            column   = (index + 1) % tot_cols
            index    = index + 1
         end
         if @bIsSilent == false then
            puts "#{param}: #{val}"
         end
      }

      if @bIsSilent == false then
         puts
      end
 
      # Remove processed file
      if @tmpDir != "" then
         cmd = "rm -f #{@directory}/#{aFile}"
            if @isDebugMode == true then
               puts cmd
            end
         system(cmd)
      end

   }

   if @excelName != "" then
      @workbook.write("#{@currentExecDir}/#{@excelName}")
   end

   Dir.chdir(prevDir)

end
#---------------------------------------------------------------------

def checkParameters
   parser = ReadWSXMLFile.new
   arrMeteoParams = parser.listOfMeteoVariables
   arrInputs      = Array.new
   arrInputs << @parameters
   arrInputs = arrInputs.flatten
   arrInputs.each{|param|
#       if @isDebugMode == true then
#          puts param
#       end
      if arrMeteoParams.include?(param) == false then
         puts "Parameter #{param} is not supplied by the ws-2300"
         exit(99)
      end
   }
end
#---------------------------------------------------------------------

def initExcelFile
   prevDir      = Dir.pwd
   Dir.chdir(@currentExecDir)
   @workbook    = Spreadsheet::Workbook.new()
   @worksheet   = @workbook.create_worksheet()

   bold_heading = Spreadsheet::Format.new :weight  => :bold,
                                          :size    => 12
                                          #:pattern_bg_color => "black", 
                                          #:pattern => 1

   headerRow   = @worksheet.row(0)
   column      = 0

   @parameters.each{|param|
      @worksheet[0, column] = param
      #headerRow.set_format(column,bold_heading)
      column = column + 1
   }
   @workbook.write("#{@currentExecDir}/#{@excelName}")
   Dir.chdir(prevDir)
end
#---------------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
