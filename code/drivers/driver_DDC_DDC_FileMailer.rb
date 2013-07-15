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

require 'ddc/DDC_FileMailer'
require 'ctc/ReadEntityConfig'
require 'ctc/ReadMailConfig'
require 'ctc/FileMailer'

puts "Checking module DDC_FileMailer ..."


mailConfig = CTC::ReadMailConfig.instance

decConfig  = CTC::ReadEntityConfig.instance

arrEnts    = decConfig.getAllMnemonics
entity     = arrEnts[0]

arrMail    = decConfig.getMailList(entity)
mailParams = mailConfig.getSendMailParams


# fileMailer = CTC::FileMailer.new(mailParams, arrMail)
# fileMailer.setDebugMode
# 
# fileMailer.setMailSubject("Test de Mail")
# 
# fileMailer.addFileToBeSent("/home/projects/dccdev/local/code/ddc/drivers/driver_DDC_DDC_FileMailer.rb")
# fileMailer.addFileToBeSent("/home/projects/dccdev/local/code/ddc/drivers/driver_1.rb")
# 
# fileMailer.sendAllFiles

puts
puts "Deliverying files via mail to #{entity}"
puts

ddcMailer = DDC::DDC_FileMailer.new(entity, false)

#ddcMailer.setDebugMode

ret = ddcMailer.deliver

if ret == true then
   puts ""
end


