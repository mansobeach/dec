#!/usr/bin/ruby

#########################################################################
#
# driver_CUC_PackageUtils
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#
#########################################################################

require 'cuc/PackageUtils'

include CUC::PackageUtils

# packZIP("/home/projects/dccdev/local/code/ddc/drivers/file1", true)

puts  pack7z("/home/meteo/Projects/weather/data/archive/minarc_root/REALTIME_XML/CASALE/2013/06/01",
      "test.7z", false, true)
