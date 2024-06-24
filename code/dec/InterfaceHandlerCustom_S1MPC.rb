#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #InterfaceHandlerAbstract class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component -> Data Collector Component
###
### Git: $Id: InterfaceHandlerAbstract.rb,v 1.12 2014/05/16 00:14:38 bolf Exp $
###
### Module Interface
### This is an abstract class that defines the interface handler methods
###
#########################################################################

## http://morningcoffee.io/interfaces-in-ruby.html


module DEC

require 'date'

require 'dec/ReadConfigDEC'
require 'dec/InterfaceHandlerCustom'

class InterfaceHandlerCustom_S1MPC < InterfaceHandlerCustom

   attr_reader :queryDate

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   ## * entity (IN):  Entity textual name (i.e. FOS)
   def initialize(entity, log)
      super(entity, log)

      if ENV.include?("DEC_QUERY_DATE_#{@entity}") == true then
         @queryDate = ENV["DEC_QUERY_DATE_#{@entity}"]
      else
         @queryDate = Date.today.prev_day.to_s
      end
   end
   ## -----------------------------------------------------------
   ##
   ##
   def print_usage
      super()
      @logger.info("[DEC_A00] I/F #{@entity}: env variable DEC_QUERY_DATE_#{@entity}=YYYY-MM-DD")
   end
   ## -------------------------------------------------------------

   ## Download a file from the I/F
   def downloadFile(filename, url)
      cmd  = "curl -s -k -L #{url} --output #{@dirIncoming}/.#{filename}"
      if@isDebugMode == true then
         @logger.debug("[DEC_XXX] I/F #{@entity}: #{cmd}")
      end
      ret = system(cmd)
      if ret == true then
         size = File.size("#{@dirIncoming}/.#{filename}")
         cmd  = "mv -f #{@dirIncoming}/.#{filename} #{@dirIncoming}/#{filename}"
         if@isDebugMode == true then
            @logger.debug("[DEC_XXX] I/F #{@entity}: #{cmd}")
         end
         ret = system(cmd)
         if ret == false then
            raise "#{cmd} failed"
         end
         @logger.info("[DEC_110] I/F #{@entity}: #{filename} downloaded with size #{size} bytes")
         self.setReceivedFromEntity(filename, size)
         self.triggerEventNewFile(filename)
         return true
      else
          @logger.error("[DEC_666] #{@entity} I/F: Could not download #{filename}")
          return false
      end
   end

   ## -----------------------------------------------------------

end # class

end # module
