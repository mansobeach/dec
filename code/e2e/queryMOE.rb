#!/usr/bin/env ruby

# == Synopsis
#
# This is a command line tool that blah blah blah
#
# == Usage
# queryMOE.rb  --query <get_MOE> --parameters par1=val1;par2=val2
#     --List                shows previously tested MOE
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

require 'e2e/CSWCreateQuery'
require 'e2e/CSWExecuteQuery'


# MAIN script function
def main

   @arrMOE = [ 
               "FOS_PLAN_MMFU_OPERATION",
               "FOS_PLAN_MSI_OPERATION",
               "ISP-GAPS",
               "MISSION_PLAN_MMFU_OPERATION",
               "MISSION_PLAN_MSI_OPERATION",
               "PLANNED-DFEP",
               "PLANNED-DUMP",
               "PLANNED-SIGNAL_CONTACT",
               "RAW-SCENE-VADILITY"
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
   @timeInterval     = nil
   @excelName        = ""
   @bIsSilent        = false
   @bVerify          = false
   @plugIn           = false
   
   opts = GetoptLong.new(
     ["--query", "-q",           GetoptLong::REQUIRED_ARGUMENT],
     ["--directory", "-d",       GetoptLong::REQUIRED_ARGUMENT],
     ["--Pattern", "-P",         GetoptLong::REQUIRED_ARGUMENT],
     ["--parameters", "-p",      GetoptLong::REQUIRED_ARGUMENT],
     ["--time", "-t",            GetoptLong::REQUIRED_ARGUMENT],
     ["--excel", "-e",           GetoptLong::REQUIRED_ARGUMENT],
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
            when "--parameters" then
               @parameters = getParameters(arg)
            when "--Silent"    then 
                  @bIsSilent = true
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


   @parameters.each{|key, val|
      puts key, val
   }

   query = E2E::CSWCreateQuery.new(@queryFile, @query, @parameters, @isDebugMode)

   E2E::CSWExecuteQuery.new(@queryFile, "result.xml", @isDebugMode)




#    if ret == false then
#       exit(9)
#    end

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
def list
   puts @arrMOE
   exit(0)
end

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
