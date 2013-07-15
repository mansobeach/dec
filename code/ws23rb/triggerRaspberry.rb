#!/usr/bin/env ruby

# == Synopsis
#
# This is a command line tool that blah blah
# 
# -f f1,f2,...,fn flag:
#
# fields
#
# == Usage
# triggerRTMeteoData.rb -f f1,f2,...fn | -a [-F <filename>]
#     --List         list all variables that can be read from meteo-station
#     --all          retrieves all variables
#     --File <file>  filename storing the information

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

require 'getoptlong'
# require 'rdoc/usage'

require 'ruby2300/ruby2300'
require 'ws23rb/WriteWSXMLFile'

include Ruby2300

# MAIN script function
def main

   @filename      = ""
   @isDebugMode   = false
   @fields        = Array.new
   @variables     = ["temperature_indoor","temperature_outdoor", "humidity_outdoor", "rain_1h", "rain_24h", 
                     "rel_pressure", "abs_pressure", "wind_pointing_degrees", 
                     "wind_direction", "wind_speed", "dewpoint"]

   opts = GetoptLong.new(
     ["--fields", "-f",         GetoptLong::REQUIRED_ARGUMENT],
     ["--File", "-F",           GetoptLong::REQUIRED_ARGUMENT],
     ["--all", "-a",            GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--List", "-L",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt
            when "--List"     then 
               puts @variables
               exit(0)
	         when "--File"     then @filename = arg.to_s
            when "--Debug"    then @isDebugMode = true
            when "--version"  then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
#            when "--usage"    then RDoc::usage("usage")
#            when "--help"     then RDoc::usage
	         when "--fields"   then @fields = arg.to_s.split(",")
            when "--all"      then @fields = @variables

         end
      end
   rescue Exception
      exit(99)
   end

   if @fields.empty? == true then
      exit(99)
      # RDoc::usage
   end

   configFile = "#{ENV['METEO_CONFIG']}/open2300.conf"

   if @isDebugMode == true then
      puts "opening config file #{configFile}"
   end

   open_weatherstation(configFile)

   hFields = Hash.new
   
   @fields.each{|field|
      if @variables.include?(field) == false then
         puts "#{field} is not a ws2300 variable"
         puts
         exit(99)
      end

      val = Ruby2300.send(field)

      hFields[field] = val
         
      if @isDebugMode == true then
         puts "#{field} - #{val}"
      end

   }

   if @filename == "" then
      exit(0)
   end

   writer = WriteWSXMLFile.new(@filename, @isDebugMode)

   writer.write(hFields)
 
   close_weatherstation

   sleep(1)

   exit(0)
end
#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
