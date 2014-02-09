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
# installPorts.rb 
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

require 'optparse'

# MAIN script function
def main

   fullPathGems = ENV['DEC_BASE']
   fullPathGems = "#{fullPathGems}/install/packages-apt-get.txt"
   fullPathGems = "/Users/borja/Projects/dec/install/packages-apt-get.txt"

   cmdOptions = {}

   begin
      OptionParser.new do |opts|

         opts.banner = "installPorts.rb"

         opts.on("-a", "--all", "retrieves all variables") do |v|
            cmdOptions[:all] = true
            @fields = @variables
         end

         opts.on("-F", "--File", "filename to keep the information") do |v|
            cmdOptions[:filename] = v.to_s
            @filename = v.to_s
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

   if @isDebugMode == true then
      puts fullPathGems
   end
   

   file = File.new(fullPathGems, "r")

   arrPorts = file.readlines

   arrPorts.each{|port|
      if port.to_s.slice(0,1) == "#" then
         puts "skip #{port}"
         next
      end
      cmd = "port install #{port}"
      puts cmd
      system(cmd)
   }

   exit(0)

end
#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
