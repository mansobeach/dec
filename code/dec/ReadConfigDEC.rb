#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #ReadConfigDEC class          
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# $Git: $Id: ReadConfigDEC.rb
#
# Module Data Exchange Component
# This class processes dec_config.xml configuration file.
# which contain all the information about the DEC configuration.
#
#########################################################################

require 'singleton'
require 'rexml/document'

require 'cuc/DirUtils'

module DEC

Reports = ["DELIVEREDFILES", "EMERGENCYDELIVEREDFILES", "RETRIEVEDFILES", "UNKNOWNFILES"]

class ReadConfigDEC

   include Singleton
   include REXML
   
   include CUC::DirUtils
   
   ## -------------------------------------------------------------
  
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
   ## -------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadConfigDEC debug mode is on"
   end
   ## -------------------------------------------------------------
   
   # Reload data from files
   #
   # This is the method called when the config files are modified
   def update
      if @isDebugMode then 
         print("\nReceived Notification that the config files have changed\n")
      end   
      loadData
   end
   ## -------------------------------------------------------------
   
   ## Get all Outgoing Filters
   ##
   def getOutgoingFilters
      return @arrFiltersOutgoing
   end
   ## -------------------------------------------------------------
   
   ## Get all Incoming Filters
   ##
   def getIncomingFilters
      return @arrFiltersIncoming
   end
   ## -------------------------------------------------------------
   
   def getProjectName
      return @projectInfo[:name]
   end
   #-------------------------------------------------------------

   def getGlobalOutbox
      return @globalOutbox
   end
   #-------------------------------------------------------------

   def getProjectID
      return @projectInfo[:id]
   end
   #-------------------------------------------------------------

   def getSatPrefix
      return @satPrefix
   end
   
   ## -------------------------------------------------------------

   def getDeleteDuplicated
      if @deleteDuplicated == 'true' then
         return true
      else
         return false
      end
   end
   ## -----------------------------------------------------------

   ## -----------------------------------------------------------

   def getDeleteUnknown
      if @deleteUnknown == 'true' then
         return true
      else
         return false
      end
   end
   ## -----------------------------------------------------------

   def getDownloadDirs
      if @downloadDirs == 'true' then
         return true
      else
         return false
      end
   end
   ## -----------------------------------------------------------
   
   def getMission
      return @mission
   end

   ## -------------------------------------------------------------
   
   def getReportDir
      return @reportDir
   end
   ## -------------------------------------------------------------

   def deleteSourceFiles?
      if @bDeleteSourceFiles == "false" then
         return false
      end
      
      if @bDeleteSourceFiles == "true" then
         return true
      end
      puts
      puts "Error in ReadConfigDEC::deleteSourceFiles? !! :-("
      puts @bDeleteSourceFiles
      puts
      exit(99)
   end
   #-------------------------------------------------------------

   def getUploadFilePrefix
      return @uploadFilePrefix
   end
   #-------------------------------------------------------------   

   def getUploadDirs
      if @uploadDirs == 'true' then
         return true
      else
         return false
      end
   end
   #-------------------------------------------------------------   

   def getReports
      return @arrReports
   end
   #-------------------------------------------------------------

