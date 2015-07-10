#!/usr/bin/env ruby

# == Synopsis
#
# This is a command line tool that blah blah blah
#
# == Usage
# analytic_MOE.rb  -t --m MOE1,MOE2 [-p par1=val1;par2=val2]
#     --trigger             it triggers the execution of the analytics
#     --moe <list_of_moe>   list of MOE to be analysed
#     --parameters <pars>
#     --list                shows all MOEs used
#     --List                shows all MOEs available
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --version             shows version number      
# 
# == Author
# Borja Lopez Fernandez
#
# == Copyleft
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
               "REPORT-DUMP"
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
   @bTrigger         = false
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
     ["--moe", "-m",             GetoptLong::REQUIRED_ARGUMENT],
     ["--excel", "-e",           GetoptLong::REQUIRED_ARGUMENT],
     ["--trigger", "-t",         GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--Silent", "-S",          GetoptLong::NO_ARGUMENT],
     ["--Verify", "-V",          GetoptLong::NO_ARGUMENT],
     ["--list", "-l",            GetoptLong::NO_ARGUMENT],
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
               @query = arg
            when "--directory" then
               @directory = arg
            when "--parameters" then
               @parameters = getParameters(arg)
            when "--moe" then
               @arrMOE = getMOE(arg)
            when "--trigger"   then 
                  @bTrigger = true
            when "--Silent"    then 
                  @bIsSilent = true
            when "--list"    then list
            when "--List"    then getList
            when "--usage"   then usage
            when "--help"    then usage                      
         end
      end
   rescue Exception
      exit(99)
   end

   if @bTrigger == false then
      puts "list of MOE configured:"
      puts @arrMOE
      exit(0)
   end

   @arrMOE.each{|moe|
      execute_MOE(moe)
   }

   cmd = "convertCSWResult2Excel.rb -f "

   @arrMOE.each{|moe|
      cmd = "#{cmd} /tmp/result_#{moe}.xml"
   }

   if @isDebugMode == true then
      puts cmd
   end
   
   system(cmd)

end

#---------------------------------------------------------------------
#---------------------------------------------------------------------
#---------------------------------------------------------------------

def execute_MOE(moe)
   if @parameters == "" or @parameters == nil then
      cmd = "queryMOE.rb -q #{moe} -p \"START_UTC=2000-07-07T00:00:00;STOP_UTC=2020-07-11T00:00:00\""
   else
      cmd = "queryMOE.rb -q #{moe} -p \"#{@parameters}\""
   end

   cmd = "#{cmd} -f /tmp/result_#{moe}.xml"

   if @isDebugMode == true then
      cmd = "#{cmd} -D"
      puts cmd
   end
   puts cmd
   system(cmd)
end

#---------------------------------------------------------------------

def getParameters(arg)
   return arg
end
#---------------------------------------------------------------------

def getMOE(arg)
   return arg.split(",")
end
#---------------------------------------------------------------------

# Print list of MOE verified for query
def list
   puts @arrMOE
   exit(0)
end
#---------------------------------------------------------------------

def getList
   cmd   = "queryMOE.rb -L"
   system(cmd)
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
