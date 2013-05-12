#!/usr/bin/env ruby

#########################################################################
#
# ===Ruby source for #ReadOrchestratorConfig class          
#
# === Written by DEIMOS Space S.L. (algk)
#
# === MDS-LEGOS => ORC Component
# 
# CVS: $Id: ReadOrchestratorConfig.rb,v 1.6 2009/02/25 09:20:00 algs Exp $
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
   
   def getPriorityRules
      return @@arrOrchPriorityRule
   end
   #-------------------------------------------------------------

   def getDataType (fileType_) 
      @@arrOrchDataProvider.each { |x|
         if x[:fileType] == fileType_ then
            return x[:dataType]
         end
      }
      return nil
   end
   #-------------------------------------------------------------

   # It retrieves the result data-type of a given processing rule
   # receiving as argument the trigger data-type

   def getResultDataType(dataType_)
      @@arrOrchProcessRule.each { |x|
         if x[:triggerInput] == dataType_ then
            return x[:output]
         end
      }
      return nil
   end 
   #-------------------------------------------------------------

   # It retrieves the coverage mode of a given processing rule
   # receiving as argument the trigger data-type

   def getTriggerCoverageByInputDataType(dataType_)
      @@arrOrchProcessRule.each { |x|
         if x[:triggerInput] == dataType_ then
            return x[:coverage]
         end
      }
      return nil
   end 
   #-------------------------------------------------------------

   def getFileType(dataType_)
      @@arrOrchDataProvider.each { |x|
         if x[:dataType] == dataType_ then
            return x[:fileType]
         end
      }
      return nil
   end
   #-------------------------------------------------------------

   def isDataTypeTrigger? (dataType_) 
      @@arrOrchDataProvider.each { |x|
         if x[:dataType] == dataType_ and x[:isTrigger] == true then         
            return true
         end
      }
      return false
   end
   #-------------------------------------------------------------
   
   def isFileTypeTrigger?(fileType_)
      @@arrOrchDataProvider.each { |x|
         if x[:fileType] == fileType_ and x[:isTrigger] == true then            
            return true
         end
      }
      return false
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

   def getListOfInputsByTriggerDataType(dataType_)
      return getListOfInputs(dataType_)
   end
   #-------------------------------------------------------------

   def getListOfInputs(triggerType_)
      @@arrOrchProcessRule.each { |x|
         if x[:triggerInput] == triggerType_ then
            return x[:listOfInputs]
         end
      }
      return nil
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
    

   #--------------------Priority Rules---------------------------
   #-------------------------------------------------------------

   def getRank(dataType)
      @@arrOrchPriorityRule.each { |x|
         if x[:type] == dataType then
            return x[:rank]
         end
         }
      return 0
   end
   #-------------------------------------------------------------

   def getSorting(dataType)
      @@arrOrchPriorityRule.each { |x|
         if x[:type] == dataType then
            return x[:sort]
         end
         }
      return nil
   end
   #-------------------------------------------------------------



   #-------------------------------------------------------------
   #---------------Private section-------------------------------
   #-------------------------------------------------------------
 
