#!/usr/bin/env ruby

require 'ctc/MailSender'

mailSender = CTC::MailSender.new( \
                              'localhost',   \
                              25,   \
                              'dec/rpf@esa.int', \
                              'password', \
                              false, \
                              )
                                         
mailSender.setDebugMode

mailSender.addToAddress("borja.lopez@deimos-space.com")

mailSender.setMailSubject("New incoming file(s) from METEO - Data Exchange Component to LOCALHOST_NOT_SECURE I/F")

mailSender.addLineToContent("")
mailSender.addLineToContent("List of Files:")
mailSender.addLineToContent("")
mailSender.addLineToContent("AE_OPER_MPL_STPLAN_20071029T000000_20071105T000000_0001")
mailSender.addLineToContent("AE_OPER_MPL_SEG____20071029T000000_20071105T000000_0003")
mailSender.addLineToContent("")
mailSender.addLineToContent("Have a nice day !")
mailSender.addLineToContent("")

mailSender.buildMessage

mailSender.init

mailSender.sendMail
