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

require 'ddc/DDC_FileSender'

puts "Checking module DDC_FileSender ..."

ddcSender = DDC::DDC_FileSender.new("RPF_R")

if ddcSender.listFileToBeSent.length == 0 then
   puts
   puts "No files to be delivered via ftp to RPF_R"
   puts
   exit(0)
end

retVal = ddcSender.deliver

puts
if retVal == true then
   puts "File Delivery to RPF_R has been completed successfully :-)"
else
   puts "ERROR in File Delivery to RPF_R ! :-("
end
puts

if ddcSender.listFileSent != 0 then
   puts "------------------------"
   puts "Files sent :"
   puts ddcSender.listFileSent
   puts
   puts "------------------------"
   puts
   puts
end

if ddcSender.listFileError.length != 0 then
   puts "------------------------"
   puts "Error Sending :"
   puts ddcSender.listFileError
   puts
   puts "------------------------"
   puts
   puts
end