private
   
   @@arrOrchDataProvider    = nil
   @@arrOrchPriorityRule    = nil 
   @@arrOrchProcessRule     = nil
   @@miscelanea             = nil
   @@configDirectory        = ""
   #-------------------------------------------------------------
   
   # This method defines all the structs used in this class
   def defineStructs
      Struct.new("OrchDataProvider", :isTrigger, :dataType, :fileType)
      Struct.new("OrchPriorityRule", :rank, :dataType, :fileType, :sort)
      Struct.new("OrchProcessRule", :output, :triggerInput, :coverage, :executable, :listOfInputs)  #output is dataType on the orchestratorConfig.xml (processing rules)
      Struct.new("OrchListOfInputs", :dataType, :coverage, :mandatory, :excludeDataType)
      Struct.new("OrchMiscelanea", :pollingDir, :pollingFreq, :procWorkingDir, :successDir, :failureDir, :breakPointDir, :tmpDir)
   end
   #-------------------------------------------------------------
       
   def fillDataProvider(isTrigger, dataType, fileType)
      return Struct::OrchDataProvider.new(isTrigger, dataType, fileType)
   end
   #-------------------------------------------------------------
  
   def fillPriorityRule(rank, dataType, fileType, sort)
      if sort.upcase != "ASC" and sort.upcase != "DESC" and sort.upcase != "" then
         puts "Fatal Error in ReadOrchestratorConfig::fillPriorityRule  ! :-("
         puts sort
         puts
         exit(99)
      end
      return Struct::OrchPriorityRule.new(rank, dataType, fileType, sort.upcase)
   end
   #-------------------------------------------------------------
  
   def fillProcessRule(output, triggerInput, coverage, executable, listOfInputs)
      return Struct::OrchProcessRule.new(output, triggerInput, coverage, executable, listOfInputs)
   end
   #-------------------------------------------------------------

   #-------------------------------------------------------------

   def fillListOfInputs(dataType, coverage, mandatory, excludeDataType = nil)
      return Struct::OrchListOfInputs.new(dataType, coverage, mandatory, excludeDataType)
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
      parsePriorityRules(xmlOrch)
      parseProcessRules(xmlOrch)
      parseMiscelanea(xmlOrch)
   end   
   #-------------------------------------------------------------
   
 
   # Process File, Data providers section
   # - xmlFile (IN): XML file 
   def parseDataProviders(xmlFile)
      
      isTrigger      = false
      file           = ""
      data           = ""               
      arr            = Array.new     
      
      # For each Data provider entry
      
      XPath.each(xmlFile,"OrchestratorConfiguration/List_of_DataProviders/DataProvider"){      
         |dp|                  

         # Gets the data provider atribute matching "isTriggerType"
         str= dp.attributes["isTriggerType"]
         
         if str == "yes" then
            isTrigger = true
         else
            isTrigger = false
         end

         # Get the 2 children elements of each dataProvider (data type and file type)
         data = dp.elements[1].text
         file = dp.elements[2].text
     
         arr << fillDataProvider(isTrigger, data, file)

      }
      @@arrOrchDataProvider = arr
 
   end
   #---------------------------------------------------------------

   # Process File, Priority Rules section
   # - xmlFile (IN): XML file    
   def parsePriorityRules(xmlFile)

      rank        = 0
      fileType    = ""
      dataType    = ""
      sort        = ""
      arr         = Array.new
         
      XPath.each(xmlFile,"OrchestratorConfiguration/List_of_PriorityRules/PriorityRule"){      
         |aRule|                  

         # Mandatory attributes for each Priority Rule
         
         rank     = aRule.attributes["rank"].to_i
         dataType = aRule.attributes["type"]
         fileType = getFileType(dataType)
         
         # optional attributes
         aRule.attributes.each_attribute{|attr|
            if attr.name == "sort" then
               sort = aRule.attributes["sort"]
               break
            end   
         }

         arr << fillPriorityRule(rank, dataType, fileType, sort)

      }
      @@arrOrchPriorityRule = arr   
   end
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
      
      XPath.each(xmlFile, "OrchestratorConfiguration/List_of_ProcessingRules/ProcessingRule"){      
         |pr|                  

         # Get the data provider atributes
         output        = pr.attributes["dataType"]
         triggerInput  = pr.attributes["triggerType"]
         coverage      = pr.attributes["coverage"]


         # Get the first child on the xml tree (executable)
         executable    = pr.elements[1].text
         
         # Get the List of inputs for each process rule
         XPath.each(pr, "List_of_Inputs/Input"){
            |loi|

            dataType    = loi.attributes["dataType"]         
            coverage_   = loi.attributes["coverage"]
            mandatory   = true
                  
            if loi.attributes["mandatory"].to_s.upcase == "FALSE" then
               mandatory = false
            end
            
            exclude     = nil

            loi.attributes.each_attribute{|attr|
               if attr.name == "exclude" then
                  exclude = loi.attributes["exclude"]
               end   
            }
            @ListOfInputs << fillListOfInputs(dataType, coverage_, mandatory, exclude)
         }    

         arr << fillProcessRule(output, triggerInput, coverage, executable, @ListOfInputs)
         @ListOfInputs = Array.new

      }
      
      @@arrOrchProcessRule = arr
 
   end
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
