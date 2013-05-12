#!/usr/bin/ruby

#########################################################################
#
# driver_CTC_ReadMailConfig
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#
#########################################################################

require 'ctc/ReadMailConfig'


decMailConfig = CTC::ReadMailConfig.instance

@smtpServer = decMailConfig.getSendMailParams

@popServer  = decMailConfig.getReceiveMailParams

puts "----------------------------------------------"
puts @smtpServer
puts "----------------------------------------------"

puts

puts "----------------------------------------------"
puts @popServer
puts "----------------------------------------------"
puts
puts

#decMailConfig 
