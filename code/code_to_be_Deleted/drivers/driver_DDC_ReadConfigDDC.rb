#!/usr/bin/ruby

#########################################################################
#
# driver_DDC_ReadConfigDDC
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#   $Id: driver_DDC_ReadConfigDDC.rb,v 1.3 2007/03/08 13:00:32 decdev Exp $
#
#########################################################################

require 'ddc/ReadConfigDDC'

puts "Checking module DDC::ReadConfigDDC ..."

# Get the one and only instace of our great singleton class
ftReadConf = DDC::ReadConfigDDC.instance

arrFilters = ftReadConf.getOutgoingFilters

puts arrFilters

puts
if ftReadConf.deleteSourceFiles? == true then
   puts "Source Files are deleted from Archive after delivery"
else
   puts "Source Files are NOT deleted from Archive after delivery"
end
puts

puts ftReadConf.getLocalRepository

puts "------------------------------------------"

puts ftReadConf.getReports

puts "------------------------------------------"
