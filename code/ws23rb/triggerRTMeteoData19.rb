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

require 'optparse'

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


   cmdOptions = {}

   begin
      OptionParser.new do |opts|

         opts.banner = "triggerRTMeteoData.rb -f f1,f2,...fn | -a [-F <filename>]"

         opts.on("-f", "--fields", "retrieves specified variables") do |v|
            cmdOptions[:fields] = true
            @fields = v.to_s.split(",")
         end

         opts.on("-a", "--all", "retrieves all variables") do |v|
            cmdOptions[:all] = true
            @fields = @variables
         end

         opts.on("-F", "--File", "filename to keep the information") do |v|
            cmdOptions[:filename] = v.to_s
            @filename = v.to_s
         end

         opts.on("-L", "--List", "list all meteo-station variables") do |v|
            cmdOptions[:list] = v
         end

         opts.separator ""
         opts.separator "Common options:"
         opts.separator ""
         
         opts.on("-D", "--Debug", "Run in debug mode") do
            cmdOptions[:debug] = true
            @isDebugMode = true
         end

         opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit(0)
         end

      end.parse!
   
   rescue Exception => e
      puts e.to_s
      exit(99)
   end

#    p cmdOptions
#    p ARGV

   if cmdOptions[:list] == true then
      puts @variables
      exit(0)
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
