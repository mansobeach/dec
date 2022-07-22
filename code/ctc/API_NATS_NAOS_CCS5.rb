#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #API_NATS_NAOS_CCS5 class
###
### === Written by DEIMOS Space S.L.
###
### === Data Exchange Component
### 
### Git: #API_NATS_NAOS_MCS.rb,v $Id$
###
### module CTC
###
#########################################################################

module CTC

## TO DOCUMENT SOMEWHERE LIKELY MCS CONFIGURATIONS    
## MessageBroker::request -subject CCS5.AutoPilot.NAOS.call -message "SleGroundStationMgm DEDANAOSSIM02_SV CONNECT"
## MessageBroker::request -subject CCS5.AutoPilot.NAOS.call -message "SleGroundStationMgm DEDANAOSSIM02_SV DISCONNECT"
## responder-id = "DEDANAOSSIM02_SV";
## /home/ccsexec/TESTENV/USER/SLE/SICF/NAOS-SIM.SI


## nats sub -s nats://172.23.253.28:4222 "CCS5.AutoPilot.NAOS.call.ack"
## [#11] Received on "CCS5.AutoPilot.NAOS.call.ack"
## Started HistoryReport.tcl GPS 2022-07-06T06:00:00 2022-07-06T12:00:00 /tmp/IVV_DEC_TM-GPS_20220706T060000_20220706T120000.xml


   module API_NATS_NAOS_CCS5
      API_NATS_R1_SUBJECT     = "CCS5.AutoPilot.NAOS.call.ack"
      API_NATS_R1_TIMEOUT     = 10
      
      API_NATS_F0_SUBJECT     = "CCS5.SESS.STATUS.NAOS.*"
      API_NATS_F0_BODY        = ""
      API_NATS_F0_TIMEOUT     = 120
      
      API_NATS_F1_SUBJECT     = "CCS5.AutoPilot.NAOS.call"
      API_NATS_F1_BODY        = "SleGroundStationMgm <GS_name> <command> <VC>"
      API_NATS_F1_TIMEOUT     = 120

      API_NATS_F2_SUBJECT     = "CCS5.AutoPilot.NAOS.switch"
      API_NATS_F2_BODY        = ""
      API_NATS_F2_TIMEOUT     = 120

   #   API_NATS_F3_SUBJECT     = "CCS5.AutoPilot.NAOS.call"
      API_NATS_F3_SUBJECT     = "CCS5.AutoPilot.NAOS.ingest"
      API_NATS_F3_BODY        = ""
      API_NATS_F3_TIMEOUT     = 120

      API_NATS_F4_SUBJECT     = "CCS5.AutoPilot.NAOS.call"
      API_NATS_F4_BODY        = "ProcessActivityFile"
      API_NATS_F4_TIMEOUT     = 120

      API_NATS_F5_SUBJECT     = "CCS5.AutoPilot.NAOS.call"
      API_NATS_F5_BODY        = "UplinkActivityFile"
      API_NATS_F5_TIMEOUT     = 120

      API_NATS_F6_SUBJECT     = "CCS5.AutoPilot.NAOS.call"
      API_NATS_F6_BODY        = "HistoryReport"
      API_NATS_F6_TIMEOUT     = 1200

      API_NATS_F99_SUBJECT    = "CCS5.AutoPilot.NAOS.eval"
      API_NATS_F99_BODY       = ""
      API_NATS_F99_TIMEOUT    = 120
   end


end
