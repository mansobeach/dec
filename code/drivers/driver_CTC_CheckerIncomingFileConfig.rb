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

require 'ctc/CheckerIncomingFileConfig'
require 'ctc/ReadFileDestination'

puts "Checking module CTC::CheckerIncomingFileConfig ...\n"

readConf  = CTC::ReadFileSource.instance

arrTypes  = readConf.getAllIncomingFiles

ret = true

arrTypes.each{|x|

   checkConf = CTC::CheckerIncomingFileConfig.new(x)
   
#   Set Debug Mode
#   checkConf.setDebugMode

   retVal = checkConf.check

   if retVal == false then
      ret = false
      puts "#{x} - ERROR"
   else
      puts "#{x} - OK"
   end

}

puts
if ret == true then
   puts "Correct configuration in ft_incoming_files.xml ! :-) \n"
else
   puts "Error configuration in ft_incoming_files.xml ! :-( \n"
end
puts
