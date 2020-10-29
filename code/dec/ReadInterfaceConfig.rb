#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #ReadInterfaceConfig class
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === Data Exchange Component
## 
## Git: $Id: ReadInterfaceConfig.rb,v 1.7 2008/03/27 15:52:13 decdev Exp $
##
## == Module Common Transfer Component
## This class reads and decodes the interfaces configuration file 
## dec_interfaces.xml.
##
#########################################################################

require 'singleton'
require 'rexml/document'
require 'cuc/DirUtils'

module DEC

class ReadInterfaceConfig

   include Singleton
   include REXML
   
   include CUC::DirUtils
   ## -------------------------------------------------------------   
   
   # Class contructor
   def initialize
      @@isModuleOK        = false
      @@isModuleChecked   = false
      @isDebugMode        = false
      @protocolArray      = ["FTP","SFTP","FTPS","FTPES","LOCAL", "HTTP", "WEBDAV"]
      checkModuleIntegrity
	   defineStructs
      loadData
   end
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "ReadEntityConfig debug mode is on"
   end
   ## -------------------------------------------------------------
   
   ## Reload data from configuration file
   ##
   ## This is the method called by the Observer when the config files are modified.
   def update
      if @isDebugMode then 
         print("\nReceived Notification that the config files have changed\n")
      end
      # puts "updating ..."
      loadData
   end
   ## -------------------------------------------------------------
   
   ## Returns the number of entities found in interfaces.xml file.
   def getNumExternalEntities
      return @@arrExtEntities.length
   end
#   #-------------------------------------------------------------
#   
#   # Reads IncomingDir from interfaces.xml 
#   # where FT leaves the files received. 
#   def getIncomingDir(mnemonic)
#      return searchEntityValue(mnemonic, @@arrExtEntities, "incomingDir")
#   end
#   #-------------------------------------------------------------  
#   
#   # It Reads OutgoingDir parameter for a given Entity from interfaces.xml.
#   #
#   # This directory is where #FT_PrepareDirectories shall leave the files
#   # which are going to be sent to a given Entity.
#   def getOutgoingDir(mnemonic)
#      return searchEntityValue(mnemonic, @@arrExtEntities, "outgoingDir")
#   end      
#   #-------------------------------------------------------------

   # It Reads description parameter for a given Entity from interfaces.xml
   def getDescription(mnemonic)
      return searchEntityValue(mnemonic, @@arrExtEntities, "description")
   end      
   #-------------------------------------------------------------
   
   # Get the mnemonics of all I/F entities.
   def getAllMnemonics
      return getAllExternalMnemonics
   end
   #-------------------------------------------------------------
   
   # Get the mnemonics of all I/F entities.
   def getAllExternalMnemonics
      nMnemonics = @@arrExtEntities.length
      arrEnt     = Array.new
      0.upto(nMnemonics-1) do |i|
         arrEnt << @@arrExtEntities[i][:mnemonic]
      end
      return arrEnt
   end
   #-------------------------------------------------------------
   
   # Get the TXRX Parameters for an entity.
   # - mnemonic (IN): Entity name
   def getTXRXParams(mnemonic)
      return searchEntityValue(mnemonic, @@arrExtEntities, "TXRXParams")      
   end
   #-------------------------------------------------------------
   
   # DEPRECATED
   # Get the Mail Parameters for an entity.
   # - mnemonic (IN): Entity name
   def getMailParams(mnemonic)
     return getNotifyParams(mnemonic)
   end
   #-------------------------------------------------------------
   
   # Get the Mail Parameters for an entity.
   # - mnemonic (IN): Entity name
   def getNotifyParams(mnemonic)
     return searchEntityValue(mnemonic, @@arrExtEntities, "Notify")
   end
   #-------------------------------------------------------------

   # Get Events for an Interface.
   # - mnemonic (IN): Entity name
   def getEvents(mnemonic)
     return searchEntityValue(mnemonic, @@arrExtEntities, "Events")
   end
   #-------------------------------------------------------------

   # Get the Contact Info for an entity.
   # - mnemonic (IN): Entity name
   def getContactInfo(mnemonic)
     return searchEntityValue(mnemonic, @@arrExtEntities, "ContactInfo")
   end
   #-------------------------------------------------------------   
   
   # Get the Email of the Contact Info
   # - mnemonic (IN): Entity name
   def getContactEMail(mnemonic)
     contactInfo = getContactInfo(mnemonic)
     return contactInfo[:email]
   end
   #-------------------------------------------------------------   
   
   # Get TXRX Immediate Retries params.
   # - mnemonic (IN): Entity name
   def getImmediateRetries(mnemonic)
     return decodeTXRXParams(getTXRXParams(mnemonic),"immediateRetries")
   end
   #-------------------------------------------------------------
   
   # Get TXRX Loop Retries params.
   # - mnemonic (IN): Entity name
   def getLoopRetries(mnemonic)
     return decodeTXRXParams(getTXRXParams(mnemonic),"loopRetries")
   end
   #-------------------------------------------------------------
   
   # Get Delay among each loop Retry expressed in seconds.
   # - mnemonic (IN): Entity name
   def getLoopDelay(mnemonic)
     return decodeTXRXParams(getTXRXParams(mnemonic),"loopDelay")
   end
   #-------------------------------------------------------------
   
   # Get Interval time among each Polling.
   # - mnemonic (IN): Entity name
   def getPollingInterval(mnemonic)
     return decodeTXRXParams(getTXRXParams(mnemonic),"pollingInterval")
   end
   #-------------------------------------------------------------      
   
   # Get the configuration FTP Config info for sending files.
   # - mnemonic (IN): Entity name
   def getFTPServer4Send(mnemonic)
      return searchEntityValue(mnemonic, @@arrExtEntities, "Server")
   end
   #-------------------------------------------------------------

   ## Get the configuration Server Config info for receiving files.
   ## - mnemonic (IN): Entity name
   def getServer(mnemonic)
      return searchEntityValue(mnemonic, @@arrExtEntities, "Server")
   end
   ## -----------------------------------------------------------

   # Get the configuration FTP Config info for receiving files.
   # - mnemonic (IN): Entity name
   def getFTPServer(mnemonic)
      return getServer(mnemonic)
   end
   ## -----------------------------------------------------------
   
   # Get the configuration FTP Config info for receiving files.
   # - mnemonic (IN): Entity name
   def getFTPServer4Receive(mnemonic)
      return searchEntityValue(mnemonic, @@arrExtEntities, "Server")
   end
   #-------------------------------------------------------------
   
