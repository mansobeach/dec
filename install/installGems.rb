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
# installGems.rb 
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
   fullPathGems = "#{fullPathGems}/install/packages-rubygems.txt"
   fullPathGems = "/Users/borja/Projects/dec/install/packages-rubygems.txt"

   cmdOptions = {}

   begin
      OptionParser.new do |opts|

         opts.banner = "installGems.rb"

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

   arrGems = file.readlines

   arrGems.each{|gem|
      cmd = "gem install #{gem}"
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
