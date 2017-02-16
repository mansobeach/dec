#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #ReadMailConfig class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS:  $Id: ReadMinarcConfig.rb,v 1.1 2008/03/11 09:49:13 decdev Exp $
#
# Module MINARC
# This class reads and decodes MINARC configuration stored 
# minarc_config.xml.
#
#########################################################################


require 'singleton'
require 'rexml/document'

require 'cuc/DirUtils'


module MINARC

class ReadMinarcConfig

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
      @arrRules = loadData
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "ReadMinarcConfig debug mode is on"
   end
   #-------------------------------------------------------------
   
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
   #-------------------------------------------------------------

private

   @@isModuleOK        = false
   @@isModuleChecked   = false
   @isDebugMode        = false
   @@configDirectory   = ""  

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true
   
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
   #-------------------------------------------------------------
   
   # Load the file into the an internal struct.
   #
   # The struct is defined in the class Constructor. See #initialize.
   def loadData
      externalFilename = %Q{#{@@configDirectory}/minarc_config.xml}
      fileExternal     = File.new(externalFilename)
      xmlFile          = REXML::Document.new(fileExternal)

      if @isDebugMode == true then
         puts "\nProcessing minarc_config.xml"
      end
      
      return processRules(xmlFile)
   end   
   #-------------------------------------------------------------
   
   # Process the xml file decoding all the Rules
   # - xmlFile (IN): XML configuration file
   def processRules(xmlFile)

      arrRules  = Array.new

      frequency = nil
      freqUnit  = nil
      filetype  = nil
      rule      = nil
      date      = nil
      age       = nil
      ageUnit   = nil
      
      XPath.each(xmlFile, "MINARC_CONFIG/CleanUp"){ |cleanUp|
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
   #-------------------------------------------------------------

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
   #-------------------------------------------------------------  
   
	# Define all the structs
	def defineStructs
	   Struct.new("CleanUpRule", :frequency, :filetype, :rule, :date, :age)
   end
   #-------------------------------------------------------------

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
   #-------------------------------------------------------------
    
	
end # class

end # module

