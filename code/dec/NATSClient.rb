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

require 'json'
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
   def natsSubscribe(subject)
      begin
         NATS.start(:servers => [@natsURL]) do |nc|
           @logger.info("NATS.subscribe #{@natsURL} #{subject}")
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

   def natsRequest(subject, body)

      if @isDebugMode == true then
         @logger.debug("natsRequest #{@natsURL} #{subject} #{body}")
      end

      begin
         NATS.start(:servers => [@natsURL]) do |nc|
=begin
           NATS.subscribe('CCS5.SESS.STATUS.NAOS.*') { |msg|
             if @isDebugMode == true then
               @logger.debug(msg)
             end
             NATS.drain
           }
=end           
            Fiber.new do
               @logger.info("NATS.request #{@natsURL} #{subject} #{body}")
               response = NATS.request(subject, \
                                     body, \
                                     timeout: 3)
               if response != nil then
                  if response.split("{")[0].include?("0") then
                     @logger.info(response)
                  else
                     @logger.error(response)
                  end
               else
                  @logger.error("no reply from server")
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
