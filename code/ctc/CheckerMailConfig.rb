#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DCC_CheckerMailConfig class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# == Data Exchange Component -> Common Transfer Component
# 
# CVS:  $Id: CheckerMailConfig.rb,v 1.10 2010/10/18 15:47:15 algs Exp $
#
# === module Common Transfer Component (CTC)
# This class is in charge of verify that the mail configuration
# defined in ft_mail_config.xml is correct.
#
# ==== This class is in charge of verify that the SMTP and/or POP3
# ==== configuration is correct. It performs tests connections to defined 
# ==== servers.
#
#########################################################################

require 'ctc/ReadMailConfig'
require 'ctc/MailSender'
require 'ctc/MailReceiver'


module CTC

class CheckerMailConfig
   
   include CTC 
   
   # --------------------------------------------------------------

   # Class constructor.
   def initialize
      checkModuleIntegrity
      @dccReadConf    = ReadMailConfig.instance
      @sendMailCfg    = @dccReadConf.getSendMailParams
      @receiveMailCfg = @dccReadConf.getReceiveMailParams
      @isDebugMode    = true
   end
   # -------------------------------------------------------------
   
   # ==== Main method of the class
   # ==== It returns a boolean True whether checks are OK. False otherwise.
   # IN (bool) [optional] - check parameters required for sending (SMTP)
   #
   # IN (bool) [optional] - check parameters required for receiving (POP3)
   def check(b4Send = true, b4Recv = true)     
      retVal = true
     
      if @isDebugMode == true then
         showMailConfig(b4Send, b4Recv)
      end
     
      if b4Send == true then
         if retVal == true then
            retVal = checkSendMailParams
         else
            checkSendMailParams
         end
      end
		
      if b4Recv == true then
         if retVal == true then
            retVal = checkReceiveMailParams
         else
            checkReceiveMailParams
         end
      end         		
		         
      return retVal
   end
   # -------------------------------------------------------------

   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "CheckerMailConfig debug mode is on"
   end
   # -------------------------------------------------------------

   def getSendMailConfig
      return @sendMailCfg
   end
   #-------------------------------------------------------------

private

   @isDebugMode       = false      
   @ftReadConf        = nil

   # -------------------------------------------------------------

   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   # -------------------------------------------------------------

   def getRecvMailConfig
      return @receiveMailCfg
   end
   # -------------------------------------------------------------

   # It shows all relevant info regarding to the Mail Config
   # communication.
   def showMailConfig(b4Send = true, b4Recv = true)
      if b4Send == true then
         showSendMailConfig
      end
      if b4Recv == true then
		   showReceiveMailConfig
      end
   end   
   # -------------------------------------------------------------
   
   # It shows the SendMail Configuration.
   def showSendMailConfig      
      puts
      puts "----------------------------------------"
      puts "SendMailParams.SMTPServer  -> #{@sendMailCfg[:server]}"
      puts "SendMailParams.Port        -> #{@sendMailCfg[:port]}"
      puts "SendMailParams.User        -> #{@sendMailCfg[:user]}"
      puts "SendMailParams.Pass        -> *************"
      puts "SendMailParams.isSecure    -> #{@sendMailCfg[:isSecure]}"
      puts "----------------------------------------"
      puts
   end   
   # -------------------------------------------------------------
   
	# It shows the ReceiveMail Configuration.
   def showReceiveMailConfig      
      puts
      puts "----------------------------------------"
      puts "RecvMailParams.POPServer   -> #{@receiveMailCfg[:server]}"
      puts "RecvMailParams.Port        -> #{@receiveMailCfg[:port]}"
      puts "RecvMailParams.User        -> #{@receiveMailCfg[:user]}"
      puts "RecvMailParams.Pass        -> *************"
      puts "RecvMailParams.isSecure    -> #{@receiveMailCfg[:isSecure]}"
      puts "----------------------------------------"
      puts
   end   
   # -------------------------------------------------------------
   
	# It checks the configuration for sending mails
   def checkSendMailParams
      mailer = MailSender.new(
                              @sendMailCfg[:server],
                              @sendMailCfg[:port],
                              @sendMailCfg[:user],
                              @sendMailCfg[:pass],
                              @sendMailCfg[:isSecure]
			                    )
      return mailer.init
   end
   # -------------------------------------------------------------

   # It checks the configuration for receiving mails
	
   def checkReceiveMailParams
      mailer = MailReceiver.new(
                                 @receiveMailCfg[:server],
                                 @receiveMailCfg[:port],
                                 @receiveMailCfg[:user],
                                 @receiveMailCfg[:pass],
                                 @receiveMailCfg[:isSecure]
			                    )
      return mailer.init
   end
   # -------------------------------------------------------------

end # class

end # module

