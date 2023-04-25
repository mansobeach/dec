#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #HTTPClientCCS5 class
###
### === Written by DEIMOS Space S.L.
###
### === Data Exchange Component
### 
### Git: $Id: HTTPClientCCS5.rb,v  $
###
###
#########################################################################

require 'json'
require 'cuc/Converters'
require 'ctc/API_HTTP_NAOS_CCS5'
require 'dec/ReadConfigDEC'

module DEC

class HTTPClientCCS5

   include CUC::Converters
   include CTC::API_HTTP_NAOS_CCS5

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   def initialize(entity, log, isDebug=false)
      @entityNATS       = entity
      @logger           = log
      
      if isDebug == true then
         self.setDebugMode
      end

      @ifConfig   = ReadInterfaceConfig.instance
      if @ifConfig.exists?(@entityNATS) == false
         @logger.error("[DEC_605] I/F #{@entityNATS}: such is not a configured interface #{'1F480'.hex.chr('UTF-8')}")
         exit(99)
      end
  
      @host = @ifConfig.getServer(@entityNATS)[:hostname]
      # Register a handler for SIGTERM
      trap 15,proc{ self.SIGTERMHandler }

   end   
   ## -----------------------------------------------------------
   ##
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("#{self.class}::#{__method__.to_s}")
   end
   ## -----------------------------------------------------------

   def SIGTERMHandler
      raise "time-out for HTTP request"
   end

   ## -----------------------------------------------------------
   ##

   def requestFSTATUS
      if @isDebugMode == true then
         @logger.debug("HTTPClientCCS5::requestFSTATUS")
      end
      url = "#{@host}:#{API_HTTP_NAOS_CCS5_PORT}#{API_HTTP_NAOS_CCS5_STATUS_PATH}"
      cmd = "curl -X #{API_HTTP_NAOS_CCS5_STATUS_VERB} #{url}"
      if @isDebugMode == true then
         @logger.debug(cmd)
      end
      return system(cmd)
   end

   ## -----------------------------------------------------------   

   ## -----------------------------------------------------------
   ##

   def requestFSTOP
      if @isDebugMode == true then
         @logger.debug("HTTPClientCCS5::requestFSTOP")
      end
      url = "#{@host}:#{API_HTTP_NAOS_CCS5_PORT}#{API_HTTP_NAOS_CCS5_STOP_PATH}"
      cmd = "curl -H '#{API_HTTP_NAOS_CCS5_STOP_HEADER}' -X #{API_HTTP_NAOS_CCS5_STOP_VERB} #{url}"
      if @isDebugMode == true then
         @logger.debug(cmd)
      end
      return system(cmd)
   end

   ## -----------------------------------------------------------   

   ## -----------------------------------------------------------
   ##

   def requestFSTART
      if @isDebugMode == true then
         @logger.debug("HTTPClientCCS5::requestFSTART")
      end
      url = "#{@host}:#{API_HTTP_NAOS_CCS5_PORT}#{API_HTTP_NAOS_CCS5_START_PATH}"
      cmd = "curl -d '#{JSON.generate(API_HTTP_NAOS_CCS5_START_ARGS)}' -H '#{API_HTTP_NAOS_CCS5_START_HEADER}' -X #{API_HTTP_NAOS_CCS5_START_VERB} #{url}"
      if @isDebugMode == true then
         @logger.debug(cmd)
      end
      return system(cmd)
   end

   ## -----------------------------------------------------------   


end # class

end # module
