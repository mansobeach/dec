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

require 'ddc/DDC_Notifier2Entity'

require 'ctc/ReadEntityConfig'
require 'ctc/ReadMailConfig'
require 'ctc/FileMailer'

puts "Checking module DDC_Notifier2Entity ..."



decConfig   = CTC::ReadEntityConfig.instance
arrEntities = decConfig.getAllMnemonics

puts arrEntities[0]
exit



mailConfig = CTC::ReadMailConfig.instance

arrMail    = decConfig.getMailList("RPF_R")
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


ddcMailer = DDC::DDC_FileMailer.new("RPF_R")

ret = ddcMailer.deliver

if ret == true then
   puts ""
end

#ddcSender.deliver

