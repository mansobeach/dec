#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #ReadMinarcConfig class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component -> minArc
### 
### Git:  $Id: ReadMinarcConfig.rb,v 1.1 2008/03/11 09:49:13 decdev Exp $
###
### Module MINARC
### This class reads and decodes MINARC configuration stored 
### minarc_config.xml.
###
#########################################################################

require 'singleton'
require 'rexml/document'

require 'cuc/DirUtils'


module ARC

class ReadMinarcConfig

   include Singleton
   include REXML
   include CUC::DirUtils
   
   ## -------------------------------------------------------------   
   
   ## Class contructor
   def initialize
      @@isModuleOK        = false
      @@isModuleChecked   = false
      @isDebugMode        = false
      @inventory          = nil
      @node               = "node not defined"
      @clientUser         = nil
      @clientPass         = nil
      @verifyPeerSSL      = false
      checkModuleIntegrity
		defineStructs
      loadData
   end
   ## -------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "ReadMinarcConfig debug mode is on"
   end
   ## -------------------------------------------------------------
   
   # Reload data from configuration file
   #
   # This is the method called by the Observer when the config files are modified.
   def update
      if @isDebugMode then 
         print("\nReceived Notification that the config files have changed\n")
      end   
      @arrRules = loadData
   end
   #-------------------------------------------------------------
   
   def getAllRules
      return @arrRules
   end
   #-------------------------------------------------------------

   def getNbRules
      return @arrRules.length
   end
   #-------------------------------------------------------------

   def getFrequencies
      arrTmp = Array.new
      @arrRules.each{|r|
         arrTmp << r[:frequency]
      }
      if arrTmp.length > 1 then
         arrTmp = arrTmp.uniq
      end
      return arrTmp
   end
   ## ------------------------------------------------------------

   def getNode
      return @node
   end
   ## -----------------------------------------------------------

   def getInventory
      return @inventory
   end
   ## -----------------------------------------------------------

   def getArchiveRoot
      return @workflow[:archiveRoot]
   end
   ## -----------------------------------------------------------

   def getArchiveError
      return @workflow[:archiveError]
   end
   ## -----------------------------------------------------------

   def getArchiveServer
      return @workflow[:archiveServer]
   end
   ## -----------------------------------------------------------

   def getTempDir
      return @workflow[:archiveTemp]
   end
   ## -----------------------------------------------------------

   def getArchiveIntray
      return @workflow[:archiveIntray]
   end
   ## -----------------------------------------------------------

   def getClientUser
      return @clientUser
   end
   ## -----------------------------------------------------------

   def getClientPassword
      return @clientPass
   end
   ## -----------------------------------------------------------

   def getClientVerifyPeerSSL
      return @verifyPeerSSL
   end
   ## -----------------------------------------------------------
   
