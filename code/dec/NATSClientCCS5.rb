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

module DEC

class NATSClientCCS5

   include CUC::Converters
   include CTC::API_NATS_NAOS_CCS5

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   def initialize(entity, log, isDebug=false)
      @entity        = entity
      @logger        = log
      
      if isDebug == true then
         self.setDebugMode
      end

      @ifConfig   = ReadInterfaceConfig.instance
      if @ifConfig.exists?(@entity) == false
         @logger.error("[DEC_605] I/F #{@entity}: such is not a configured interface #{'1F480'.hex.chr('UTF-8')}")
         exit(99)
      end
  
      @natsServer = @ifConfig.getServer(@entity)
      @natsURL    = "nats://#{@natsServer[:hostname]}:#{@natsServer[:port]}"
   end   
   ## -----------------------------------------------------------
   ##
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("#{self.class}::#{__method__.to_s}")
   end
   ## -----------------------------------------------------------

   ## -----------------------------------------------------------
   ##

   def requestF0
      natsSubscribe(@natsURL, API_NATS_F0_SUBJECT) 
   end

   ## -----------------------------------------------------------

   # F2. Session Switch
   # NATS subject used by AUTO to issue the request: CCS5.AutoPilot.NAOS.switch
   # NATS body: none.
   def requestF2
      natsRequest(@natsURL, API_NATS_F2_SUBJECT, "")
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
      natsRequest(@natsURL, API_NATS_F3_SUBJECT, body)
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
      natsRequest(@natsURL, API_NATS_F4_SUBJECT, body)
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
      natsRequest(@natsURL, API_NATS_F5_SUBJECT, body)   
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
      body     = "HistoryReport #{type} #{start} #{stop} #{urlFile}"
      natsRequest(@natsURL, API_NATS_F4_SUBJECT, body)
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
      natsRequest(@natsURL, API_NATS_F99_SUBJECT, body)
   end
   ## -----------------------------------------------------------   
   ##
   def natsSubscribe(url, subject)
      begin
         NATS.start(:servers => [url]) do |nc|
           @logger.info("NATS.subscribe #{url} #{subject}")
           NATS.subscribe(subject) { |msg| 
             doc = JSON.parse(msg)
             msg = "Session : #{doc["NAME"]} ; State : #{doc["STATE"]}"
             @logger.info(msg)
             if @isDebugMode == true then
               @logger.debug(doc)
             end
             NATS.drain
           }
         end
       end      
   end
   ## -------------------------------------------------------------

   def natsRequest(url, subject, body)

      if @isDebugMode == true then
         @logger.debug("natsRequest #{url} #{subject} #{body}")
      end

      begin
         NATS.start(:servers => [url]) do |nc|
=begin
           NATS.subscribe('CCS5.SESS.STATUS.NAOS.*') { |msg|
             if @isDebugMode == true then
               @logger.debug(msg)
             end
             NATS.drain
           }
=end           
            Fiber.new do
               @logger.info("NATS.request #{url} #{subject} #{body}")
               response = NATS.request(subject, \
                                     body, \
                                     timeout: 3)
               if response != nil then
                  if response.include?("0") then
                     @logger.info(response)
                  else
                     @logger.error(response)
                  end
               else
                  @logger.info("no reply")
               end
               NATS.drain
            end.resume
     
           nc.on_disconnect do |reason|
             # puts "Disconnected: #{reason}"
           end
       
           nc.on_close do |reason|
             #puts "Closed: #{reason}"
           end

         end
        
       end      
   end
   ## -------------------------------------------------------------

end # class

end # module
