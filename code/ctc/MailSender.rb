#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #MailSender class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: MailSender.rb,v 1.4 2007/11/30 13:24:03 decdev Exp $
#
# Module Common Transfer Component
# This class delivers text mails.
#
# This class creates and sends text mails.
#
#########################################################################

require 'net/smtp'

module CTC


class MailSender
    
   #--------------------------------------------------------------

   # Class constructor.
   # address (IN) : string with the from address mail.
   # host (IN) : string with the IP address or hostname
   # port (IN) : integer with port number
   def initialize(fromAddress,host, port)
#      puts "initialize MailSender ..."
      @isModuleOK        = false
      @isModuleChecked   = false
      @isDebugMode       = false
      @bConfigured       = false      
      @host              = host
      @port              = port
      checkModuleIntegrity
      @arrToAddress      = Array.new
      @arrContent        = Array.new
      @subject           = ""
      @fromAddress       = fromAddress
   end
   #-------------------------------------------------------------
   
   def init
      begin
         @smtpClient        = Net::SMTP.start(@host, @port, @domain)
      rescue Exception
         if @isDebugMode == true
            puts
            puts "SMTP Connection Refused ! =-("
	         puts "Host   -> #{@host}"
	         puts "Port   -> #{@port}"
	         puts "Domain -> #{@domain}"
            puts
         else
            puts
            puts "MailSender could not connect to #{@host}:#{@port}"
         end
         return false
      end
      @bConfigured = true
      return true
   end
   #-------------------------------------------------------------
   
   # Add an address to @toAddress array
   def addToAddress(address)
      @arrToAddress << address
      if @isDebugMode == true then
         puts "Address #{address} added to Destinations"
      end
   end
   #-------------------------------------------------------------

   # Set Mail Subject
   def setMailSubject(subject)
      smtpSubject = %Q{Subject: #{subject}\n}
      @arrContent.unshift(smtpSubject)
      if @isDebugMode == true then
         puts "Mail Subject is : #{subject} added to Destinations"
      end
   end
   #-------------------------------------------------------------
   
   # Content of the outgoing mail is stored as an array of lines.
   def addLineToContent(line)
      line = %Q{#{line}\n}
      @arrContent << line
   end
   #-------------------------------------------------------------
   
   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "MailSender Debug Mode is on"
   end
   #-------------------------------------------------------------
   
   # Sends a mail with 
   def sendMail
      if @bConfigured == false then
         puts "MailSender::sendMail Internal Error : init method must be first invoked first !! :-O \n\n"
         exit(99)
      end      
      if @arrToAddress.empty? == true then
         puts "MailSender::sendMail Error : Destinations address is empty :-( \n\n"
         exit(99)
      end
      @smtpClient.sendmail(@arrContent, @fromAddress, @arrToAddress)
      return true
   end
   #-------------------------------------------------------------

private

   @isModuleOK        = false
   @isModuleChecked   = false
   @isDebugMode       = false      

   #-------------------------------------------------------------

   # Check that all needed to run is present
   def checkModuleIntegrity
      bDefined = true
      if !ENV['HOSTNAME'] then
         puts "\nHOSTNAME environment variable not defined !\n"
         bDefined = false
      end
      
      if bDefined == false then
        puts("MailSender::checkModuleIntegrity FAILED !\n\n")
        exit(99)
      end      
      @domain = ENV['HOSTNAME']
   end
   #-------------------------------------------------------------


   #=============================================================
end # class

end # module
