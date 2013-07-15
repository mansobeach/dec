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
# readMeteo2300.rb -f f1,f2,...fn 
#     --List      list all variables that can be read from meteo-station


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

require 'ruby2300'
require 'getoptlong'
require 'rdoc/usage'

include Ruby2300

# MAIN script function
def main

   @isDebugMode   = false
   @fields        = Array.new
   @variables     = ["temperature_outdoor", "humidity_outdoor", "rain_1h", "rain_24h", 
                     "rel_pressure", "abs_pressure", "wind_pointing_degrees", "wind_direction"]

   opts = GetoptLong.new(
     ["--fields", "-f",       GetoptLong::REQUIRED_ARGUMENT],
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
            when "--Debug"    then @isDebugMode = true
            when "--version"  then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--usage"    then RDoc::usage("usage")
            when "--help"     then RDoc::usage
	         when "--fields"   then @fields = arg.to_s.split(",")

         end
      end
   rescue Exception
      exit(99)
   end

   if @fields.empty? == true then
      RDoc::usage
   end

   open_weatherstation("/Users/borja/Projects/weather/config/open2300.conf")

   
   @fields.each{|field|
      if @variables.include?(field) == false then
         puts "#{field} is not a ws2300 varible"
         puts
         exit(99)
      end
         
      if @isDebugMode == true then
         puts "#{field} - #{Ruby2300.send(field)}"
      end
   }




   exit

   puts $wind_direction_degrees
   puts

   puts $wind_direction_pointing
   puts


   puts temperature_outdoor
   puts

   puts temperature_indoor
   puts

   puts humidity_outdoor
   puts

   puts rain_24h
   puts

   puts rain_1h
   puts

   puts rel_pressure
   puts

   puts abs_pressure
   puts

   puts wind_all
   puts


   close_weatherstation
end
#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
