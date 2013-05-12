#!/usr/bin/ruby
#########################################################################
#
# driver_CheckerOutgoingFileConfig
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#   $Id: driver_CTC_CheckerOutgoingFileConfig.rb,v 1.1 2006/09/06 14:48:34 decdev Exp $
#
#########################################################################

require 'ctc/CheckerOutgoingFileConfig'
require 'ctc/ReadFileDestination'

puts "Checking module CTC::CheckerOutgoingFileConfig ...\n"

readConf  = CTC::ReadFileDestination.instance

arrTypes  = readConf.getAllOutgoingFiles

arrTypes.each{|x|

   puts "Checking #{x} filetype"

   checkConf = CTC::CheckerOutgoingFileConfig.new(x)
   
#   Set Debug Mode
#   checkConf.setDebugMode

   ret = checkConf.check
   puts

# if ret == true then
#    puts "Correct configuration in ft_outgoing_files.xml ! :-) \n"
# else
#    puts "Error configuration in ft_outgoing_files.xml ! :-( \n"
# end

}
