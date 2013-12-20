#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DDC_Notifier2Interface class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# CVS:  $Id: DDC_Notifier2Interface.rb,v 1.7 2007/11/30 13:23:33 decdev Exp $
#
# Module Data Distributor Component
# This class delivers text mails.
#
# This class creates and sends text mails.
#
#########################################################################

require 'rubygems'

require 'ddc/ReadConfigDDC'
require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadMailConfig'
require 'ctc/CheckerMailConfig'
require 'ctc/MailSender'
require 'dbm/DatabaseModel'


module DDC



class DDC_Notifier2Interface
      
   # Class constructor.
   # * entity (IN):  Entity textual name (i.e. FOS)
   def initialize(entity)
      @isDebugMode = false
      @entity      = entity
      checkModuleIntegrity
      checker           = CTC::CheckerMailConfig.new
      ret               = checker.check(true, false)
      if ret == false then
         puts "Notifier2Interface could not connect to SMTP Server !! =-O"
         puts
         exit(99)
      end      
      @listFiles        = Array.new
      @listROPFiles     = Array.new
      @bListLoaded      = false
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
     @isDebugMode = true
     if @mailer != nil then
        @mailer.setDebugMode
     end
     puts "DDC_Notifier2Interface debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Generates a mail for the I/F naming all files sent to it.
   def notifyFilesSent
      
      # setFileList methods must be invoked before calling
      # notifyFilesSent.
      if @bListLoaded == false then
         puts "\nError in DDC_Notifier2Interface::notifyFilesSent !\n\n"
         puts "A list of files must be specified !\n\n\n"
         exit(99)
      end
      
      # If for this I/F the files list provided or through a parameter
      # or from the QUERY given the ROP number, it is empty, no mail
      # has to be sent. 
      if @bListWithFiles == false then
         if @isDebugMode == true then
            puts "\nNo Files to #{@entity} I/F => No Mail Notification !\n\n"
         end
         return
      end
           
      # setup Mailer for a notification of success      
      setupMailer(true)
      
      ddcConf = DDC::ReadConfigDDC.instance
      
      prjName = ddcConf.getProjectName
      prjID   = ddcConf.getProjectID
      
      @mailer.setMailSubject("New incoming file(s) from #{prjID} - #{prjName} to #{@entity} I/F")
      
      
      @mailer.addLineToContent("List of Files :")
      @mailer.addLineToContent("")
      
      @listFiles.each{|x| @mailer.addLineToContent(x)}
      
      @mailer.addLineToContent("")
      @mailer.addLineToContent("Have a nice day !")
      @mailer.addLineToContent("")
      # It performs the mail send
      @mailer.sendMail
      
   end
   #-------------------------------------------------------------
   
   # Set List if Files
   # IN: list of files. 
   # This method shall be used or the one that passes 
   # the ROP number to retrieve the list of files.
   # Nominally this method is invoked when the notification is 
   # generated for a delivery in Emergency Mode.
   def setListFilesSent(listFiles)
      @listFiles   = listFiles
      @bListLoaded = true
      if listFiles.length > 0 then
         @bListWithFiles = true
      else
         @bListWithFiles = false
      end
   end
   
   def setListFilesErrors(listFilesErrors)
      @listFilesErrors   = listFilesErrors
      @bListLoaded = true
      if listFilesErrors.length > 0 then
         @bListWithFiles = true
      else
         @bListWithFiles = false
      end
   end
   #-------------------------------------------------------------
   
   # Generates a mail to notify the I/F Contact person that
   # the delivery to this I/F failed.
   #
   # For further info of this requirement please consult ICDs 
   # documents, 3.4.6.1 data communication problem (2nd paragraph) 
   def notifyDeliveryError
      
      # setFileList methods must be invoked before calling
      # notifyFilesSent.
      if @bListLoaded == false then
         puts "\nError in DDC_Notifier2Interface::notifyDeliveryError !\n\n"
         puts "A list of files must be specified !\n\n\n"
         exit(99)
      end
      
      # If for this I/F the files list provided or through a parameter
      # or from the QUERY given the ROP number, it is empty, no mail
      # has to be sent. 
      if @bListWithFiles == false then
         if @isDebugMode == true then
            puts "\nNo Files to #{@entity} I/F => No Mail Notification !\n\n"
         end
         return
      end  
   
      # setup Mailer for a notification of failure      
      setupMailer(false)
      
      ddcConf = DDC::ReadConfigDDC.instance
      
      prjName = ddcConf.getProjectName
      prjID   = ddcConf.getProjectID
      
      @mailer.setMailSubject("Delivery Error when #{prjID} - #{prjName} sent files to #{@entity} I/F")

      @mailer.addLineToContent("")
      @mailer.addLineToContent(%Q{#{@contactName},})
      @mailer.addLineToContent("")
      @mailer.addLineToContent("could you please get in contact with your #{prjID} - #{prjName} reference person")
      @mailer.addLineToContent("due to this transfer error between the #{prjID} and #{@entity}.")
      @mailer.addLineToContent("")
      @mailer.addLineToContent("List of files failed to be sent :")
      
      @listFilesErrors.each{|x| @mailer.addLineToContent(x)}
      
      @mailer.addLineToContent("")
      @mailer.addLineToContent("Apologize for the inconvenience.")
      @mailer.addLineToContent("")
      # It performs the mail send
      @mailer.sendMail   
   end
   #-------------------------------------------------------------   
   


private

   @listFiles = nil
   @mailer    = nil

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   # - Here it is checked that Entity Name I/F is already registered
   # - in the database.
   def checkModuleIntegrity
      ret = Interface.find_by_name(@entity)
      if ret == nil then
         puts
         puts "Error - #{@entity} is not a registered I/F ! :-("
         puts
         exit(99)
      end
  
      # Load Mail Params for this I/F.
      ftMailConf    = CTC::ReadMailConfig.instance
      @mailParams   = ftMailConf.getSendMailParams
      ftReadConf    = CTC::ReadInterfaceConfig.instance
      @bIsNotified  = ftReadConf.isNotificationSent?(@entity)
      @contactInfo  = ftReadConf.getContactInfo(@entity)
      @contactEmail = ftReadConf.getContactEMail(@entity)
      @arrNotify2   = ftReadConf.getNotifyTo(@entity)
      @contactName  = @contactInfo[:name]     
   end
   #-------------------------------------------------------------

   # It loads and sets up the mailer object with its parameters.
   # Depending whether it is a notification of success or failure
   # destinations are different.
   def setupMailer(bSuccess)
      sendTo    = Array.new
      smtpHost  = @mailParams[:server]
      smtpPort  = @mailParams[:port]
      user      = @mailParams[:user]
      if bSuccess == true then
         sendTo    = @arrNotify2
      else
         sendTo    << @contactEmail
      end 
     
      @mailer   = CTC::MailSender.new(user, smtpHost, smtpPort.to_i)

      if @isDebugMode == true then
        @mailer.setDebugMode
      end
      @mailer.init
      sendTo.each{|x| @mailer.addToAddress(x)}
   end
   #-------------------------------------------------------------
      
end # class

end # module