#   def getAllDownloadDirs(mnemonic)
#      ftpStruct = getFTPServer(mnemonic)
#      return ftpStruct[:arrDownloadDirs]
#   end
#   #-------------------------------------------------------------   
#   
#   # Get the Download Dir <Entity><DownloadDir>
#   # - mnemonic (IN): Entity name
#   def getDownloadDir(mnemonic)
#      puts
#      puts "DEPRECATED METHOD - ReadInterfaceConfig::getDownloadDir !!!!"
#      puts 
#      exit(99)
#      ftpStrct = getFTPServer4Receive(mnemonic)
#      return ftpStrct[:downloadDir]
#   end
#   #-------------------------------------------------------------
   	
   # Get List of Mail addresses for diseminating the files to
   def getMailList(mnemonic)
      return searchEntityValue(mnemonic, @@arrExtEntities, "DeliverByMailTo")
   end
   #-------------------------------------------------------------
   
   # Get the configuration FTP config flag <RegisterContentFlag>
   # - mnemonic (IN): Entity name
	def registerDirContent?(mnemonic)
	   ftp = getFTPServer4Receive(mnemonic)
		return ftp[:isTracked]
	end
	#-------------------------------------------------------------

	# Get the configuration FTP config flag <RetrieveContentFlag>
   # - mnemonic (IN): Entity name
	def retrieveDirContent?(mnemonic)
	   ftp = getFTPServer4Receive(mnemonic)
		return ftp[:isRetrieved]
	end
	## ----------------------------------------------------------- 
	   
	## Get the configuration FTP config flag <DeleteFlag>
   ## - mnemonic (IN): Entity name	
	def deleteAfterDownload?(mnemonic)
      puts "DEPRECATED METHOD ! #{'1F480'.hex.chr('UTF-8')}"
      exit(99)
	   ftp = getFTPServer4Receive(mnemonic)
		return ftp[:isDeleted]	
	end

   ## -----------------------------------------------------------

	# Get the configuration FTP config flag <CompressFlag>
   # - mnemonic (IN): Entity name
	def isCompressed?(mnemonic)
	   ftp = getFTPServer4Receive(mnemonic)
		return ftp[:isCompressed]
	end
   ## -----------------------------------------------------------
	
   ## Get the configuration FTP config flag <SecureFlag>
   ## - mnemonic (IN): Entity name
	def isSecure?(mnemonic)
	   ftp = getFTPServer4Receive(mnemonic)
		return ftp[:isSecure]
	end
	## -----------------------------------------------------------

   ## Get the configuration FTP config flag <VerifyPeerSSL>
   ## - mnemonic (IN): Entity name
	def isVerifyPeerSSL?(mnemonic)
	   ftp = getFTPServer4Receive(mnemonic)
		return ftp[:verifyPeerSSL]
	end
	## -----------------------------------------------------------

   # Get the configuration FTP config Clean Up Freq
   # - mnemonic (IN): Entity name
	def getCleanUpFreq(mnemonic)
	   ftp = getFTPServer4Send(mnemonic)
		return ftp[:cleanUpFreq]
	end
	#-------------------------------------------------------------
	 
   def getNotifyTo(mnemonic)
      notifyParams = getNotifyParams(mnemonic)
      return notifyParams[:arrNotifyTo]
   end
   #-------------------------------------------------------------

   # sendNotification flag
   def isNotificationSent?(mnemonic)
      notifyParams = getNotifyParams(mnemonic)
      return notifyParams[:sendNotification]
   end
   #-------------------------------------------------------------

   # Checks whether it is an Entity configured with that name.
   # - mnemonic (IN): Entity name   
   # * It returns true if exists.
   # * Otherwise It returns false.
   def exists?(mnemonic)
      @@arrExtEntities.each{ |x| 
        if mnemonic == x[:mnemonic] then return true end
      }
      return false
   end
   #-------------------------------------------------------------
   
   def isEnabled4Sending?(mnemonic)
      return decodeTXRXParams(getTXRXParams(mnemonic),"enabled4Send")
   end
   #-------------------------------------------------------------

   def isEnabled4Receiving?(mnemonic)
      return decodeTXRXParams(getTXRXParams(mnemonic),"enabled4Receive")
   end
   ## -----------------------------------------------------------
   ##
   ## Get the Server network protocol configured for circulations
   ## - mnemonic (IN): Entity name
   def getProtocol(mnemonic)  
      return searchEntityValue(mnemonic, @@arrExtEntities, "Server").protocol
   end
   ## -----------------------------------------------------------

