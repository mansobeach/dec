#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #NATSClientCCS5 class
###
### === Written by DEIMOS Space S.L.
###
### === Data Exchange Component
### 
### Git: $Id: NATSClient.rb,v  $
###
###
#########################################################################

## https://github.com/nats-io/nats.rb
## https://github.com/nats-io/nats.rb/issues/102
## https://www.rubydoc.info/gems/nats/0.10.0

require 'json'
require 'nats/client'
require 'fiber'

require 'cuc/Converters'
require 'dec/ReadConfigDEC'

module DEC

class NATSClient

   include CUC::Converters

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
      @natsOPT    = {
                     :reconnect_time_wait    => 80000,
                     :max_reconnect_attempts => 1200,
                     :servers                => [@natsURL]
                  }
      # @natsTimeOut = 7200
      @natsTimeOut = 600
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
   def natsSubscribe(subject, timeout = @natsTimeOut)
      strReply = ""
      begin
         NATS.start(@natsOPT) do |nc|
            @logger.info("[NATS003] I/F #{@entity}: NATS.subscribe #{@natsURL} #{subject}")
            sid = NATS.subscribe(subject) { |msg|
               strReply = msg.dup
               NATS.drain
            }
            NATS.timeout(sid, timeout) { return "" }
         end
       end
       return strReply   
   end
   ## -------------------------------------------------------------

   def natsRequest(subject, body, timeout = @natsTimeOut)

      if @isDebugMode == true then
         @logger.debug("[NATSXXX] I/F #{@entity}: natsRequest #{@natsURL} #{subject} #{body} #{timeout}")
      end

      begin
         NATS.start(@natsOPT) do |nc|
=begin
           NATS.subscribe('CCS5.SESS.STATUS.NAOS.*') { |msg|
             if @isDebugMode == true then
               @logger.debug(msg)
             end
             NATS.drain
           }
=end           
            Fiber.new do
               @logger.info("[NATS001] I/F #{@entity}: NATS.request #{@natsURL} #{subject} #{body}")
               response = NATS.request(subject, \
                                     body, \
                                     timeout: timeout)
               if response != nil then
                  if response.split("{")[0].include?("0") then
                     @logger.info("[NATS002] I/F #{@entity}: #{response}")
                  else
                     @logger.error("[DEC_XXX] I/F #{@entity}: #{response}")
                  end
               else
                  @logger.error("[NATS101] I/F #{@entity}: no reply from server")
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

   def blockRequest(subject, body)

   end

   ## -------------------------------------------------------------

end # class

end # module
