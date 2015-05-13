#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to perform a connectivity check to 
# US core components deployed in the different centres

# == Usage
#  S2checkUS_Network.rb   
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --version             shows version number      
# 

# == Author
# Sentinel-2 PDGS Team (BL)
#
# == Copyleft
# ESA / ESRIN


# ------------------------------------------------------------------------------

require 'rubygems'
require 'getoptlong'

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------


# MAIN script function
def main


   @locker              = nil
   @product             = nil
   @isDebugMode         = false
   @isForceMode         = false

   opts = GetoptLong.new(
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT],
     ["--check", "-c",           GetoptLong::NO_ARGUMENT],
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt
            when "--file"     then @sadPDIdirectory            = arg.to_s
            when "--Debug"    then @isDebugMode                = true
            when "--excel"    then @bCreateExcel               = true
            when "--check"    then @bChkOrganisation           = true
            when "--version"  then
               print("\nESA - ESRIN ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--usage"   then usage
            when "--help"    then usage                        
         end
      end
   rescue Exception
      exit(99)
   end

   init

   @currentDir = Dir.pwd

   checkConnectivity
   
   Dir.chdir(@currentDir)
   
   exit(0)

end

#---------------------------------------------------------------------

def init
   @hHosts = Hash.new
   
#   @hHosts["PDMC.DAM1"]       = "https://pdmcdam1.sentinel2.eo.esa.int"
#   @hHosts["PDMC.DAM3"]       = "https://pdmcdam3.sentinel2.eo.esa.int"
   
   # -----------------------------------------------------------------
   # ESRIN
   @hHosts["PDMC.DAM2"]       = "https://pdmcdam2.sentinel2.eo.esa.int"
   @hHosts["PDMC.DAGB"]       = "https://pdmcdag.sentinel2.eo.esa.int"
   @hHosts["PDMC.DAGB1"]      = "https://pdmcdag1.sentinel2.eo.esa.int"
   @hHosts["PDMC.DAGB2"]      = "https://pdmcdag2.sentinel2.eo.esa.int"
   # -----------------------------------------------------------------

   # -----------------------------------------------------------------
   # MATERA
   @hHosts["CGS1.DAGS"]        = "https://cgs1dag.sentinel2.eo.esa.int"
   @hHosts["CGS1.DAGS1"]       = "https://cgs1dag1.sentinel2.eo.esa.int"
   @hHosts["CGS1.DAGS2"]       = "https://cgs1dag2.sentinel2.eo.esa.int"
   # -----------------------------------------------------------------

   # -----------------------------------------------------------------
   # SVALBARD
   @hHosts["CGS2.DAGS"]        = "https://cgs2dag.sentinel2.eo.esa.int"
   @hHosts["CGS2.DAGS1"]       = "https://cgs2dag1.sentinel2.eo.esa.int"
   @hHosts["CGS2.DAGS2"]       = "https://cgs2dag2.sentinel2.eo.esa.int"
   # -----------------------------------------------------------------

   # -----------------------------------------------------------------
   # MADRID
   @hHosts["PAC1.DAGB"]        = "https://pac1dag.sentinel2.eo.esa.int"
   @hHosts["PAC1.DAGS"]        = "https://pac1dag.sentinel2.eo.esa.int"
   @hHosts["PAC1.DAGS1"]       = "https://pac1dag1.sentinel2.eo.esa.int"
   @hHosts["PAC1.DAGS2"]       = "https://pac1dag2.sentinel2.eo.esa.int"
   # -----------------------------------------------------------------
 
   # -----------------------------------------------------------------
   # FARNBOROUGH
   @hHosts["PAC2.DAGB"]        = "https://pac2dag.sentinel2.eo.esa.int"
   @hHosts["PAC2.DAGS"]        = "https://pac2dag.sentinel2.eo.esa.int"
   @hHosts["PAC2.DAGS1"]       = "https://pac2dag1.sentinel2.eo.esa.int"
   @hHosts["PAC2.DAGS2"]       = "https://pac2dag2.sentinel2.eo.esa.int"
   # -----------------------------------------------------------------

   # -----------------------------------------------------------------
   # MPC/CC
   @hHosts["MPC.DAGS"]         = "https://mpccdag.sentinel2.eo.esa.int"
   @hHosts["MPC.DAGS1"]        = "https://mpccdag1.sentinel2.eo.esa.int"
   @hHosts["MPC.DAGS2"]        = "https://mpccdag2.sentinel2.eo.esa.int"
   # -----------------------------------------------------------------

  
end
#-------------------------------------------------------------
#-------------------------------------------------------------

def checkConnectivity

   @hHosts.each{|key, value|
      cmd = "curl --silent --connect-timeout 5 --max-time 100 -k #{value}"
      
      puts
      puts "Checking #{key}"
      
      if @isDebugMode == true then
         puts cmd
      end
      
      # ret = system(cmd)
   
       `#{cmd}`
   
      ret = $?.exitstatus.to_i
      
      if ret != 0 then
         puts "Error connecting to #{key} - #{value} - #{$?.exitstatus}"
      end
      
   }
   
end
#---------------------------------------------------------------------


#---------------------------------------------------------------------

def usage
   fullpathFile = `which #{File.basename($0)}`
   puts File.basename($0)
   puts fullpathFile
   system("head -22 #{fullpathFile}")
   exit
end

#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================

