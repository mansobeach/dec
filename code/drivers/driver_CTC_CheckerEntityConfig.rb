#!/usr/bin/ruby

#########################################################################
#
# driver_FT_CheckerEntityConfig
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#
#########################################################################

require 'ctc/CheckerInterfaceConfig'
require 'ctc/ReadInterfaceConfig'


puts "Checking module CTC::CheckerInterfaceConfig ..."


ftConfig = CTC::ReadInterfaceConfig.instance


arrEnts  = ftConfig.getAllExternalMnemonics

arrEnts.each{
              |x|
              checker    = CTC::CheckerInterfaceConfig.new(x)
#              checker.setDebugMode
              retVal     = checker.check

              if retVal == true then
                 puts "\n\n#{x} I/F is configured correctly ! :-) \n\n"
              else
                 puts "\n\n#{x} I/F is not configured correctly ! :-( \n\n"
              end

              puts ftConfig.getCleanUpFreq(x)

}






