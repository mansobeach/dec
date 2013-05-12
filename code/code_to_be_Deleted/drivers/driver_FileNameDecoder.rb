#!/usr/bin/ruby

#########################################################################
#
# driver_CTC_FileNameDecoder
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#
#########################################################################


require 'ctc/FileNameDecoder'

decoder = CTC::FileNameDecoder.new("SM_MREP_MPL_VS_PRO.20060330.20050701T000000_20050702T000000.W.zip")

ret = decoder.fileType

puts
puts ret
puts

puts "***************************************"
puts CTC::FileNameDecoder.new("SM_MREP_MPL_VS_PRO.20060330.20050701T000000_20050702T000000.W.zip").fileType

