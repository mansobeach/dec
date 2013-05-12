#!/usr/bin/env ruby

#########################################################################
#
# ===Ruby source for #ReadOrchestratorConfig class          
#
# === Written by DEIMOS Space S.L. (algk)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: ReadOrchestratorConfig.rb,v 1.17 2007/07/24 17:21:50 decdev Exp $
#
# This class processes ft_incoming_files.xml and ft_outgoing_files.xml.
# which contain all the information about the destination and address
# of all files registered in the DCC.
#
#########################################################################

require 'singleton'
require 'rexml/document'

module ORC

class ReadOrchestratorConfig

   include Singleton
   include REXML

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize
      @isDebugMode        = false                
      checkModuleIntegrity
      defineStructs
      loadData
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadOrchestratorConfig debug mode is on"
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
#----------------Public---Methods-----------------------------
#-------------------------------------------------------------

#-------------------------------------------------------------
   def getAllDataProviders 
      puts @@arrOrchFiles
   end
#-------------------------------------------------------------
   def getAllDataTypes 
    @@arrOrchFiles.each { |x| puts x[:dataType] }
   end
#-------------------------------------------------------------
   def getAllFileTypes 
       @@arrOrchFiles.each { |x| puts x[:fileType] }
   end
#-------------------------------------------------------------
   def getDataType (fileType_) 
      @@arrOrchFiles.each { |x|
         if x[:fileType] == fileType_ then
            puts x[:dataType]
         end
      }
   end
#-------------------------------------------------------------
   def getFileType (dataType_) 
      @@arrOrchFiles.each { |x|
         if x[:dataType] == dataType_ then
            puts x[:fileType]
         end
      }
   end
#-------------------------------------------------------------
   def isDataTypeTrigger (dataType_) 
      @@arrOrchFiles.each { |x|
         if x[:dataType] == dataType_ then
            puts x[:isTrigger]
         end
      }
   end
#-------------------------------------------------------------
   def isFileTypeTrigger (fileType_) 
      @@arrOrchFiles.each { |x|
         if x[:fileType] == fileType_ then
            puts x[:isTrigger]
         end
      }
   end
#-------------------------------------------------------------
   def isValidFileType(fileType_)
      @@arrOrchFiles.each { |x|
         if x[:fileType] == fileType_ then             
            return true 
         end  
         }
      return false
   end

#-------------------------------------------------------------
#---------------Private section-------------------------------
#-------------------------------------------------------------

 
private
   
   @isDebugMode        = false
   
   @@arrOrchFiles  = nil 
   @@configDirectory   = ""

   #-------------------------------------------------------------
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
      
      if bDefined == true
      then      
        configDir         = %Q{#{ENV['DCC_CONFIG']}}        
        @@configDirectory = configDir
                        
        configFile = %Q{#{configDir}/orchestratorConfigFile.xml}      
        if !FileTest.exist?(configFile) then
           bCheckOK = false
           print("\n\n", configFile, " does not exist !  :-(\n\n" )
        end        
        
      end
      if bCheckOK == false then
        puts "DCC_ReadOrchestratorConfig::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end      
   end
   #-------------------------------------------------------------
   
   def defineStructs
      Struct.new("OrchDataProvider", :isTrigger, :dataType, :fileType)
   end
   #-------------------------------------------------------------
   
   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def loadData

      orchFilename = %Q{#{@@configDirectory}/orchestratorConfigFile.xml}
      fileOrch     = File.new(orchFilename)
      xmlOrch      = REXML::Document.new(fileOrch)
      @@arrOrchFiles      = Array.new
      
      if @isDebugMode == true then
         puts "\nProcessing Outgoing Files"
      end
      parseFile(xmlOrch)
   end   
   #-------------------------------------------------------------
   
       
    def fillStruct(it, dt, ft)
      return Struct::OrchDataProvider.new(it, dt, ft)
    end
   #-------------------------------------------------------------


 
   # Process File
   # - xmlFile (IN): XML file 
   def parseFile(xmlFile)
      
      isTrigger      = false
      file           = ""
      data           = ""               
      arr            = Array.new     
      
   # for each data provider...
      XPath.each(xmlFile,"OrchestratorConfiguration/List_of_DataProviders/DataProvider"){      
         |dp|                  

         #gets the data provider atribute matching "isTriggerType"
         str= dp.attributes["isTriggerType"]
         
         if str == "yes" then
            isTrigger = true
         else
            isTrigger = false
         end
   
         #gets the DataTypes (1) for each dataprovider
         XPath.each(dp, "DataType"){
            |dt|
            data = dt.text         
            }

         #gets the FileTypes (1) for each dataprovider
         XPath.each(dp, "FileType"){
            |ft|
            file = ft.text
            }
     
         arr << fillStruct(isTrigger, data, file)

      } #fin del bloque  de data provider
      @@arrOrchFiles = arr
 
   end #end of method parseFile
  

end # class


end # module