private

   @@isModuleOK        = false
   @@isModuleChecked   = false
   @isDebugMode        = false
   
   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true
   
      if !ENV['DEC_CONFIG'] then
         puts "\nDEC_CONFIG environment variable not defined !  :-(\n\n"
         bCheckOK = false
         bDefined = false
      end
      
      if bDefined == true then      
        configDir         = nil
        if ENV['DEC_CONFIG'] then
           configDir         = %Q{#{ENV['DEC_CONFIG']}}  
        end
                
        @@configDirectory = configDir
        
        configFile = %Q{#{configDir}/dec_config.xml}        
        if !FileTest.exist?(configFile) then
           bCheckOK = false
           print("\n\n", configFile, " does not exist !  :-(\n\n" )
        end
        
      end
      if bCheckOK == false then
        puts "ReadConfigDEC::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end      
   end
   #-------------------------------------------------------------
   
	# This method defines all the structs used
	def defineStructs
	   Struct.new("Project", :name, :id)
      Struct.new("Report", :name, :enabled, :desc, :fileClass, :fileType)
	end
	## -----------------------------------------------------------
   
   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def loadData
     configFilename           = %Q{#{@@configDirectory}/dec_config.xml}
     fileConfig               = File.new(configFilename)
     xmlConfig                = REXML::Document.new(fileConfig)
     @arrFiltersOutgoing      = Array.new
     @arrFiltersIncoming      = Array.new
     if @isDebugMode == true then
        puts "\nProcessing DEC Config File"
     end
     processConfigFile(xmlConfig)
   end   
   ## -----------------------------------------------------------
   
   # Process File
   # - xmlFile (IN): XML file
   # - arrFile (OUT): 
   def processConfigFile(xmlFile)
      description          = ""
      newFile              = nil
      projectName          = "   "
      projectId            = ""
      @mission             = ""
      arrFromList          = Array.new
      arrToList            = Array.new
      @satPrefix           = ""
      bDeleteSourceFiles   = nil
      @uploadFilePrefix    = ""
      @uploadDirs          = ""
      @bDeleteSourceFiles  = ""
      @globalOutbox        = ""
      @arrReports          = Array.new
      enabled              = ""
      desc                 = ""
      fileClass            = "" 
      fileType             = ""

      
      XPath.each(xmlFile, "Configuration/Project/Name"){      
         |name|
         projectName = name.text
      }   
      
      XPath.each(xmlFile, "Configuration/Project/Id"){      
         |id|
         projectId   = id.text             
      }

      XPath.each(xmlFile, "Configuration/Project/Mission"){      
         |id|
         @mission    = id.text             
      }
      
      @projectInfo = Struct::Project.new(projectName, projectId)

      ## -----------------------------------------

      XPath.each(xmlFile, "Configuration/Filters/OutgoingFilters"){      
         |filters|                  
         XPath.each(filters, "Filter"){
            |filter|
            @arrFiltersOutgoing << filter.text
         }           
      }
      
      @arrFiltersOutgoing = @arrFiltersOutgoing.uniq
      
      ## -----------------------------------------
 
       XPath.each(xmlFile, "Configuration/Filters/IncomingFilters"){      
         |filters|                  
         XPath.each(filters, "Filter"){
            |filter|
            @arrFiltersIncoming << filter.text
         }           
      }
      
      @arrFiltersIncoming = @arrFiltersIncoming.uniq
      
      ## -----------------------------------------
      
      # Process the Configuration Upload Options
      XPath.each(xmlFile, "Configuration/Options/Upload"){      
         |option|  
         XPath.each(option, "DeleteSourceFiles"){
            |option_1|
            bDeleteSourceFiles = option_1.text.downcase
         }
         XPath.each(option, "UploadFilePrefix"){
            |option_1|
            @uploadFilePrefix = option_1.text.downcase
         }
         XPath.each(option, "UploadDirs"){
            |option_1|
            @uploadDirs = option_1.text.downcase
         }
      }
      
      ## -----------------------------------------
      
      # Process the Configuration Download Options
      XPath.each(xmlFile, "Configuration/Options/Download"){      
         |option|  

         XPath.each(option, "DownloadDirs"){
            |option_1|
            @downloadDirs = option_1.text.downcase
         }
         XPath.each(option, "DeleteDuplicated"){
            |option_1|
            @deleteDuplicated = option_1.text.downcase
         }
         XPath.each(option, "DeleteUnknown"){
            |option_1|
            @deleteUnknown = option_1.text.downcase
         }
      }     
      
      ## -----------------------------------------
      
      
      @bDeleteSourceFiles = bDeleteSourceFiles

      # Process GlobalOutbox
      XPath.each(xmlFile, "Configuration/GlobalOutbox"){      
         |repository|
         @globalOutbox = expandPathValue(repository.text)
      }
      XPath.each(xmlFile, "Configuration/SatPrefix"){      
         |prefix|
         @satPrefix = prefix.text
      }

      # Process Report Dir
      XPath.each(xmlFile, "Configuration/ReportDir"){      
         |reportDir|
         @reportDir = expandPathValue(reportDir.text)
      }

      # Process Reports Configuration
      XPath.each(xmlFile, "Configuration/Reports"){      
         |reports|

         XPath.each(reports, "Report"){
            |report|
            
#             XPath.each(report, "Enabled"){      
#                |isEnabled|
#                enabled = isEnabled.text.to_s.downcase
#             }
# 
#             XPath.each(report, "Desc"){      
#                |aDesc|
#                desc = aDesc.text
#             }
# 

            enabled     = report.elements[1].text
            desc        = report.elements[2].text

            fileClass = ""
            XPath.each(report, "FileClass"){      
                |aFileClass|
                fileClass = aFileClass.text.to_s
             }
 
            XPath.each(report, "FileType"){      
                |aFileType|
                fileType = aFileType.text.to_s.upcase
             }
    
            @arrReports << fillReportStruct(report.attributes["Name"], enabled, desc, fileClass, fileType)
         }           
      }

   end
   #-------------------------------------------------------------
   
   # ReportStruct is filled in this method.
   # - name (IN):
   # - desc (IN):
   # - fileType (IN):
   # There is only one point in the class where all Dynamic structs 
   # are filled so that it is easier to update/modify the I/Fs   
   def fillReportStruct(name, enabled, desc, fileClass, fileType)
      name = name.to_s.upcase

      if enabled != "true" and enabled != "false" then
         puts
         puts "Error in Report #{name} - Enabled allowed values are true | false"
         puts "Enabled value is #{enabled}"
         puts
         puts "Error in dec_config.xml file ! :-("
         puts
         exit(99)
      end
      
      if enabled == "true" then
         enabled = true
      else
         enabled = false
      end
      
      if fileType == nil then
         puts
         puts "Error in Report #{name} - FileType cant be blank"
         puts
         puts "Error in dec_config.xml file ! :-("
         puts
         exit(99) 
      end

      if fileType.length != 10 then
         puts
         puts "Error in Report #{name} - FileType must have 10 characters"
         puts "FileType value is #{fileType} with #{fileType.length} characters"
         puts
         puts "Error in dec_config.xml file ! :-("
         puts
         exit(99)
      end
      bFound = false
      
      Reports.each{|aReport|
         if name == aReport then
            bFound = true
         end
      }

      if bFound == false then
         puts
         puts "Error in Report #{name}"
         puts "Name value is #{name} and allowed values are: #{Reports}"
         puts
         puts "Error in dec_config.xml file ! :-("
         puts
         exit(99)                  
      end
      
      return Struct::Report.new(name, enabled, desc, fileClass, fileType)
   end
   #-------------------------------------------------------------

end # class

end # module
