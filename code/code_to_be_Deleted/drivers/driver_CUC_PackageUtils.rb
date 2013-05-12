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

packZIP("/home/projects/dccdev/local/code/ddc/drivers/file1", true)
