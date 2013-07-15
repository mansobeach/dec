#!/usr/bin/ruby

#########################################################################
#
# driver_DCC_FileSender
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#
#########################################################################

require 'cuc/DirUtils'


include CUC::DirUtils

puts expandPathValue("$DCC_TMP/kaka/revaka")
puts "===================================================="

puts expandPathValue("kakito/kaka/revaka")
puts "===================================================="

puts expandPathValue("/kakito/kaka/revaka")
puts "===================================================="

puts expandPathValue("$DCC_TMP/kakito/$DATABASE_USER/revaka")
puts "===================================================="
