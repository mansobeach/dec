#!/usr/bin/ruby

#########################################################################
#
# driver_CheckerIncomingFileConfig
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#   $Id: driver_CTC_CheckerIncomingFileConfig.rb,v 1.1 2006/09/06 14:48:34 decdev Exp $
#
#########################################################################

require 'dcc/CheckerInTrayConfig'
require 'ctc/ReadFileSource'


@dccIncoming = CTC::ReadFileSource.instance
puts @dccIncoming.getAllIncomingFiles
