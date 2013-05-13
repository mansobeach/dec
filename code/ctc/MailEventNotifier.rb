#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #MailEventNotifier class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS:  $Id: MailEventNotifier.rb,v 1.3 2008/07/02 09:59:15 decdev Exp $
#
#########################################################################

require 'ctc/ReadMailNotification'
require 'ctc/CheckerMailNotification'
require 'cuc/Log4rLoggerFactory'

   # Module Common Transfer Component
   # Class that performs mail notifications for different DEC events.

module CTC


class MailEventNotifier
	 
   #--------------------------------------------------------------

   # Class constructor.
   def initialize
      @isDebugMode = false
      checkModuleIntegrity

      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("MailEventNotifier", "#{ENV['DCC_CONFIG']}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in MailEventNotifier::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{ENV['DCC_CONFIG']}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end

      checker     = CTC::CheckerMailNotification.new
      @notifyConf = CTC::ReadMailNotification.instance
      @configOK = checker.check
      if @configOK == false then
         @logger.error("Configuration Error in mail_notifications.xml")
         return false
      end
   end
   #-------------------------------------------------------------
   
   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "MailEventNotifier Debug Mode is on"
   end
   #-------------------------------------------------------------
   
   def mailEvent(entity, event, params)
      if @notifyConf.isNotifiedEvent?(entity, event) == false then
         @logger.error("#{entity} has no registered #{event} event in mail_notifications.xml")
         puts "Error - #{entity} has no registered #{event} event in mail_notifications.xml ! :-("
         return false
      end
      
   end
   #-------------------------------------------------------------

private

   #-------------------------------------------------------------

   # Check that all needed to run is present
   def checkModuleIntegrity
	   return
   end
   #-------------------------------------------------------------

end # class

end # module


