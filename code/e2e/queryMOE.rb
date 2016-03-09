#!/usr/bin/env ruby

# == Synopsis
#
# This is a command line tool that blah blah blah
#
# == Usage
# queryMOE.rb  --query <get_MOE> --parameters par1=val1;par2=val2
#     --file <output.xml>   filename of the result query
#     --List                shows previously tested MOE
#     --correctUTC          it corrects UTC times 
#                             with latest predicted orbit ephemeris
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
require 'benchmark'

require 'e2e/CSWCreateQuery'
require 'e2e/CSWExecuteQuery'


# MAIN script function
def main

   @arrMOE = [ 
               "CIRCULATION-INVENTORY-LTA-ERROR",
               "CORRECTED_FOS_DUMP_OPERATION",
               "CORRECTED_FOS_PLAN_CSM_OPERATION",
               "CORRECTED_FOS_PLAN_MMFU_OPERATION",
               "CORRECTED_FOS_PLAN_MSI_IMAGING_MODE",
               "CORRECTED_MISSION_DUMP_OPERATION",
               "CORRECTED_MISSION_PLAN_MMFU_OPERATION",
               "CORRECTED_MISSION_PLAN_MSI_IMAGING_MODE",
               "DATA-ARCHIVED",
               "DATA-VALIDITY",
               "DATA-VALIDITY.DS",
               "DATA-SENSING",
               "DATA-SENSING.DS",
               "FOS_DUMP_OPERATION",
               "FOS_PLAN_CSM_OPERATION",
               "FOS_PLAN_MMFU_OPERATION",
               "FOS_PLAN_MSI_IMAGING_MODE",
               "FOS_PLAN_MSI_OPERATION",
               "INGESTION_CONTROL_STAMP",
               "INGESTION_CONTROL_VALIDITY",
               "INGESTION-INVENTORY-LTA-ERROR",
               "ISP-GAPS",
               "LTA-ERROR",
               "MISSION_DUMP_OPERATION",
               "MISSION_PLAN_MMFU_OPERATION",
               "MISSION_PLAN_MSI_IMAGING_MODE",
               "MISSION_PLAN_MSI_OPERATION",
               "MSI-L0U",
               "ORBIT-PRED",
               "PDI-CIRCULATION",
               "PDI-CIRCULATION.POD",
               "PLANNED-DFEP",
               "PLANNED-DUMP",
               "PLANNED-SIGNAL_CONTACT",
               "RAW-SCENE-VADILITY",
               "REPORT-DUMP",
               "SAT_EXEC_MMFU_OPERATION",
               "SAT_EXEC_MSI_IMAGING_MODE",
               "SATELLITE-UNAVAILABILITY",
               "STATION-UNAVAILABILITY",
               "STEP-INFO",
               "VC-GAPS",
               "VC-VALIDITY"
            ]

   #=======================================================================

   def SIGTERMHandler
      puts "\n[#{File.basename($0)} #{@@mnemonic}] SIGTERM signal received ... sayonara, baby !\n"
      exit(0)
   end
   #=======================================================================

   
   @isDebugMode      = false
   @query            = ""
   @queryFile        = ""
   @directory        = ""
   @tmpDir           = ""
   @pattern          = ""
   @parameters       = nil
   @resultFile       = ""
   @bIsSilent        = false
   @bVerify          = false
   @plugIn           = false
   @bCorrectUTC      = false
   
   @arrArgs          = Array.new(ARGV)
   
   opts = GetoptLong.new(
     ["--query", "-q",           GetoptLong::REQUIRED_ARGUMENT],
     ["--directory", "-d",       GetoptLong::REQUIRED_ARGUMENT],
     ["--Pattern", "-P",         GetoptLong::REQUIRED_ARGUMENT],
     ["--parameters", "-p",      GetoptLong::REQUIRED_ARGUMENT],
     ["--time", "-t",            GetoptLong::REQUIRED_ARGUMENT],
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
     ["--correctUTC", "-U",      GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--Silent", "-S",          GetoptLong::NO_ARGUMENT],
     ["--Verify", "-V",          GetoptLong::NO_ARGUMENT],
     ["--List", "-L",            GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt     
            when "--Debug"   then @isDebugMode = true
            when "--version" then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--query" then
               @query = "get_#{arg}"
            when "--directory" then
               @directory = arg
            when "--file" then
               @resultFile = arg
            when "--parameters" then
               @parameters = getParameters(arg)
            when "--Silent"    then 
                  @bIsSilent = true
            when "--correctUTC" then 
                  @bCorrectUTC  = true
            when "--List"    then list
            when "--usage"   then usage
            when "--help"    then usage                      
         end
      end
   rescue Exception
      exit(99)
   end

   if @query == nil or @query == "" then
      usage
   end

   @queryFile = "query_#{@query}.xml"
   # @queryFile = "query.xml"


#    @parameters.each{|key, val|
#       puts key, val
#    }

   query = E2E::CSWCreateQuery.new(@queryFile, @query, @parameters, @bCorrectUTC, @isDebugMode)

   if @resultFile == "" then
      @resultFile = "result.xml"
   end


#    puts "-------------------------"
#    puts @parameters
#    puts "-------------------------"
# 
#    exit

   perf = Benchmark.measure{
      E2E::CSWExecuteQuery.new(@queryFile, @query, @resultFile, @bCorrectUTC, @isDebugMode)
   }
      
   printBenchmark(perf)

end

#---------------------------------------------------------------------

def getParameters(arg)
   hParam = Hash.new
   arr = arg.split(";")
   arr.each{|value|
      key = value.split("=")[0]
      val = value.split("=")[1]
      hParam[key] = val   
   }
   return hParam
end
#---------------------------------------------------------------------

#---------------------------------------------------------------------

# Print list of MOE verified for query
def list
   puts @arrMOE
   exit(0)
end
#---------------------------------------------------------------------

def printBenchmark(tms)
   puts "--------------------------------------------------------"
   puts
   puts "#{File.basename($0)} #{@arrArgs}"
   puts "User CPU          Time : #{tms.utime + tms.cutime}"
   puts "System CPU        Time : #{tms.stime + tms.cstime}"
   puts "Total             Time : #{tms.total}"
   puts "Elapsed           Time : #{tms.real}"
   puts "--------------------------------------------------------"
   puts
end
#-------------------------------------------------------------


# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}` 
   system("head -20 #{fullpathFile}")
   exit
end
#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