private

   @@isModuleOK        = false
   @@isModuleChecked   = false
   @isDebugMode        = false
   @@configDirectory   = ""  

   ## -------------------------------------------------------------
   
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true

      if !ENV['MINARC_CONFIG'] then
         ENV['MINARC_CONFIG'] = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      end

      if !ENV['MINARC_CONFIG'] then
        puts "MINARC_CONFIG environment variable not defined !  :-(\n"
        bCheckOK = false
        bDefined = false
      end
            
      if bDefined == true then      
         configDir         = %Q{#{ENV['MINARC_CONFIG']}}        
         @@configDirectory = configDir
        
         configFile = %Q{#{configDir}/minarc_config.xml}        
         if !FileTest.exist?(configFile) then
            bCheckOK = false
            print("\n\n", configFile, " does not exist !  :-(\n\n" )
         end           
      end      
      if bCheckOK == false then
         puts "ReadMinarcConfig::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end      
   end
   ## -----------------------------------------------------------
   
   ## Load the file into the an internal struct.
   ##
   ## The struct is defined in the class Constructor. See #initialize.
   def loadData
      # self.setDebugMode
      externalFilename = %Q{#{@@configDirectory}/minarc_config.xml}
      fileExternal     = File.new(externalFilename)
      xmlFile          = REXML::Document.new(fileExternal)

      if @isDebugMode == true then
         puts "\nProcessing minarc_config.xml"
      end
      
      processNode(xmlFile)
      
      @arrRules = processRules(xmlFile)
      @workflow = parseWorkflow(xmlFile)
      
      parseInventoryConfig(xmlFile)
      
      processClientConfig(xmlFile)
   end   
   ## -----------------------------------------------------------
   
   def processNode(xmlFile)
      XPath.each(xmlFile, "Configuration/Node"){ |node|
         if node.text != nil and node.text != "" then
            @node = expandPathValue(node.text)
         end
      }
   end
   ## -----------------------------------------------------------
   
   ## Process the xml file decoding all the Rules
   ## - xmlFile (IN): XML configuration file
   def processRules(xmlFile)

      arrRules  = Array.new

      frequency = nil
      freqUnit  = nil
      filetype  = nil
      rule      = nil
      date      = nil
      age       = nil
      ageUnit   = nil
      
      XPath.each(xmlFile, "Configuration/CleanUp"){ |cleanUp|
         frequency = cleanUp.attributes["Frequency"]
         freqUnit  = cleanUp.attributes["Unit"]

         frequency = conv2seconds(frequency, freqUnit)

         XPath.each(cleanUp, "List_of_CleanUpRules"){ |list|
         
            XPath.each(list, "CleanUpRule"){ |r|
               filetype = r.attributes["Filetype"]
               rule     = r.attributes["Rule"]
               date     = r.attributes["Date"]
               age      = r.attributes["Age"]
               ageUnit  = r.attributes["Unit"]

               age = conv2seconds(age, ageUnit)

               arrRules << fillCleanUpRuleStruct(frequency, filetype, rule, date, age)
            }

         }
      }

      if @isDebugMode == true then
         puts arrRules
      end

      return arrRules
	
   end
   
   ## -----------------------------------------------------------

   def parseWorkflow(xmlFile)
   
      archiveServer  = ""
      archiveRoot    = nil
      archiveError   = nil
      archiveIntray  = nil
      tempDir        = nil
   
      XPath.each(xmlFile, "Configuration/Workflow"){     
         |workflow|

 
         XPath.each(workflow, "ArchiveServer"){      
            |value|
            if value.text != nil and value.text != "" then
               archiveServer = expandPathValue(value.text)
            end
         }

         XPath.each(workflow, "ArchiveRoot"){      
            |value|
            archiveRoot = expandPathValue(value.text)
         }


         XPath.each(workflow, "ArchiveError"){      
            |value|
            archiveError = expandPathValue(value.text)
         }

         XPath.each(workflow, "ArchiveIntray"){      
            |value|
            archiveIntray = expandPathValue(value.text)
         }

         XPath.each(workflow, "TempDir"){      
            |value|
            tempDir = expandPathValue(value.text)
         }
      
      }

         

      return Struct::Workflow.new(archiveServer, 
                                  archiveRoot,
                                  archiveError,
                                  archiveIntray,
                                  tempDir)

   end
   ## -----------------------------------------------------------

   def parseInventoryConfig(xmlFile)
         
      ## -----------------------------------------
      ## Process Reports Configuration
      XPath.each(xmlFile, "Configuration/Inventory"){      
         |inventory|

         db_adapter  = ""
         db_host     = ""
         db_port     = ""
         db_name     = ""
         db_user     = ""
         db_pass     = ""

         XPath.each(inventory, "Database_Adapter"){
            |adapter|  
            db_adapter = adapter.text.to_s
         }

         XPath.each(inventory, "Database_Host"){
            |name|
            db_host  = name.text.to_s
         }

         XPath.each(inventory, "Database_Port"){
            |name|
            db_port  = name.text.to_s
         }
         
         XPath.each(inventory, "Database_Name"){
            |name|
            db_name  = name.text.to_s
         }

         XPath.each(inventory, "Database_User"){
            |user|
            db_user  = user.text.to_s
         }

         XPath.each(inventory, "Database_Password"){
            |pass|
            db_pass  = pass.text.to_s   
         }
         
         @inventory = Struct::Inventory.new(db_adapter, \
                                             db_host, \
                                             db_port, \
                                             db_name, \
                                             db_user, \
                                             db_pass)
          
      }
      ## -----------------------------------------

      if @isDebugMode == true then
         puts @inventory
      end

      ## -----------------------------------------

   end

   ## -----------------------------------------------------------
   
   def processClientConfig(xmlFile)
         
      ## -----------------------------------------
      ## Process Reports Configuration
      XPath.each(xmlFile, "Configuration/Client"){      
         |client|

         XPath.each(client, "VerifyPeerSSL"){
            |ssl|  
             if ssl.text.to_s.downcase! == "true" then
                @verifyPeerSSL = true
             else
                @verifyPeerSSL = false
             end
         }

         XPath.each(client, "User"){
            |user|  
            @clientUser = user.text.to_s
         }

         XPath.each(client, "Password"){
            |password|  
            @clientPass = password.text.to_s
         }
      }
      
      ## -----------------------------------------
      
   end
   
   ## -----------------------------------------------------------

   # converts times in seconds according to the original unit.
   def conv2seconds(value, unit)
      newValue = nil

      case unit
         when "s" then newValue = value.to_i
         when "h" then newValue = (value.to_i * 3600)
         when "d" then newValue = (value.to_i * 86400)
         when "w" then newValue = (value.to_i * 86400 * 7)
         when "m" then newValue = (value.to_i * 86400 * 30)
         when "y" then newValue = (value.to_i * 86400 * 365)
      end

      return newValue
   end
   ## -----------------------------------------------------------  
   
	## Define all the structs
	def defineStructs
	   
      Struct.new("CleanUpRule", :frequency, :filetype, :rule, :date, :age)
      
      Struct.new("Workflow",     :archiveServer,\
                                 :archiveRoot,\
                                 :archiveError,\
                                 :archiveIntray,\
                                 :archiveTemp)

      if Struct::const_defined? "Inventory" then
         Struct.const_get "Inventory"
      else
         Struct.new("Inventory", :db_adapter, \
                              :db_host, \
                              :db_port, \
                              :db_name, \
                              :db_username, \
                              :db_password)
      end
   end
   ## -----------------------------------------------------------

   # Fill a Send;ailStruct struct
   # - smtpserver (IN):
   # - port (IN):
   # - user (IN):
   # - pass (IN):
   # There is only one point in the class where all dynamic structs 
   # are filled so that it is easier to update/modify the I/F.
   def fillCleanUpRuleStruct(frequency, filetype, rule, date, age)                      
      cleanUpRuleStruct = Struct::CleanUpRule.new(frequency, filetype,
                                  rule,
                                  date,
			                         age)
      return cleanUpRuleStruct               
   end
   ## -------------------------------------------------------------
    
	
end # class

end # module

