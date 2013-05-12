#!/usr/bin/env ruby

#########################################################################
#
# ===Ruby source for #ReadOrchestratorConfig class          
#
# === Written by DEIMOS Space S.L. (algk)
#
# === MDS-LEGOS => ORC Component
# 
# CVS: $Id: ReadOrchestratorConfig.rb,v 1.3 2009/01/26 19:50:37 decdev Exp $
#
# This class processes $ORC_CONFIG/orchestratorConfigFile.xml
# which contain all the configuration related to the ORCHESTRATOR
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
      @isDebugMode        = true                
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
   # This is the method called when the config files are modified
   def update
      if @isDebugMode then 
         print("\nReceived Notification that the config files have changed\n")
      end   
      loadData
   end
   #-------------------------------------------------------------
   
   def getAllDataProviders 
      return @@arrOrchDataProvider
   end
   #-------------------------------------------------------------

   def getAllDataTypes 
      @@arrOrchDataProvider.each { |x| puts x[:dataType] }
   end
   #-------------------------------------------------------------

   def getAllFileTypes 
      @@arrOrchDataProvider.each { |x| puts x[:fileType] }
   end
   #-------------------------------------------------------------

   def getDataType (fileType_) 
      @@arrOrchDataProvider.each { |x|
         if x[:fileType] == fileType_ then
            return x[:dataType]
         end
      }
   end
   #-------------------------------------------------------------

   def getFileType (dataType_) 
      @@arrOrchDataProvider.each { |x|
         if x[:dataType] == dataType_ then
            return x[:fileType]
         end
      }
   end
   #-------------------------------------------------------------

   def isDataTypeTrigger (dataType_) 
      @@arrOrchDataProvider.each { |x|
         if x[:dataType] == dataType_ then
            return true
         end
      }
   end
   #-------------------------------------------------------------


   def isFileTypeTrigger?(fileType_)
      @@arrOrchDataProvider.each { |x|
         if x[:fileType] == fileType_ then            
             return true
         end
      }
   end

   #-------------------------------------------------------------
   
   def isValidFileType?(fileType_)
      @@arrOrchDataProvider.each { |x|
         if x[:fileType] == fileType_ then             
            return true 
         end  
      }
      return false
   end
   #-------------------------------------------------------------

  
   #----------------Process Rules Methods------------------------
   #-------------------------------------------------------------
   
   def getAllProcessRules 
      @@arrOrchProcessRule.each { |x|
         puts "#{x[:output]} #{x[:triggerInput]} #{x[:coverage]}"
         puts "executable: #{x[:executable]}"
         puts "List of inputs:"
         x[:listOfInputs].each { |y|
              puts "#{y[:dataType]} #{y[:coverage]} #{y[:mandatory]}"
            }
         puts
         }
   end
   #-------------------------------------------------------------

   def getExecutable(triggerType_)
      @@arrOrchProcessRule.each { |x|
         if x[:triggerInput] == triggerType_ then
            return x[:executable]
         end
      }
   end
   #-------------------------------------------------------------

   def getListOfInputs(triggerType_)
      @@arrOrchProcessRule.each { |x|
         if x[:triggerInput] == triggerType_ then
            return x[:listOfInputs]
         end
      }
   end
   #-------------------------------------------------------------


   #----------------Miscelanea Methods---------------------------
   #-------------------------------------------------------------

  
   def getAllMiscelanea
      return @@miscelanea 
   end
   #-------------------------------------------------------------
  
   def getPollingDir
      return @@miscelanea[:pollingDir] 
   end
   #-------------------------------------------------------------
 
   def getPollingFreq
      return @@miscelanea[:pollingFreq] 
   end
   #-------------------------------------------------------------

   def getProcWorkingDir
      return @@miscelanea[:procWorkingDir] 
   end
   #-------------------------------------------------------------

   def getSuccessDir
      return @@miscelanea[:successDir]
   end
   #-------------------------------------------------------------

   def getFailureDir
      return @@miscelanea[:failureDir]
   end
   #-------------------------------------------------------------

   def getBreakPointDir
      return @@miscelanea[:breakPointDir]
   end
   #-------------------------------------------------------------

   def getTmpDir
      return @@miscelanea[:tmpDir]
   end
   #-------------------------------------------------------------
    

   #-------------------------------------------------------------
   #---------------Private section-------------------------------
   #-------------------------------------------------------------

 
