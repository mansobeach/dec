#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DDC_FileMailer class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: FileMailer.rb,v 1.2 2006/10/05 14:52:30 decdev Exp $
#
# Module Common Transfer Component
# This class delivers methods for sending files to entities using SMTP.
# The files are sent through attachments in a mail.
#
#########################################################################

require 'ctc/SMTPClient'


module CTC

class FileMailer
      
   # Class constructor.
   # * mailParams (IN): smtp struct with parameters
   # * arrSendTo (IN): array of addresses
   def initialize(mailParams, arrSendTo, name="")
      checkModuleIntegrity
      @mailParams   = mailParams
      @sendTo       = arrSendTo
      @name         = name
      # Creates the mail client
      setupMailer      
      @listFiles   = Array.new         
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      if @mailer != nil then
         @mailer.setDebugMode
      end
      puts "FileMailer debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Add filename to be sent in the attachment
   def addFileToBeSent(full_path_filename)
      @listFiles   << full_path_filename
   end
   #-------------------------------------------------------------
   
   # Deliver all files to their destinations
   def deliver
      if @listFiles.empty? == true then
         puts "FileMailer::sendAllFiles Error : list of is empty :-( \n\n"
         exit(99)
      end
      
      # Attach all files of the delivery
      @listFiles.each{|x|
         @mailer.attach(x)
      }        
      return @mailer.sendMail
   end
   #-------------------------------------------------------------
   
   # Set the subject of the delivery sent via mail
   def setMailSubject(subject)
     if @mailer != nil then
        @mailer.setMailSubject(subject)
     end
   end
   #-------------------------------------------------------------

private

   @listFiles = nil
   @mailer    = nil

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   #-------------------------------------------------------------

   # It loads and sets up the mailer object with its parameters.
   def setupMailer
      smtpHost  = @mailParams[:server]
      smtpPort  = @mailParams[:port]
      user      = @mailParams[:user]
      sendTo    = @sendTo
      @mailer   = SMTPClient.new(user, smtpHost, smtpPort.to_i, @name)
      if @isDebugMode == true then
        @mailer.setDebugMode
      end
      sendTo.each{|x| @mailer.addToAddress(x)}
   end
   #-------------------------------------------------------------
      
end # class

end # module

