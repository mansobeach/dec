#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #API_HTTP_NAOS_CCS5 class
###
### === Written by DEIMOS Space S.L.
###
### === Data Exchange Component
### 
### Git: #API_HTTP_NAOS_CCS5.rb,v $Id$
###
### module CTC
###
#########################################################################

module CTC

## TO DOCUMENT SOMEWHERE LIKELY MCS CONFIGURATIONS    
# https://jira.elecnor-deimos.com/browse/NAOSMCS-52

   module API_HTTP_NAOS_CCS5
      API_HTTP_NAOS_CCS5_PORT          = 8080

      API_HTTP_NAOS_CCS5_STATUS_VERB   = 'GET'
      API_HTTP_NAOS_CCS5_STATUS_PATH   = '/SessionControl/status'

      API_HTTP_NAOS_CCS5_START_VERB    = 'POST'
      API_HTTP_NAOS_CCS5_START_HEADER  = 'Content-Type: application/json'
      API_HTTP_NAOS_CCS5_START_PATH    = '/SessionControl/start'
      API_HTTP_NAOS_CCS5_START_ARGS    = { "sessionTag" => "TEST", "sessionType" => "REALTIME" }

      API_HTTP_NAOS_CCS5_STOP_VERB     = 'POST'
      API_HTTP_NAOS_CCS5_STOP_HEADER   = 'Content-Type: application/json'
      API_HTTP_NAOS_CCS5_STOP_PATH     = '/SessionControl/stop'
      API_HTTP_NAOS_CCS5_STOP_ARGS     = nil
   end


end