private
   
   @@arrOrchDataProvider    = nil 
   @@arrOrchProcessRule     = nil 
   @@miscelanea             = nil
   @@configDirectory  = ""
   #-------------------------------------------------------------
   
   def defineStructs
      Struct.new("OrchDataProvider", :isTrigger, :dataType, :fileType)
      Struct.new("OrchProcessRule", :output, :triggerInput, :coverage, :executable, :listOfInputs)  #output is dataType on the orchestratorConfig.xml (processing rules)
      Struct.new("OrchListOfInputs", :dataType, :coverage, :mandatory)
      Struct.new("OrchMiscelanea", :pollingDir, :pollingFreq, :procWorkingDir, :successDir, :failureDir, :breakPointDir, :tmpDir)
   end
   #-------------------------------------------------------------
   
    
    def fillDataProvider(isTrigger, dataType, fileType)
       return Struct::OrchDataProvider.new(isTrigger, dataType, fileType)
    end
   #-------------------------------------------------------------

        
    def fillProcessRule(output, triggerInput, coverage, executable, listOfInputs)
       return Struct::OrchProcessRule.new(output, triggerInput, coverage, executable, listOfInputs)
    end
   #-------------------------------------------------------------

    def fillListOfInputs(dataType, coverage, mandatory)
       return Struct::OrchListOfInputs.new(dataType, coverage, mandatory)
    end
   #-------------------------------------------------------------

    def fillMiscelanea(pollingDir, pollingFreq, procWorkingDir, successDir, failureDir, breakPointDir, tmpDir)
       return Struct::OrchMiscelanea.new(pollingDir, pollingFreq, procWorkingDir, successDir, failureDir, breakPointDir, tmpDir)
    end
   #-------------------------------------------------------------

   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def loadData

      orchFilename = %Q{#{@@configDirectory}/orchestratorConfigFile.xml}
      fileOrch     = File.new(orchFilename)
      xmlOrch      = REXML::Document.new(fileOrch)     
      
#       if @isDebugMode == true then
#          puts "\nParsing #{orchFilename}"
#       end

      parseDataProviders(xmlOrch)
      parseProcessRules(xmlOrch)
      parseMiscelanea(xmlOrch)
   end   
   #-------------------------------------------------------------
   
 
   # Process File, Data providers module
   # - xmlFile (IN): XML file 
   def parseDataProviders(xmlFile)
      
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

         # gets the 2 childs of each dataProvider (data type and file type)
         data = dp.elements[1].text
         file = dp.elements[2].text
     
         arr << fillDataProvider(isTrigger, data, file)

      } #fin del bloque  de data provider
      @@arrOrchDataProvider = arr
 
   end #end of method parseFile
   #---------------------------------------------------------------

   # Process File, Process rules module
   # - xmlFile (IN): XML file 
   def parseProcessRules(xmlFile)
      
      isTrigger      = false
      file           = ""
      data           = ""     
      executable     = ""          
      arr            = Array.new
      @ListOfInputs  = Array.new
      
   # for each data provider...
      XPath.each(xmlFile,"OrchestratorConfiguration/List_of_ProcessingRules/ProcessingRule"){      
         |pr|                  

      #gets the data provider atributes"
         output=        pr.attributes["dataType"]
         triggerInput=  pr.attributes["triggerType"]
         coverage=      pr.attributes["coverage"]

      #gets the first child on the xml tree (executable)
         executable = pr.elements[1].text
         
      #gets the List of inputs for each process rule
         XPath.each(pr, "List_of_Inputs/Input"){
            |loi|

            dataType=   loi.attributes["dataType"]         
            coverage_=  loi.attributes["coverage"]       
            mandatory=  loi.attributes["mandatory"]
            @ListOfInputs << fillListOfInputs(dataType, coverage_, mandatory)
            }    

         arr << fillProcessRule(output, triggerInput, coverage, executable, @ListOfInputs)
         @ListOfInputs = Array.new

      } #fin del bloque  de data provider
      @@arrOrchProcessRule = arr
 
   end #end of method parseFile
#-------------------------------------------------------------------------

 
   # Process File, Miscelanea Module
   # - xmlFile (IN): XML file 
   def parseMiscelanea(xmlFile)
      
      pollingDir     = ""
      pollingFreq    = ""
      procWorkingDir = ""
      successDir     = ""
      failureDir     = ""
      breakPointDir  = ""
      tmpDir         = ""                   
      
   # for each data provider...
      XPath.each(xmlFile,"OrchestratorConfiguration/Miscelanea"){      
         |mc|  
   #gets the 7 childs on the xml tree
      pollingDir     = mc.elements[1].text         
      pollingFreq    = mc.elements[2].text
      procWorkingDir = mc.elements[3].text
      successDir     = mc.elements[4].text
      failureDir     = mc.elements[5].text
      breakPointDir  = mc.elements[6].text
      tmpDir         = mc.elements[7].text           

      @@miscelanea = fillMiscelanea(pollingDir, pollingFreq, procWorkingDir, successDir, failureDir, breakPointDir, tmpDir)
      } #fin del bloque  de data provider

   end #end of method parseFile
   #---------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
 
      bDefined = true
      bCheckOK = true
   
      if !ENV['ORC_CONFIG'] then
        puts "\nORC_CONFIG environment variable not defined !  :-(\n\n"
        bCheckOK = false
        bDefined = false
      end
      
      if bDefined == true
      then      
        configDir         = %Q{#{ENV['ORC_CONFIG']}}        
        @@configDirectory = configDir
                        
        configFile = %Q{#{configDir}/orchestratorConfigFile.xml}      
        if !FileTest.exist?(configFile) then
           bCheckOK = false
           print("\n\n", configFile, " does not exist !  :-(\n\n" )
        end        
        
      end
      if bCheckOK == false then
        puts "ORC_ReadOrchestratorConfig::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end      
   end
   #-------------------------------------------------------------
  

end # class


end # module
