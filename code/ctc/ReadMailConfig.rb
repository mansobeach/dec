#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #ReadMailConfig class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS:  $Id: ReadMailConfig.rb,v 1.5 2013/03/14 13:40:57 algs Exp $
#
# Module Common Transfer Component
# This class reads and decodes DEC mail configuration stored 
# ft_mail_config.xml.
#
#########################################################################


require 'singleton'
require 'rexml/document'

require 'cuc/DirUtils'


module CTC

class ReadMailConfig

   include Singleton
   include REXML
   include CUC::DirUtils
   #-------------------------------------------------------------   
   
   # Class contructor
   def initialize
      @@isModuleOK        = false
      @@isModuleChecked   = false
      @isDebugMode        = false
      checkModuleIntegrity
		defineStructs
      loadData
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "ReadMailConfig debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Reload data from configuration file
   #
   # This is the method called by the Observer when the config files are modified.
   def update
      if @isDebugMode then 
         print("\nReceived Notification that the config files have changed\n")
      end   
      loadData
   end
   #-------------------------------------------------------------
   
   def getSendMailServer
      return @@sendMailParams[:server]
   end
   #-------------------------------------------------------------
   
   def getSendMailUser
      return @@sendMailParams[:user]
   end
   #-------------------------------------------------------------
   
   def getSendMailPass
      return @@sendMailParams[:pass]
   end
   #-------------------------------------------------------------  
   
   def getSendMailPort
      return @@sendMailParams[:port]
   end
   #-------------------------------------------------------------  

   def isSendMailSecure
      return @@sendMailParams[:isSecure]
   end	
   #-------------------------------------------------------------	

   def isSendMailSubject
      return @@sendMailParams[:subject]
   end	
   #-------------------------------------------------------------	

   def isSendMailBody
      return @@sendMailParams[:body]
   end	
   #-------------------------------------------------------------	
	
   def getSendMailParams
      return @@sendMailParams
   end
	
   #-------------------------------------------------------------
   #-------------------------------------------------------------

   def getReceiveMailServer
      return @@receiveMailParams[:server]
   end
   #-------------------------------------------------------------
   
   def getReceiveMailUser
      return @@receiveMailParams[:user]
   end
   #-------------------------------------------------------------
   
   def getReceiveMailPass
      return @@receiveMailParams[:pass]
   end
   #-------------------------------------------------------------  
   
   def getReceiveMailPort
      return @@receiveMailParams[:port]
   end
   #-------------------------------------------------------------  
 
   def isReceiveMailSecure
      return @@receiveMailParams[:isSecure]
   end	
   #-------------------------------------------------------------
   
   def getReceiveMailParams
      return @@receiveMailParams
   end	
   #-------------------------------------------------------------

