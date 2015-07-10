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

require 'e2e/WriteGanttXLS'



# MAIN script function
def main

   @locker        = nil
   @isDebugMode   = true
   @bForce        = false
   @filename      = ""

   opts = GetoptLong.new(
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",          GetoptLong::NO_ARGUMENT],
     ["--file", "-f",           GetoptLong::REQUIRED_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   
     writer      = E2E::WriteGanttXLS.new(@isDebugMode)    
   
     writer.writeEvents(ARGV)
   
     exit(0) 
   
#     puts ARGV
#     exit
   
#    begin 
#       opts.each do |opt, arg|
#          case opt     
#             when "--Debug"   then @isDebugMode = true
#             when "--Force"   then @bForce    = true
#             when "--file"    then puts ARGV
#                                  exit
#             when "--version" then
#                print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
#                exit (0)
#             when "--usage"   then fullpathFile = `which #{File.basename($0)}` 
#                                   system("head -20 #{fullpathFile}")
#                                   exit
#             when "--help"    then fullpathFile = `which #{File.basename($0)}` 
#                                   system("head -20 #{fullpathFile}")
#                                   exit                    
#          end
#       end
#    rescue Exception
#       exit(99)
#    end

#    if @filename == "" then
#       fullpathFile = `which #{File.basename($0)}` 
#       system("head -20 #{fullpathFile}")
#       exit
#    end


   if bReturn == true then
      exit(0)
   else
      exit(99)
   end

end
#---------------------------------------------------------------------




#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================

