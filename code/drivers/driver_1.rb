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

require 'ddc/FileSender'
require 'ctc/ReadEntityConfig'

require 'cuc/DirUtils'
require 'ctc/CheckerFTPConfig'

include CUC::DirUtils

bret    = false
checker = nil

if bret == true then
   require 'ctc/CheckerIncomingFileConfig'
   checker = CTC::CheckerIncomingFileConfig.new("AUX_VC2_TM")
else
   require 'ctc/CheckerOutgoingFileConfig'
   checker = CTC::CheckerOutgoingFileConfig.new("MPL_ORBREF")
end

checker.check