private

   @@isModuleOK        = false
   @@isModuleChecked   = false
   @isDebugMode        = false
   @@configDirectory   = ""  
   @@monitorCfgFiles   = nil
   @@arrExtEntities    = nil

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true
   
      if !ENV['DCC_CONFIG'] and !ENV['DEC_CONFIG'] then
        puts "DEC_CONFIG / DCC_CONFIG environment variable not defined !  :-(\n"
        bCheckOK = false
        bDefined = false
      end
            
      if bDefined == true then      
      
         configDir = nil

         if ENV['DEC_CONFIG'] then
            configDir         = %Q{#{ENV['DEC_CONFIG']}}  
         else
            configDir         = %Q{#{ENV['DCC_CONFIG']}}  
         end
     
         @@configDirectory = configDir
        
         configFile = %Q{#{configDir}/ft_mail_config.xml}        
         if !FileTest.exist?(configFile) then
            bCheckOK = false
            print("\n\n", configFile, " does not exist !  :-(\n\n" )
         end           
      end      
      if bCheckOK == false then
         puts "ReadMailConfig::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end      
   end
   #-------------------------------------------------------------
   
   # Load the file into the an internal struct.
   #
   # The struct is defined in the class Constructor. See #initialize.
   def loadData
      externalFilename = %Q{#{@@configDirectory}/ft_mail_config.xml}
      fileExternal     = File.new(externalFilename)
      xmlFile          = REXML::Document.new(fileExternal)
      
      if @isDebugMode == true then
         puts "\nProcessing ft_mail_config.xml"
      end
      process(xmlFile)
   end   
   #-------------------------------------------------------------
   
   # Process the xml file decoding all the file
   # - xmlFile (IN): XML configuration file
   def process(xmlFile)
      smtpserver     = ''
      popserver      = ''
      port           = ''
      user           = ''
      pass           = ''
      isSecure       = false
      subject        = ''
      body           = ''
      
      path    = "MailParams/SendMailParams"
      mailer  = XPath.each(xmlFile, path){
          |entity|   	  
          XPath.each(entity, "SMTPServer"){
             |server|
             smtpserver = server.text
          }
          XPath.each(entity, "Port"){
             |pport|
             port = pport.text
          }
          XPath.each(entity, "User"){
             |uuser|
             user = uuser.text
          }
          XPath.each(entity, "Pass"){
             |ppass|
             pass = ppass.text
          }	  	  
          XPath.each(entity, "isSecure"){
             |sec|            
               case sec.text
                  when "true" then isSecure = true
                  when "false" then isSecure = false
                  else isSecure = false 
               end            
          }
          XPath.each(entity, "Subject"){
             |ssubject|
             subject = ssubject.text
          }
          XPath.each(entity, "Body"){
             |bbody|
             body = bbody.text
          }	 

   @@sendMailParams = fillSendMailStruct(smtpserver,
                                          port,
                                          user,
                                          pass,
                                          isSecure,
                                          subject,
                                          body)
      }
      if @isDebugMode == true then
         puts @@sendMailParams
      end
   
      path    = "MailParams/ReceiveMailParams"
      mailer  = XPath.each(xmlFile, path){
          |entity|   	  
          XPath.each(entity, "POPServer"){
             |server|
             popserver = server.text
          }
          XPath.each(entity, "Port"){
             |pport|
             port = pport.text
          }		 
          XPath.each(entity, "User"){
             |uuser|
             user = uuser.text
          }
          XPath.each(entity, "Pass"){
             |ppass|
             pass = ppass.text
          }	  	  
          XPath.each(entity, "isSecure"){
             |sec|            
               case sec.text
                  when "true" then isSecure = true
                  when "false" then isSecure = false
                  else isSecure = "" 
               end            
          }	  	  
      @@receiveMailParams = fillReceiveMailStruct(popserver,
                                          port,
                                          user,
                                          pass,
                                          isSecure
                                          )
      }
      if @isDebugMode == true then
         puts @@receiveMailParams
      end
	
   end
   #-------------------------------------------------------------   
   
	# Define all the structs
   def defineStructs
      Struct.new("SendMailStruct", :server, :port, :user, :pass, :isSecure, :subject, :body)
      Struct.new("ReceiveMailStruct", :server, :port, :user, :pass, :isSecure)
   end
   #-------------------------------------------------------------

   # Fill a Send;ailStruct struct
   # - smtpserver (IN):
   # - port (IN):
   # - user (IN):
   # - pass (IN):
   # There is only one point in the class where all dynamic structs 
   # are filled so that it is easier to update/modify the I/F.
   def fillSendMailStruct(smtpserver, port, user, pass, isSecure, subject, body)                      
      sendMailStruct = Struct::SendMailStruct.new(smtpserver,
                                  port,
                                  user,
			                         pass,
                                  isSecure,
                                  subject,
                                  body)
      return sendMailStruct               
   end
   #-------------------------------------------------------------
   
	# Fill a ReceiveMail struct
   # - server (IN):
   # - port (IN):
   # - user (IN):
   # - pass (IN):
   # There is only one point in the class where all dynamic structs 
   # are filled so that it is easier to update/modify the I/F.
   def fillReceiveMailStruct(server, port, user, pass, isSecure)   
      receiveMailStruct = Struct::ReceiveMailStruct.new(server,
                                 port,
                                 user,
                                 pass,
                                 isSecure)
      return receiveMailStruct               
   end
   #-------------------------------------------------------------   
	
end # class

end # module