private

   @@isModuleOK        = false
   @@isModuleChecked   = false
   @isDebugMode        = false
   @@configDirectory   = ""  
   @@monitorCfgFiles   = nil
   @@arrExtEntities    = nil


   ## -----------------------------------------------------------
   
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true

      ## -----------------------------------------
      ##
       
      ## If not previosly defined,
      ## the configuration directory is the one of the gem installation 
       
      if !ENV['DEC_CONFIG'] then
         ENV['DEC_CONFIG'] = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      end
  
      ## -----------------------------------------
  
      if !ENV['DEC_CONFIG'] then
         puts "\nDEC_CONFIG environment variable not defined !  :-(\n\n"
         bCheckOK = false
         bDefined = false
      end

      # if environment variables are defined check for config files
      # interfaces.xml
      
      if bDefined == true then
         configDir = nil
         if ENV['DEC_CONFIG'] then
            configDir         = %Q{#{ENV['DEC_CONFIG']}}  
         end
            
              
         @@configDirectory = configDir
        
         @configFile = %Q{#{configDir}/dec_interfaces.xml}        
         if !FileTest.exist?(@configFile) then
           bCheckOK = false
           print("\n\n", @configFile, " does not exist !  :-(\n\n" )
         end        
      end
            
      if bCheckOK == false then
         raise "ReadInterfaceConfig::checkModuleIntegrity FAILED"
      end      
   end
   ## -------------------------------------------------------------
   
	## This method defines all the structs used
	def defineStructs
	   Struct.new("Entity", :mnemonic, :description, :incomingDir,
                      :outgoingDir, :Server, :TXRXParams,
	                   :Notify, :DeliverByMailTo, :Events, :ContactInfo)
                      
		Struct.new("Server", :mnemonic, \
                           :protocol, \
                           :hostname, \
                           :port, \
                           :user, \
                           :password, \
                           :isTracked, \
                           :isRetrieved, \
                           :isSecure, \
                           :verifyPeerSSL, \
                           :isCompressed, \
#                           :isDeleted, \
                           :isPassive, \
                           :cleanUpFreq, \
                           :uploadDir, \
                           :uploadTemp, \
                           :arrDownloadDirs \
                           )
                           
#		Struct.new("FTPServer", :mnemonic, :protocol, :hostname, :port,
#                   :user, :password, :ServerMirror, :isTracked, :isRetrieved, 
#                   :isSecure, :isCompressed, :isDeleted, :isPassive, :cleanUpFreq, :uploadDir,
#                   :uploadTemp, :arrDownloadDirs)
      Struct.new("FTPServerMirror", :mnemonic,:protocol, :hostname, :port, :user, :password)
#      Struct.new("DownloadDir", :mnemonic, :directory, :depthSearch)
		Struct.new("TXRXParams", :mnemonic, :enabled4Send, :enabled4Receive,
                 :immediateRetries, :loopRetries, :loopDelay, :pollingInterval, :pollingSize, :parallelDownload)
		Struct.new("NotifyTo", :mnemonic, :sendNotification, :arrNotifyTo)		            
      Struct.new("GetMailParams", :mnemonic, :hostname, :port, 
                             :user, :password, :pollingInterval)
      Struct.new("Events", :mnemonic, :arrEvents) 
      Struct.new("ContactInfo", :mnemonic, :name, :email, 
                             :tlf, :fax, :address)
	end
	## -------------------------------------------------------------
	
   ## Load the file into the an internal struct.
   ##
   ## The struct is defined in the class Constructor. See #initialize.
   def loadData
      fileExternal     = File.new(@configFile)
      xmlExternal      = REXML::Document.new(fileExternal)
      @@arrExtEntities = Array.new
      if @isDebugMode == true then
         puts "\nProcessing Interfaces configuration"
      end
      processEntities(xmlExternal, @@arrExtEntities)
   end   
   ## -------------------------------------------------------------
   
   ## Process the xml file decoding all the Entities
   ## - xmlFile (IN): XML configuration file
   ## - arrEmtities (OUT): Array of entity objects
   def processEntities(xmlFile, arrEntities)
#      @isDebugMode = true
      description = ""
      inDir    = ""
      outDir   = ""
      remote   = nil
      local    = nil
      txrx     = nil
      notify   = nil
      events   = nil
      mailto   = nil   
      contact  = nil
      arrsendTo= nil

      path = "Interfaces/Interface"
      
      entity  = XPath.each(xmlFile, path){
          |entity|
          events = nil
          XPath.each(entity, "Desc"){
             |descr|
             description = descr.text
          }          
#          XPath.each(entity, "IncomingDir"){
#             |dir|
#             inDir  = expandPathValue(dir.text)
#          }
#          XPath.each(entity, "OutgoingDir"){
#             |dir|
#             outDir = expandPathValue(dir.text)
#          }
          XPath.each(entity, "TXRXParams"){
             |txrxparams|
             txrx = fillTXRXParamsStruct(entity.attributes["Name"], txrxparams)
          }
          XPath.each(entity, "Server"){
             |remoteserver|
             remote = fillFTPServerStruct(entity.attributes["Name"], remoteserver)
          }
          XPath.each(entity, "DeliverByMailTo"){
             |nmail|
     	       arrSendTo = Array.new
             XPath.each(nmail, "Address/"){
               |address|
               if address.text != nil and address.text != "" then
                  arrSendTo << address.text
               end
             }
             mailto = arrSendTo
          }                    
          XPath.each(entity, "Notify"){
             |nnotify|      
             notify = fillNotify2Struct(entity.attributes["Name"], nnotify)
          }
          XPath.each(entity, "Events"){
             |eevents|      
             events = fillEventsStruct(entity.attributes["Name"], eevents)
          }
          XPath.each(entity, "ContactInfo"){
             |contactinfo|
             contact = fillContactInfoStruct(entity.attributes["Name"], contactinfo)
          }     
          
          arrEntities << fillEntityStruct(entity.attributes["Name"],
                                          description,
                                          inDir,
                                          outDir,
                                          remote,
                                          txrx,
                                          notify,
                                          mailto,
                                          events,
                                          contact
                                          )
      }
      if @isDebugMode == true then
         puts arrEntities
      end
   end
   ## -------------------------------------------------------------
   
   # Fill an entity struct
   # - mnemonic (IN): entity names
   # - description (IN): description of the Interface
   # - indir (IN):
   # - outdir (IN):
   # - remoteserver (IN):
   # - localserver (IN):
   # - txrxparams (IN):
   # - notifyBymail (IN):
   # - deliverByMail (IN):
   # There is only one point in the class where all dynamic structs 
   # are filled so that it is easier to update/modify the I/F.
   def fillEntityStruct(mnemonic, description, indir, outdir, ftpserver, txrxparams, notify, mailTo, events, contact)                      
      entity = Struct::Entity.new(
                         mnemonic,
                         description,
                         indir,
                         outdir,
                         ftpserver,
                         txrxparams,
                         notify,
                         mailTo,
                         events,
			                contact
                         )
                         
      return entity              
   end
   ## -----------------------------------------------------------
   
   # Fill an FTPServer Struct
   # - mnemonic (IN):
   # - hostname (IN):
   # - port (IN):
   # - user (IN):
   # - password (IN):
	# - isTracked (IN):
   # - isRetrieved (IN):
   # - isSecure (IN):
   # - uploadDir (IN):
   # - downloadDir (IN):
   # - uploadTemp (IN):
   # - downloadTemp (IN):
   # There is only one point in the class where all Dynamic structs 
   # are filled so that it is easier to update/modify the I/Fs.
   def fillFTPServerStruct(mnemonic, xmlstruct)
      bTracked       = false
		bRetrieved     = false
      bSecure        = false
      bVerifyPeerSSL = false
		bCompress      = false
		bDelete        = false      
      bErrorValue    = false
      bPassive       = true
      protocol       = ""
      hostname       = ""
      port           = ""
      user           = ""
      pass           = ""
      nCleanUpFreq   = 0
      
      if !xmlstruct.elements["Hostname"].nil? then
         hostname    = xmlstruct.elements["Hostname"].text
      end
      
      if !xmlstruct.elements["Port"].nil? then
         port    = xmlstruct.elements["Port"].text.to_i
      end
      
      if !xmlstruct.elements["User"].nil? then
         user    = xmlstruct.elements["User"].text.gsub('"', '\"')
      end

      if !xmlstruct.elements["Pass"].nil? then
         pass    = xmlstruct.elements["Pass"].text.gsub('"', '\"')
      end

      if !xmlstruct.elements["SecureFlag"].nil? and !xmlstruct.elements["SecureFlag"].text.nil? then
         if xmlstruct.elements["SecureFlag"].text.upcase == "TRUE" then
            bSecure = true
         else
            bSecure = false
         end
      else
         bSecure = false
      end

      if !xmlstruct.elements["VerifyPeerSSL"].nil? and !xmlstruct.elements["VerifyPeerSSL"].text.nil? then
         if xmlstruct.elements["VerifyPeerSSL"].text.upcase == "TRUE" then
            bVerifyPeerSSL = true
         else
            bVerifyPeerSSL = false
         end
      else
         bVerifyPeerSSL = false
      end

      if !xmlstruct.elements["CleanUpFreq"].nil? and !xmlstruct.elements["CleanUpFreq"].text.nil? then

         if !xmlstruct.elements["CleanUpFreq"].text.empty? then
         
            if xmlstruct.elements["CleanUpFreq"].text.upcase == "NEVER" then
               nCleanUpFreq = 0
            else
               strTemp = xmlstruct.elements["CleanUpFreq"].text.to_s
               if strTemp == "0" then
                  nCleanUpFreq = 0
               else
                  nCleanUpFreq = strTemp.to_i
                  if nCleanUpFreq == 0 then
                     puts
                     puts "Error[#{mnemonic}] CleanUpFreq field only accepts a number value or \"NEVER\" literal"
                     bErrorValue = true
                  end
               end
            end
            
         end
      end
      
      arrDownloadDirs = Array.new

      if !xmlstruct.elements["Protocol"].nil?
           if (xmlstruct.elements["Protocol"].text != nil) and \
               (@protocolArray.include?(xmlstruct.elements["Protocol"].text.upcase)) then
              protocol = xmlstruct.elements["Protocol"].text.upcase    
           else
              puts "Error in ReadInterfaceConfig::fillFTPServerStruct"
              puts "Protocol #{xmlstruct.elements["Protocol"].text.upcase} is not valid"
              exit(99)
           end
      end

#      if protocol != "" then

      # puts protocol

      if xmlstruct.elements["RegisterContentFlag"].text.upcase == "TRUE" then
         bTracked = true
      else
         if xmlstruct.elements["RegisterContentFlag"].text.upcase != "FALSE" then
            puts "Error[#{mnemonic}] RegisterContentFlag field only accepts true|false value"
            bErrorValue = true
         end
      end
     
      if xmlstruct.elements["RetrieveContentFlag"].text.upcase == "TRUE" then
         bRetrieved = true
      else
         if xmlstruct.elements["RetrieveContentFlag"].text.upcase != "FALSE" then
            puts "Error[#{mnemonic}] RetrieveContentFlag field only accepts true|false value"
            bErrorValue = true
         end         
      end


      if !xmlstruct.elements["CompressFlag"].nil? and !xmlstruct.elements["CompressFlag"].text.nil? then
         if xmlstruct.elements["CompressFlag"].text.upcase == "TRUE" then
            bCompress = true
         else
            bCompress = false
         end
      else
         bCompress = false
      end

### DeleteFlag is deprecated since DEC 1.0.14

#      if xmlstruct.elements["DeleteFlag"].text.upcase == "TRUE" then
#         bDelete = true
#      else
#         if xmlstruct.elements["DeleteFlag"].text.upcase != "FALSE" then
#            puts "Error[#{mnemonic}] DeleteFlag field only accepts true|false value"
#            bErrorValue = true
#         end
#      end

      # ----------------------
      # new flag for ftp passive or not (passive is by default)
      
      if !xmlstruct.elements["PassiveFlag"].nil? and !xmlstruct.elements["PassiveFlag"].text.nil? then
         if xmlstruct.elements["PassiveFlag"].text.upcase == "TRUE" then
            bPassive = true
         else
            bPassive = false  
         end
      else
         bPassive = false  
      end
      # ----------------------

      if bErrorValue == true then
         puts
         puts "Error in ReadInterfaceConfig::fillFTPServerStruct ! :-("
         puts
         exit(99)
      end

#      XPath.each(xmlstruct, "DownloadDirs/Directory"){
#         |directory|
#         depth = directory.attributes["DepthSearch"].to_i
#         dir   = expandPathValue(directory.text)
#         arrDownloadDirs << Struct::DownloadDir.new(mnemonic, dir, depth)
#      }

	   ftpstruct   = Struct::Server.new(
                         mnemonic,
                         protocol,
                         hostname,
                         port,
                         user,
                         pass,
								 bTracked,
                         bRetrieved,
                         bSecure,
                         bVerifyPeerSSL,
                         bCompress,
###								 bDelete,
                         bPassive,
                         nCleanUpFreq,
                         nil,
                         nil,
#                         expandPathValue(xmlstruct.elements["UploadDir"].text),
#                         expandPathValue(xmlstruct.elements["UploadTemp"].text),
                         arrDownloadDirs
                         ) 
                                                      
      return ftpstruct      
   end
   #-------------------------------------------------------------
   
   # TXRXParamsStruct is filled in this method.
   # mnemonic,
   # - getMode (IN):
   # - sendMode (IN):
   # - sendCompressMode (IN):
   # - immediateRetries (IN):
   # - loopRetries (IN):
   # - loopDelay (IN):
   # - pollingInterval (IN):
   # There is only one point in the class where all Dynamic structs 
   # are filled so that it is easier to update/modify the I/Fs   
   def fillTXRXParamsStruct(mnemonic, xmlstruct)
      @b4Send  = false
      @b4Rcv   = false
      strSend = xmlstruct.elements["Enabled4Sending"].text.downcase
      strRcv  = xmlstruct.elements["Enabled4Receiving"].text.downcase
      
      if strSend == "true"
         @b4Send = true
      end

      if strRcv == "true"
         @b4Rcv  = true
      end

      pollingSize       = nil
      parallelDownload  = 1
      
      if !xmlstruct.elements["PollingSize"].nil? then
         pollingSize = xmlstruct.elements["PollingSize"].text
      end

      if !xmlstruct.elements["ParallelDownload"].nil? then
         parallelDownload = xmlstruct.elements["ParallelDownload"].text.to_i
      end

      txrxParams  = Struct::TXRXParams.new(
                         mnemonic,
                         @b4Send,
                         @b4Rcv,
                         xmlstruct.elements["ImmediateRetries"].text,
                         xmlstruct.elements["LoopRetries"].text,
                         xmlstruct.elements["LoopDelay"].text,
                         xmlstruct.elements["PollingInterval"].text,
                         pollingSize,
                         parallelDownload
                         )
      return txrxParams
   end
   ## -----------------------------------------------------------

   ## There is only one point in the class where all Dynamic structs 
   ## are filled so that it is easier to update/modify the I/Fs   
   def fillNotify2Struct(entity, xmlstruct)              
      arrNotifyTo = Array.new

      sendNotification = xmlstruct.elements["SendNotification"].text.to_s.downcase

      if sendNotification != "true" and sendNotification != "false" then
         puts
         puts "#{entity} configuration:"
         puts "<Notify><SendNotification> only accepts true | false values"
         puts sendNotification
         puts
         exit(99)         
      end

      if sendNotification == "true" then
         sendNotification = true
      else
         sendNotification = false
      end

      XPath.each(xmlstruct,"To"){
         |to|
         XPath.each(to, "Address"){
             |nnotify|      
             arrNotifyTo << nnotify.text.to_s
         }    
      }

      notify2  = Struct::NotifyTo.new(
                          entity.to_s,
                          sendNotification,
                          arrNotifyTo                  
                         )
      return notify2     
   end
   ## -----------------------------------------------------------

   def fillEventsStruct(interface, xmlstruct)
      arrEvents = Array.new

      XPath.each(xmlstruct, "Event"){
         |event|
         bFoundCmd   = false
         bFoundName  = false
         event.attributes.each_attribute{|attr|
            if attr.name == "Name" then
               bFoundName = true
            end
            if attr.name == "executeCmd" then
               bFoundCmd = true
            end
         }
         if bFoundName == false or bFoundCmd == false then
            puts "Events[#{interface}] configuration is wrong ! :-("
            puts "Name & executeCmd attributes must be present"
            puts
            exit(99)
         end
         eventName = event.attributes["Name"]
         eventCmd  = event.attributes["executeCmd"]
         hEvent    = Hash.new
         hEvent["name"] = eventName.upcase
         hEvent["cmd"]  = eventCmd
         if eventCmd != nil and eventCmd != "" then
            arrEvents << hEvent
         end         
      }

      return Struct::Events.new(interface, arrEvents)

   end
   ## -----------------------------------------------------------      
   
   ## ContactInfoStruct is filled in this method.
   ## mnemonic,
   ## There is only one point in the class where all Dynamic structs 
   ## are filled so that it is easier to update/modify the I/Fs   
   def fillContactInfoStruct(mnemonic, xmlstruct)
      contactInfo  = Struct::ContactInfo.new(
                          mnemonic,
                          xmlstruct.elements["Name"].text,
                          xmlstruct.elements["EMail"].text,
                          xmlstruct.elements["Tel"].text,
                          xmlstruct.elements["Fax"].text,
                          xmlstruct.elements["Address"].text
                         )
   
      return contactInfo
   end
   ## -------------------------------------------------------------     
   
   ## Decode TXRXParams struct.
   ## - txrx (IN): TXRXParams struct
   ## - field (IN): Field name
   def decodeTXRXParams(txrx, field)
      return txrx[field]
   end
   ## -------------------------------------------------------------
   
   ## Search in the array an Entity the given mnemonic.
   ## - mnemonic (IN): Entity name
   ## - arrEntities (IN): Array of Entity structs
   ## - key (IN):
   def searchEntityValue(mnemonic, arrEntities, key)
      nEntities = arrEntities.length
      0.upto(nEntities-1) do |i|
         if arrEntities[i][:mnemonic] == mnemonic then
            return arrEntities[i][key]
         end
      end
      return nil
   end
   ## -------------------------------------------------------------
   
end # class

end # module
