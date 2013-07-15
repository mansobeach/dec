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

require 'ddc/DDC_BodyMailer'
require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadMailConfig'
require 'ctc/MailSender'

puts "Checking module DDC_BodyMailer ..."


# mailConfig = CTC::ReadMailConfig.instance
# 
decConfig  = CTC::ReadInterfaceConfig.instance

arrEnts    = decConfig.getAllMnemonics
interface  = arrEnts[0]

interface  = "FOS"

# 
# arrMail    = decConfig.getMailList(entity)
# mailParams = mailConfig.getSendMailParams


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
puts "Deliverying files via mail to #{interface}"
puts

ddcMailer = DDC::DDC_BodyMailer.new(interface, false)

ddcMailer.setDebugMode

#ddcMailer.loadFileList

ret = ddcMailer.deliver(true)

if ret == true then
   puts ""
end


