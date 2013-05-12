#!/usr/bin/ruby

#########################################################################
#
# driver_CTC_CheckerMailConfig
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#
#########################################################################


require 'ctc/CheckerMailConfig'


checker = CTC::CheckerMailConfig.new

ret = checker.check

puts

if ret == false then
   puts "Error in DEC Mail Configuration ! :-("
else
   puts "DEC Mail Configuration  is OK ! :-)"
end

puts
