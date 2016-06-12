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
   cmdParser      = nil
   @filename      = ""
   @isDebugMode   = false
   @fields        = Array.new
   @variables     = [
                     "temperature_indoor",
                     "temperature_outdoor", 
                     "humidity_outdoor", 
                     "rain_1h", 
                     "rain_24h", 
                     "rel_pressure", 
                     "abs_pressure",
#                     "wind_pointing_degrees", 
                     "wind_direction", 
                     "wind_speed", 
                     "dewpoint"]


   cmdOptions = {}

   begin
      cmdParser = OptionParser.new do |opts|

         opts.banner = "triggerRTMeteoData.rb -f f1,f2,...fn | -a [-F <filename>]"

         opts.on("-D", "--Debug", "Run in debug mode") do
            cmdOptions[:debug] = true
            @isDebugMode = true
         end

         opts.on("-f s", "--fields=s", String, "retrieves specified variables") do |arg|
            cmdOptions[:fields] = arg.to_s.split(",")
            @fields = arg.to_s.split(",")
         end

         opts.on("-a", "--all", "retrieves all variables") do |v|
            cmdOptions[:all] = true
            @fields = @variables
         end

         opts.on("-F s", "--File=s", String, "filename to keep the information") do |arg|
            cmdOptions[:filename] = arg.to_s
            @filename = arg.to_s
         end

         opts.on("-L", "--List", "list all meteo-station variables") do |v|
            cmdOptions[:list] = v
         end

         opts.separator ""
         opts.separator "Common options:"
         opts.separator ""
         
         opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            return
         end

      end.parse!
   
   rescue Exception => e
      puts e.to_s
      exit(99)
   end

   if @isDebugMode == true then
      p cmdOptions
      p ARGV
   end

   if cmdOptions[:list] == true then
      puts @variables
      exit(0)
   end

   if cmdOptions[:all].nil? and cmdOptions[:fields].nil?
      puts "Run #{File.basename($0)} -h for help"
      puts
      exit(99)
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

      if @isDebugMode == true then
         puts "Reading #{field} ..."
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

#-------------------------------------------------------------

def usage
   fullpathFile = `which #{File.basename($0)}` 
   system("head -25 #{fullpathFile}")
   exit
end
#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
