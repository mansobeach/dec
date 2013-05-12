#!/usr/bin/ruby

#########################################################################
#
# driver_CTC_ReadMailNotification
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#
#########################################################################

require 'ctc/ReadMailNotification'


mailNotify = CTC::ReadMailNotification.instance


arrkk = mailNotify.getNotificationEvents("RPF_R")

puts arrkk


arrRecipients = mailNotify.getRecipients("RPF_R", "OnDelivery")

puts "------------"

puts arrRecipients

puts

retVal = mailNotify.isNotifiedEvent?("RPF_R", "OnDelivery")

if retVal == true then
   puts "Notified Flag is true"
else
   puts "Notified Flag is false"
end
