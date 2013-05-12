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

puts "Checking module DDC_FileSender ..."

ddcConfig = CTC::ReadEntityConfig.instance

ftpStruct = ddcConfig.getFTPServer4Send("RPF_R")

txStruct  = ddcConfig.getTXRXParams("RPF_R")

checkerConfig = CTC::CheckerFTPConfig.new(ftpStruct, "RPF_R")
checkerConfig.setDebugMode

ret = checkerConfig.check4Send

if ret == false then
   puts
   puts "Configuration Error for RPF_R !! :-("
   puts
   puts
   exit(99)
end


struct1   = Hash.new
hash1     = Hash.new

outboxpath = expandPathValue("$HOME/local/data")

fileList   = ["GO_TEST_SST_NOM_1B_20000715T110801_20000715T123721_0001.HDR",
              "GO_TEST_SST_NOM_1B_20000715T140000_20000715T144514_0001.HDR",
              "GO_TEST_SST_NOM_1B_20000715T140641_20000715T153601_0001.HDR"]


fileSender = DDC::FileSender.new(ftpStruct, txStruct, hash1)
fileSender.setDebugMode
fileSender.setFileList(fileList, outboxpath)

fileSender.sendAllFiles(false)
