#!/usr/bin/env ruby

#########################################################################
#
# driver_DDC_ReadConfigDCC
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#   $Id: driver_DCC_ReadConfigDCC.rb,v 1.1 2007/03/07 17:08:35 decdev Exp $
#
#########################################################################

require 'dcc/ReadConfigDCC'

puts "Checking module DCC::ReadConfigDCC ..."

# Get the one and only instace of our great singleton class
ftReadConf = DCC::ReadConfigDCC.instance

arrFilters = ftReadConf.getIncomingFilters

puts arrFilters

arrReports = ftReadConf.getReports

puts arrReports
