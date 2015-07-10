#!/usr/bin/env ruby


# == Synopsis
#
# This is the command line tool to prepare a delicious pudding of strawberry
#
# == Usage
#  convertCSWResult2Excel.rb   -f <csw_result.xml>
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
require 'benchmark'

require 'e2e/ReadCSWResult'
require 'e2e/WriteGanttXLS'



# MAIN script function
def main
   
   @locker        = nil
   @isDebugMode   = true
   @bForce        = false
   @filename      = ""
   @arrArgs       = Array.new(ARGV)

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
            when "--Debug"   then @isDebugMode  = true
            when "--Force"   then @bForce       = true
            when "--file"    then @filename     = "true"
            when "--version" then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--usage"   then usage 
            when "--help"    then usage
         end
      end
   rescue Exception
      exit(99)
   end

   if @filename == "" then
      usage
   end

   perf = Benchmark.measure{
      writer      = E2E::WriteGanttXLS.new(@isDebugMode)    
      writer.writeEventsCSWResult(@arrArgs)
   }
   
   printBenchmark(perf)
   
   exit(0)

   if bReturn == true then
      exit(0)
   else
      exit(99)
   end

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
#-------------------------------------------------------------

#---------------------------------------------------------------------

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

