#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #NATSClientCCS5 class
###
### === Written by DEIMOS Space S.L.
###
### === Data Exchange Component
### 
### Git: $Id: NATSClientCCS5.rb,v  $
###
###
#########################################################################

require 'json'
require 'cuc/Converters'
require 'ctc/API_NATS_NAOS_CCS5'
require 'dec/ReadConfigDEC'
require 'dec/NATSClient'

module DEC

class NATSClientCCS5

   include CUC::Converters
   include CTC::API_NATS_NAOS_CCS5

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   def initialize(entity, ifSFTP, log, isDebug=false)
      @entityNATS       = entity
      @entitySFTP       = ifSFTP 
      @logger           = log
      
      if isDebug == true then
         self.setDebugMode
      end

      @ifConfig   = ReadInterfaceConfig.instance
      if @ifConfig.exists?(@entityNATS) == false
         @logger.error("[DEC_605] I/F #{@entityNATS}: such is not a configured interface #{'1F480'.hex.chr('UTF-8')}")
         exit(99)
      end
  
      @client = NATSClient.new(@entityNATS, @logger, @isDebugMode)

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
      raise "time-out for NATS request"
   end

   ## -----------------------------------------------------------
   ##

   def requestF0
      reply = @client.natsSubscribe(API_NATS_F0_SUBJECT)
      doc   = JSON.parse(reply)
      msg = "[CCS5_OK] I/F #{@entityNATS}: Session = #{doc["NAME"]} ; State = #{doc["STATE"]}"
      @logger.info(msg)
      if @isDebugMode == true then
         @logger.debug(doc)
      end 
   end

   ## -----------------------------------------------------------

   # F2. Session Switch
   # NATS subject used by AUTO to issue the request: CCS5.AutoPilot.NAOS.switch
   # NATS body: none.
   def requestF2
      @client.natsRequest(API_NATS_F2_SUBJECT, "", API_NATS_F2_TIMEOUT)
   end
   ## -----------------------------------------------------------

   # F3. Ingest MPS activities file
   # NATS subject used by AUTO to issue the request: CCS5.AutoPilot.NAOS.call
   # NATS body: Ingest <filename> <target>
   def requestF3(params)
      if @isDebugMode == true then
         @logger.debug(params)
      end
      body = "#{API_NATS_F3_BODY}#{JSON.parse(params)['filename']} #{JSON.parse(params)['target']}"
      @client.natsRequest(API_NATS_F3_SUBJECT, body, API_NATS_F3_TIMEOUT)
   end
   ## -----------------------------------------------------------

   # F4. Trigger processing of MPS/FDS activities file
   # NATS subject used by AUTO to issue the request: CCS5.AutoPilot.NAOS.call
   # NATS body: ProcessActivityFile <PATH>
   def requestF4(params)
      if @isDebugMode == true then
         @logger.debug(params)
      end
      body = "ProcessActivityFile #{JSON.parse(params)['path']}"
      @client.natsRequest(API_NATS_F4_SUBJECT, body, API_NATS_F4_TIMEOUT)
   end
   ## -----------------------------------------------------------

   # F5. Start dispatching a sequence of TCs created from an activities file
   # NATS subject used by AUTO to issue the request: CCS5.AutoPilot.NAOS.call
   # NATS body: UplinkActivityFile <filename>
   def requestF5(params)
      if @isDebugMode == true then
         @logger.debug(params)
      end
      body = "UplinkActivityFile #{JSON.parse(params)['filename']}"
      @client.natsRequest(API_NATS_F5_SUBJECT, body, API_NATS_F5_TIMEOUT)   
   end
   ## -----------------------------------------------------------

   def requestF6(params)
      if @isDebugMode == true then
         @logger.debug(params)
      end
      type    = JSON.parse(params)['type'].to_s.upcase
      urlFile = JSON.parse(params)['url']
      start   = JSON.parse(params)['start']
      stop    = JSON.parse(params)['end']

      case type
         when "GPS" then 
         when "MSC" then
         when "THR" then
      else
         @logger.error("Param type : #{type} is not supported for F6")
         return false
      end
  
      begin
         dateStart = str2date(start) 
      rescue Exception => e
         @logger.error("Param start : #{start} is not a valid date")
         if @isDebugMode == true then
            @logger.error(e.to_s)
         end
         return false
      end

      begin
         dateStart = str2date(stop) 
      rescue Exception => e
         @logger.error("Param end : #{stop} is not a valid date")
         if @isDebugMode == true then
            @logger.error(e.to_s)
         end
         return false
      end

      if urlFile.include?(".xml") == false then
         @logger.error("Param url : #{urlFile} does not seem to include a xml filename")
         return false
      end

     
     pidChild = fork{
         ppid     = Process.ppid
         @client2 = NATSClient.new(@entityNATS, @logger, @isDebugMode)
         reply    = @client2.natsSubscribe(API_NATS_R1_SUBJECT, API_NATS_R1_TIMEOUT)

         if reply == "" or reply == nil then
            msg   = "[CCS5ERR] I/F #{@entityNATS}: time-out for #{API_NATS_R1_SUBJECT}"
            @logger.error(msg)
            Process.kill(15, ppid.to_i)
            exit(99)
         end
         
         msg   = "[CCS5ACK] I/F #{@entityNATS}: #{reply}"
         @logger.info(msg)
         exit(0)
      }
      
      # to simulate time-out
      # sleep(0.9)

      body     = "HistoryReport #{type} #{start} #{stop} #{urlFile}"
      @client.natsRequest(API_NATS_F6_SUBJECT, body, API_NATS_F6_TIMEOUT)
      
      pid, status = Process.wait2
      #pid = Process.waitpid(pidChild, 0)
    
      if @entitySFTP != nil then
         cmd = "decGetFromInterface -m #{@entitySFTP} --nodb"
         if @isDebugMode == true then
            @logger.info(cmd)
         end
         ret = system(cmd)
         if ret == false then
            msg = "[DEC_600] I/F #{@entity}: Could not perform polling"
            @logger.error(msg)
            raise msg
         end
      end

   end

   ## -----------------------------------------------------------

   # F7. Process Playback TM frames
   # NATS subject used by AUTO to issue the request: CCS5.AutoPilot.NAOS.call
   # NATS body: ReplayTmFrames <File path> <VC>
   def requestF7(params)
      if @isDebugMode == true then
         @logger.debug(params)
      end
      pathFile = JSON.parse(params)['url']
      vc       = JSON.parse(params)['start']
      body     = "ReplayTmFrames"
   end
   ## -----------------------------------------------------------

   # F7. Process Playback TM frames
   # NATS subject used by AUTO to issue the request: CCS5.AutoPilot.NAOS.call
   # NATS body: ReplayTmFrames <File path> <VC>
   def requestF99(params)
      if @isDebugMode == true then
         @logger.debug(params)
      end
      # body     = "::CCSSEQ::startSession LOCAL REALTIME"
      # body     = "::CCSSEQ::stopSession LOCAL"
      body     = "::CCSSEQ::getServerStatus LOCAL"
      @client.natsRequest(API_NATS_F99_SUBJECT, body, API_NATS_F99_TIMEOUT)
   end
   ## -----------------------------------------------------------   

end # class

end # module
