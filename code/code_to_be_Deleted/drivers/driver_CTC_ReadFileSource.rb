#!/usr/bin/ruby
#########################################################################
#
# driver_FT_ReadFileDestination
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#   $Id: driver_CTC_ReadFileSource.rb,v 1.3 2007/10/15 14:42:58 decdev Exp $
#
#########################################################################

require 'ctc/ReadFileSource'

puts "Checking module CTC::ReadFileSource ..."

# Get the one and only instace of our great singleton class
ftReadConf = CTC::ReadFileSource.instance

puts "================ Incoming File-Types ================="
puts ftReadConf.getAllIncomingFiles
puts
puts "================ Incoming File-Names ================="
puts ftReadConf.getAllIncomingFileNames
puts
puts
puts "XXXXXXXXXXXXXXXXXXXXXXXXX"
puts ftReadConf.getEntitiesSendingIncomingFileName("CORG2730.06I.Z")
#exit

# 
# # Set Debug Mode
# #ftReadConf.setDebugMode
# 
# arrFiles = ftReadConf.getToListOutgoingFiles("PDS")
# 
# puts "============================================================"
# puts "Files Sent TO the PDS"
# puts
# puts arrFiles
# puts
# puts "============================================================"
# 
# arrFiles = ftReadConf.getFromListOutgoingFiles("RPF_R")
# 
# puts "============================================================"
# puts "Files Sent BY the RPF_R"
# puts
# puts arrFiles
# puts
# puts "============================================================"
# 
# arrFiles = ftReadConf.getFromListIncomingFiles("FOS_R")
# 
# puts "============================================================"
# puts "Files Received FROM the FOS_R"
# puts
# puts arrFiles
# puts
# puts "============================================================"
# 
# arrFiles = ftReadConf.getToListIncomingFiles("RPF")
# 
# puts "============================================================"
# puts "Files Received BY the RPF"
# puts
# puts arrFiles
# puts
# puts "============================================================"
# 
# arrEntities = ftReadConf.getEntitiesReceivingIncomingFile("AUX_SDC_06")
# 
# puts "============================================================"
# puts "INTERNAL Entities which RECEIVE the File Type AUX_SDC_06"
# puts
# puts arrEntities
# puts
# puts "============================================================"
# 
# arrEntities = ftReadConf.getEntitiesReceivingOutgoingFile("MPL_ORBREF")

# puts "============================================================"
# puts "EXTERNAL Entities which RECEIVE the File Type MPL_ORBREF"
# puts
# puts arrEntities
# puts
# puts "============================================================"
# 
# arrEntities = ftReadConf.getEntitiesSendingIncomingFile("MPL_ORBPRE")
# 
# puts "============================================================"
# puts "EXTERNAL Entities which SEND the File Type MPL_ORBPRE"
# puts
# puts arrEntities
# puts
# puts "============================================================"
# 
# arrEntities = ftReadConf.getEntitiesSendingOutgoingFile("MPL_ORBREF")
# 
# puts "============================================================"
# puts "INTERNAL Entities which SEND the File Type MPL_ORBREF"
# puts
# puts arrEntities
# puts
# puts "============================================================"

#ftReadConf.setDebugMode

puts ftReadConf.getCompressMethod("FOS", "MPL_ORBREF")

puts ftReadConf.getDeliveryMethods("FOS", "MPL_ORBREF")

puts "------------------------------------------------"
puts ftReadConf.getDeliveryMethods("PDS", "MPL_ORBREF")

puts "------------------------------------------------"
puts "------------------------------------------------"

puts "Check for incoming Type AUX_SST_DB whether it is added the mnemonic"
puts ftReadConf.isMnemonicAddedToName?("RPF_R", "AUX_SST_DB")

puts

puts "Check for incoming File env_filename1.Z whether it is added the mnemonic"
puts ftReadConf.isMnemonicAddedToName?("SLR_EDCA", "env_filename1.Z", false)



# puts
# puts "Start monitoring the config files during 10 seconds each 2 seconds ..."
# 
# rpfObs = CTC::ObservableConfigFiles.instance
# 
# # Set Debug Mode
# rpfObs.setDebugMode
# 
# # Set the check of the config files every 2 seconds
# rpfObs.setTimer(2)
# 
# # start the monitoring
# rpfObs.start
# 
# # we monitor the FT config files during 10 seconds
# sleep(10)
# 
# # stop the monitoring
# rpfObs.stop
# 
# # 
