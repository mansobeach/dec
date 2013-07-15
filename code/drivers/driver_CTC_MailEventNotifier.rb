#!/usr/bin/ruby

#########################################################################
#
# driver_CTC_MailEventNotifier
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#
#########################################################################


require 'ctc/MailEventNotifier'


notifier = CTC::MailEventNotifier.new

ret = notifier.mailEvent("RPF_R", "SuccessDelivery", ["file1", "file2", "file3", "fileN"])

if ret == false then
   puts "Error notifying event SuccessDelivery to RPF_R I/F"
else
   puts "Success notifying event SuccessDelivery to RPF_R I/F"
end
