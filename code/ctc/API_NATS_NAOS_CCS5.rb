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



   module API_NATS_NAOS_CCS5
      API_NATS_R1_SUBJECT     = "CCS5.AutoPilot.NAOS.call.*"
      API_NATS_F0_SUBJECT     = "CCS5.SESS.STATUS.NAOS.*"
      API_NATS_F0_BODY        = "CCS5.SESS.STATUS.NAOS.*"
      API_NATS_F1_SUBJECT     = "CCS5.AutoPilot.NAOS.call"
      API_NATS_F1_BODY        = "SleGroundStationMgm <GS_name> <command> <VC>"
      API_NATS_F2_SUBJECT     = "CCS5.AutoPilot.NAOS.switch"
      API_NATS_F2_BODY        = ""
   #   API_NATS_F3_SUBJECT     = "CCS5.AutoPilot.NAOS.call"
      API_NATS_F3_SUBJECT     = "CCS5.AutoPilot.NAOS.ingest"
      API_NATS_F3_BODY        = ""
   #   API_NATS_F3_BODY        = "Ingest"
      API_NATS_F4_SUBJECT     = "CCS5.AutoPilot.NAOS.call"
      API_NATS_F4_BODY        = "ProcessActivityFile"
      API_NATS_F5_SUBJECT     = "CCS5.AutoPilot.NAOS.call"
      API_NATS_F5_BODY        = "UplinkActivityFile"
      API_NATS_F6_SUBJECT     = "CCS5.AutoPilot.NAOS.call"
      API_NATS_F6_BODY        = "HistoryReport"
      API_NATS_F99_SUBJECT    = "CCS5.AutoPilot.NAOS.eval"
   end


end

=begin

F1. Manage G/S connections
NATS subject used by AUTO to issue the request: CCS5.AutoPilot.NAOS.call
NATS body: SleGroundStationMgm <GS_name> <command> <VC>
<GS_name> is the Ground Station identifier as identified in the system;
<command> : either CONNECT or DISCONNECT.
 CONNECT will make MCS to Bind and Start one CLTU Forward Service Instance (SI) and one Return Service Instance with the G/S (RAF or RCF depending on <VC>, see below).
 DISCONNECT will make the MCS Stop and Unbind Forward and Return SIs.
<VC> TM Virtual Channel, optional argument. If no value is provided, the connection to the Ground Station will be established by means of a RAF service instance. If VC is provided, RCF is used instead, configured with the VC value passed (possible values: 0,1,..7, * )
NATS message example (subject, body): “CCS5.AutoPilot.NAOS.call”, “SleGroundStationMgm SvaBB-Prime-001 CONNECT 0”.
The CLTU and RAF (or RCF) SLE Service Instances used to connect to the ground station are defined in the MCS (SICF file). If multiple SLE SI are defined in the SICF for the given <GS_name> and the specific service type (CLTU, RAF, or RCF), the first in the SICF is used.

=end