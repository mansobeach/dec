#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #ReadConfigDCC class          
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Collector Component
# 
# CVS: $Id: ReadConfigDCC.rb,v 1.8 2007/12/05 15:17:03 decdev Exp $
#
# Module Data Distributor Component
# This class processes dcc_config.xml configuration file.
# which contain all the information about the DCC configuration.
#
#########################################################################

require 'singleton'
require 'rexml/document'

require 'cuc/DirUtils'


module DCC

Reports = ["RETRIEVEDFILES", "UNKNOWNFILES"]

class ReadConfigDCC

   include Singleton
   include REXML
   
   include CUC::DirUtils
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
      puts "ReadConfigDCC debug mode is on"
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
   
   # Get all Incoming Filters
   #
   def getIncomingFilters
      return @arrFilters
   end
   #-------------------------------------------------------------
   
   def getProjectName
      return @projectInfo[:name]
   end
   #-------------------------------------------------------------
   #-------------------------------------------------------------

   def getProjectID
      return @projectInfo[:id]
   end
   #-------------------------------------------------------------

   def getMission
      return @mission
   end
   #-------------------------------------------------------------

   def getSatPrefix
      return @satPrefix
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
   
      if !ENV['DCC_CONFIG'] then
        puts "\nDCC_CONFIG environment variable not defined !  :-(\n\n"
        bCheckOK = false
        bDefined = false
      end
      
      if bDefined == true then      
        configDir         = %Q{#{ENV['DCC_CONFIG']}}        
        @@configDirectory = configDir
        
        configFile = %Q{#{configDir}/dcc_config.xml}        
        if !FileTest.exist?(configFile) then
           bCheckOK = false
           print("\n\n", configFile, " does not exist !  :-(\n\n" )
        end
        
      end
      if bCheckOK == false then
        puts "DCC_ReadFileDestination::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end      
   end
   #-------------------------------------------------------------
   
	# This method defines all the structs used
	def defineStructs
	   Struct.new("Project", :name, :id)
      Struct.new("Report", :name, :enabled, :desc, :fileType)
	end
	#-------------------------------------------------------------   
   
   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def loadData
     configFilename   = %Q{#{@@configDirectory}/dcc_config.xml}
     fileConfig       = File.new(configFilename)
     xmlConfig        = REXML::Document.new(fileConfig)
     @arrFilters      = Array.new
     if @isDebugMode == true then
        puts "\nProcessing DCC Config File"
     end
     processConfigFile(xmlConfig, @arrFilters)
   end   
   #-------------------------------------------------------------
   
   # Process File
   # - xmlFile (IN): XML file
   # - arrFile (OUT): 
   def processConfigFile(xmlFile, arrFilters)
      description    = ""
      newFile        = nil    
      compressMethod = nil
      projectName    = ""
      projectId      = ""
      arrFromList    = Array.new
      arrToList      = Array.new
      bDeleteSourceFiles  = nil
      @bDeleteSourceFiles = ""
      @satPrefix          = ""
      @mission            = ""
      @arrReports         = Array.new
      enabled             = ""
      desc                = ""
      fileType            = ""
      
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

      XPath.each(xmlFile, "Configuration/Filters/IncomingFilters"){      
         |filters|
         XPath.each(filters, "Filter"){
            |filter|
            arrFilters << filter.text
         }           
      }
      @arrFilters = arrFilters.uniq
      
      XPath.each(xmlFile, "Configuration/SatPrefix"){      
         |prefix|
         @satPrefix = prefix.text
      }

      XPath.each(xmlFile, "Configuration/Reports"){      
         |reports|

         XPath.each(reports, "Report"){
            |report|
            
            XPath.each(report, "Enabled"){      
               |isEnabled|
               enabled = isEnabled.text.to_s.downcase
            }

            XPath.each(report, "Desc"){      
               |aDesc|
               desc = aDesc.text
            }

            XPath.each(report, "FileType"){      
               |aFileType|
               fileType = aFileType.text.to_s.upcase
            }
      
            @arrReports << fillReportStruct(report.attributes["Name"], enabled, desc, fileType)
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
   def fillReportStruct(name, enabled, desc, fileType)
      name = name.to_s.upcase

      if enabled != "true" and enabled != "false" then
         puts
         puts "Error in Report #{name} - Enabled allowed values are true | false"
         puts "Enabled value is #{enabled}"
         puts
         puts "Error in dcc_config.xml file ! :-("
         puts
         exit(99)
      end
      
      if enabled == "true" then
         enabled = true
      else
         enabled = false
      end

      if fileType.length != 10 then
         puts
         puts "Error in Report #{name} - FileType must have 10 characters"
         puts "FileType value is #{fileType} with #{fileType.length} characters"
         puts
         puts "Error in dcc_config.xml file ! :-("
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
         puts "Error in dcc_config.xml file ! :-("
         puts
         exit(99)                  
      end
      
      return Struct::Report.new(name, enabled, desc, fileType)
   end
   #-------------------------------------------------------------

end # class

end # module
