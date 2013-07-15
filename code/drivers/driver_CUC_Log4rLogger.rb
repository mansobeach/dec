#!/usr/bin/env ruby

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

require 'cuc/Log4rLogger'


loggersetup = CUC::Log4rLogger.new("Module::Kakito")

loggersetup.setDebugMode

alog = loggersetup.setupManual(nil,  false, true)

alog.debug("What?!")
alog.info("Ah!")
alog.warn("Hey!")
alog.error("Ay!")
alog.fatal("BOOOM!")
