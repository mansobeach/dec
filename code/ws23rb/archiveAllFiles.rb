#!/usr/bin/env ruby

# == Synopsis
#
# This is a command line tool that blah blah blah
#
# == Usage
# archiveAllFiles.rb  --time <start>,<stop> --parameters par1,par2
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

   prevDir = Dir.pwd

   workdir = "/Users/borja/Projects/weather/data/intray"

   Dir.chdir(workdir)

   arrFiles = Dir["METEO_CASALE_2*.xml"]

   arrFiles.each{|aFile|
      cmd = "minArcStore.rb -t METEO_DAILY_XML -f #{workdir}/#{aFile} -d"
      puts cmd
      system(cmd)
   }

   Dir.chdir(prevDir)

end

#---------------------------------------------------------------------

def process

   @isDebugMode   = true

   arrMinResults  = Array.new
   arrMaxResults  = Array.new

   prevDir  = Dir.pwd
   archDir  = ENV['MINARC_ARCHIVE_ROOT']
   arrDirs  = Array.new
   arrFiles = Array.new

   @timeInterval.each{|aTime|
      arrDirs << "#{archDir}/METEO_DAILY_V_XLS/#{aTime.slice(0,4)}/#{aTime.slice(4,2)}"
   }

   arrDirs.each{|aDir|
      if @isDebugMode == true then
         puts aDir
      end
      
      begin
         Dir.chdir(aDir)
      rescue Exception
         next
      end

      arrTmp   = Array.new
      arr      = Dir["*.xls"]
      arr.each{|aFile|
         arrTmp << "#{aDir}/#{aFile}"
      }

      arrFiles << arrTmp
   }

   arrFiles = arrFiles.flatten
#    dataDir = "#{archDir}/METEO_DAILY_V_XLS/#{@timeInterval[0].slice(0,4)}/#{@timeInterval[0].slice(4,2)}"
# 
#    Dir.chdir(dataDir)
# 
#    arrFiles = Dir["*#{@timeInterval[0]}*.xls"]
# 
#    # metVariable = "temperature_outdoor"

   metVariable = @parameters[0]

   arrFiles.each{|excelFile|

      if @isDebugMode == true then
         puts "processing #{excelFile}"
      end

      parser = WS23RB::WSExcelFileReader.new(excelFile, false)

      arr = parser.readVariable(metVariable)

      arrField = Array.new

      theMin   = 99999.99
      theMax   = -99999.99
      minDate  = nil
      minTime  = nil
      maxDate  = nil
      maxTime  = nil

      arr.each{|entry|

         if entry[2].to_f < theMin then
            theMin   = entry[2].to_f
            minDate  = entry[0]
            minTime  = entry[1]
         end

         if entry[2].to_f > theMax then
            theMax   = entry[2].to_f
            maxDate  = entry[0]
            maxTime  = entry[1]
         end
 
      }

      if @isDebugMode == true then
         puts "#{minDate} - #{minTime} - #{theMin}"
      end

      arrMinResults << [minDate, minTime, theMin]

      if @isDebugMode == true then
         puts "#{maxDate} - #{maxTime} - #{theMax}"
      end

      arrMaxResults << [maxDate, maxTime, theMax]

   }

   # Write Excel File

   Dir.chdir(prevDir)


   if @excelName == "" or @excelName == nil then
      if @isDebugMode == true then
         puts "No output excel-sheet specified"
      end
      exit(0)
   end

   if @isDebugMode == true then
      puts "Saving excel-sheet #{@excelName}"
   end


   excelWriter = WS23RB::WSExcelFileWriter.new(@excelName, true)

   arrHeader   = ["date", "time", "min_#{metVariable}"]

   excelWriter.createNewSheet("min_#{metVariable}", arrHeader, true)

   excelWriter.writeData(arrMinResults)

   arrHeader   = ["date", "time", "max_#{metVariable}"]

   excelWriter.createNewSheet("max_#{metVariable}", arrHeader, true)

   excelWriter.writeData(arrMaxResults)


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

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
