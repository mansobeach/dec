#!/usr/bin/env ruby

#########################################################################
#
# driver_FT_ReadFileDestination
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#   $Id: driver_CTC_ReadFileDestination.rb,v 1.4 2007/07/24 17:22:01 decdev Exp $
#
#########################################################################

require 'ctc/ReadFileDestination'

puts "Checking module CTC::ReadFileDestination ..."

# Get the one and only instace of our great singleton class
ftReadConf = CTC::ReadFileDestination.instance
# 
# # Set Debug Mode
ftReadConf.setDebugMode
# 
arrFiles = ftReadConf.getToListOutgoingFiles("FOS")

puts "============================================================"
puts "Files Sent TO the FOS"
puts
puts arrFiles
puts
puts "============================================================"

arrFiles = ftReadConf.getToListOutgoingFiles("RPF_R")

puts "============================================================"
puts "Files Sent TO the RPF_R"
puts
puts arrFiles
puts
puts "============================================================"


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
# 
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

puts ftReadConf.getCompressMethod("FOS", "MPL_PPF___")

puts ftReadConf.getDeliveryMethods("FOS", "MPL_PPF___")

puts "------------------------------------------------"
puts ftReadConf.getDeliveryMethods("RPF_R", "MPL_PPF___")

puts ftReadConf.getAllOutgoingFiles  

puts ftReadConf.getCleanUpAge("APF", "MPL_USERS_")
puts ftReadConf.getCleanUpAge("MMPF", "MPL_USERS_")
puts ftReadConf.getCleanUpAge("KAKITO", "MPL_USERS_")

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
