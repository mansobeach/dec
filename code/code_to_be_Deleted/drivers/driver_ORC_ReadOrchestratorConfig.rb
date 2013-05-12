#!/usr/bin/env ruby

#########################################################################
#
# driver_ORC_ReadOrchestratorConfig
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#   $Id: driver_ORC_ReadOrchestratorConfig.rb,v 1.4 2007/07/24 17:22:01 decdev Exp $
#
#########################################################################

require 'orc/ReadOrchestratorConfig'

puts "Checking module ORC::ReadOrchestratorConfig ..."

# Get the one and only instace of our great singleton class
ftReadConf = ORC::ReadOrchestratorConfig.instance


# # # Set Debug Mode
ftReadConf.setDebugMode

# #shows all Data providers
# puts "***DATA PROVIDERS***"
# ftReadConf.getAllDataProviders
# puts
#
# 
# #shows all Data types
# puts "***DATA TYPES***"
# ftReadConf.getAllDataTypes
# puts
#
#shows all File types
puts "***FILE TYPES***"
ftReadConf.getAllFileTypes
puts
# 
# #shows the Data type of a given File type
# puts "***THE DATA TYPE IS***"
# ftReadConf.getDataType("MIR_JMATD_")
# puts
# 
# #shows the File type of a given Data type
# puts "***THE FILE TYPE IS***"
# ftReadConf.getFileType("GMAT")
# puts
# 
# #shows if the Data type is a trigger for a given Data type
# puts "***IS IT A TRIGGER?***"
# ftReadConf.isDataTypeTrigger("FWF1A")
# puts
# 
# #shows if the File type is a trigger for a given File type
# puts "***IS IT A TRIGGER?***"
# ftReadConf.isFileTypeTrigger("AUX_FLATT_")
# puts

#  #shows if the File type matches a given File type
#  puts "***IS IT A VALID TYPE?***"
#  puts ftReadConf.isValidFileType("TLM_MIRA1A")
#  puts
