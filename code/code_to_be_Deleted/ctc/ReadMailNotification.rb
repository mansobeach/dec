#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #ReadMailNotification class          
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: ReadMailNotification.rb,v 1.2 2006/10/17 13:26:07 decdev Exp $
#
# This class processes mail_notifications.xml
# which contain all the information about the events and list of email addresses
# to be notified when the event happens
#
#########################################################################

require 'singleton'
require 'rexml/document'

module CTC

class ReadMailNotification

   include Singleton
   include REXML
   include CTC
   
   #-------------------------------------------------------------
  
   # Class constructor
   def initialize
      @@isModuleOK        = false
      @@isModuleChecked   = false
      @isDebugMode        = false
      @@handlerXmlFile    = nil          
      checkModuleIntegrity
      defineStructs
      loadData
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadMailNotification debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Reload data from files
   #
   # This is the method called when the config files are modified
   def update
      if @isDebugMode then 
         print("\nReceived Notification that the config files have changed\n")
      end   
      loadData
   end
   #-------------------------------------------------------------
   
   # Get all events name for a given entity
   # - mnemonic (IN): Entity name
   def getNotificationEvents(mnemonic)
      return getEvents(mnemonic)
   end
   #-------------------------------------------------------------

   # Get all events name for a given entity
   # - mnemonic (IN)    : Entity name
   # - event Name (IN)  : Event name   
   def getRecipients(mnemonic, event)
      @arrNotifications.each{|element|
         if element[:entity] == mnemonic and element[:event] == event then
            return element[:arrRecipients]
         end
      }
   end
   #-------------------------------------------------------------
   
   # Get all events name for a given entity
   # - mnemonic (IN)    : Entity name
   # - event Name (IN)  : Event name   
   def isNotifiedEvent?(mnemonic, event)
      @arrNotifications.each{|element|
         if element[:entity] == mnemonic and element[:event] == event then
            if element[:notifyFlag].to_s.downcase == "true" then
               return true
            end
            if element[:notifyFlag].to_s.downcase == "false" then
               return false
            end
            puts
            puts "Error in ReadMailNotification::isNotifiedEvent?  :-(!"
            puts
            exit(99)
         end
      }
      return false
   end
   #-------------------------------------------------------------
   
   # Get all events name for a given entity
   # - mnemonic (IN)    : Entity name
   # - event Name (IN)  : Event name   
   def getAllEntities
      arrEntities = Array.new
      @arrNotifications.each{|element|
         arrEntities << element[:entity]
      }
      return arrEntities.uniq
   end
   #-------------------------------------------------------------
   
private

   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true
   
      if !ENV['DCC_CONFIG'] then
         puts "\nDCC_CONFIG environment variable not defined !  :-(\n\n"
         bCheckOK = false
         bDefined = false
      end

      
      if bDefined == true then      
        configDir         = %Q{#{ENV['DCC_CONFIG']}}        
        @@configDirectory = configDir
        
        configFile = %Q{#{configDir}/mail_notifications.xml}        
        if !FileTest.exist?(configFile) then
           bCheckOK = false
           print("\n\n", configFile, " does not exist !  :-(\n\n" )
        end
        
      end
      if bCheckOK == false then
         puts "ReadMailNotification::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end      
   end
   #-------------------------------------------------------------

	# Define all the structs
	def defineStructs
	   Struct.new("MailNotificationStruct", :entity, :event, :notifyFlag, :arrRecipients)
   end
   #-------------------------------------------------------------

   
   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def loadData
      externalFilename = %Q{#{@@configDirectory}/mail_notifications.xml}
      fileExternal     = File.new(externalFilename)
      xmlFile          = REXML::Document.new(fileExternal)
      
      if @isDebugMode == true then
         puts "\nProcessing mail_notifications.xml"
      end
      process(xmlFile)
   end   
   #-------------------------------------------------------------
   
   # Process File
   # - xmlFile (IN): XML file
   # - arrFile (OUT): 
   def process(xmlFile)
      @arrNotifications = Array.new
      description       = ""
      entity            = nil
      notifyFlag        = nil   
      arrAddresses      = Array.new
      
      XPath.each(xmlFile, "MailNotifications/Notify2"){      
         |notify2|
         
         entity = notify2.attributes["Name"]
         
         
         XPath.each(notify2, "Event"){
            |event|
            
            anEvent = event.attributes["Name"]
            
            XPath.each(event, "NotifyFlag"){
               |flag|
               notifyFlag = flag.text
            }

            XPath.each(event, "Recipients"){
               |recipients|
               arrAddresses = Array.new
               XPath.each(recipients, "Address"){
                  |address|
                  arrAddresses << address.text
               }
               arrAddresses = arrAddresses.uniq
            }

            @arrNotifications << fillMailNotificationStruct(entity, anEvent, notifyFlag, arrAddresses)
             
         }
      
      }
            
   end
   #-------------------------------------------------------------

   # MailNotificationStruct is filled in this method.
   # mnemonic,
   # - mnemonic (IN):
   # - event (IN):
   # - flag (IN):
   # - arrAddresses (IN):
   # There is only one point in the class where all Dynamic structs 
   # are filled so that it is easier to update/modify the I/Fs   
   def fillMailNotificationStruct(mnemonic, event, flag, arrAddresses)          
      notification  = Struct::MailNotificationStruct.new(
                         mnemonic,
                         event,
                         flag,
                         arrAddresses
                         )
      return notification
   end
   #-------------------------------------------------------------

   def getEvents(mnemonic)
      arrEvents = Array.new
      @arrNotifications.each{|element|
         if element[:entity] == mnemonic then
            arrEvents << element[:event]
         end
      }
      return arrEvents.uniq
   end
   #-------------------------------------------------------------

end # class


end # module
