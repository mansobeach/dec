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


require 'ctc/CheckerMailNotification'


checker = CTC::CheckerMailNotification.new

ret = checker.check

puts

if ret == false then
   puts "Error in DEC mail_notifications.xml ! :-("
else
   puts "DEC mail_notifications.xml Configuration  is OK ! :-)"
end

puts
