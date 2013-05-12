#!/usr/bin/ruby

#########################################################################
#
# === Ruby source for #CheckerOrchestratorConfig class
#
# === Written by DEIMOS Space S.L. (algk)
#
# ==  Data Exchange Component -> Data Collector Component
#
# CVS:  $Id: CheckerOrchestratorConfig.rb,v 1.2 2009/03/17 08:25:11 algs Exp $
#
#
# === This class verifies the integrity of the orchestratorConfigFile.xml
#
#########################################################################


require 'orc/ReadOrchestratorConfig'
require 'cuc/DirUtils'


module ORC


class CheckerOrchestratorConfig

   include CUC::DirUtils
   #--------------------------------------------------------------

   # Class constructor.
   def initialize
      checkModuleIntegrity
      @orcReadConf = ORC::ReadOrchestratorConfig.instance
      @arrDataTypes = @orcReadConf.getAllDataTypes
      @arrFileTypes = @orcReadConf.getAllFileTypes
      @arrTriggerTypeInputs =  @orcReadConf.getAllTriggerTypeInputs
   end
   #-------------------------------------------------------------


   def check
      checkDataProvider    
      checkPriorityRules    
      checkProcessingRules
      checkMiscelanea    
   end
   #-------------------------------------------------------------

   def checkDataProvider
      puts "================================================"
      puts "Checking Data Providers section :"
      puts
    
      # Checks the Data type uniqueness
      arrDataTypes = @arrDataTypes.clone
      while arrDataTypes.empty? == false
         dataType = arrDataTypes.pop
         if arrDataTypes.include?(dataType) == true
            print "error   -> dataType    ", dataType.ljust(10), " is repeated \n"
         end
      end
      #-----------------------------------

      # Checks the file type length and uniqueness
      arrFileTypes = @arrFileTypes.clone
      while arrFileTypes.empty? == false
         fileType = arrFileTypes.pop
         if fileType.length != 10 then
            puts "error   -> fileType    #{fileType} length is not correct"
         else
            if arrFileTypes.include?(fileType) == true
               puts "error   -> fileType    #{fileType} is repeated"
            end
         end       
      end
      #------------------------------------

      # Check if its trigger and if there is a processing rule asociated    
      @arrDataTypes.each { |dataType|
         trig = @orcReadConf.isDataTypeTrigger?(dataType)
         if trig == nil then
            print "error   -> TriggerType ", dataType.ljust(10)," :invalid trigger value \n"
         else
         if trig == true then
            found = false
            @arrTriggerTypeInputs.each {|triggerInput|
               if triggerInput == dataType then
                  found = true
                  break
                end
            }
            if found == false then
              print "warning -> TriggerType ", dataType.ljust(10), " has no processing Rule \n"
            end
         end
end
      }
   puts
   end #end of checkDataProvider
   #-------------------------------------------------------------


   def checkPriorityRules
      puts "================================================"
      puts "Checking priority rules section :"
      puts

      @arrAllDataTypePri = @orcReadConf.getAllDataTypePri

      # Check if the dataTypes in the list are defined
      @arrAllDataTypePri.each { |dataTypePri|
         if @orcReadConf.isValidDataType?(dataTypePri) == false
            print "error   -> in priority rule list: ", dataTypePri.ljust(10), " is not defined \n"
         end
      }
      #------------------------------------

      # Check if all dataTypes in list are trigger
      @arrAllDataTypePri.each { |dataTypePri|
         trig = @orcReadConf.isDataTypeTrigger?(dataTypePri)
         if trig == nil
            print "error   -> in DataProvider def's: ", dataTypePri.ljust(10), " has not a valid trigger value \n"
         else
            if trig == false
               print "warning -> in priority rule list: ", dataTypePri.ljust(10), " is not trigger \n"
            end
         end
      }
   puts
   end # end of checkPriorityRules
   #-------------------------------------------------------------


   def checkProcessingRules
      puts "================================================"
      puts "Checking processing rules section :"
      puts      

      # Checks the Trigger input uniqueness
      arrTriggerInput = @arrTriggerTypeInputs.clone
      while arrTriggerInput.empty? == false
         triggerInput = arrTriggerInput.pop
         if arrTriggerInput.include?(triggerInput) == true
            print "error   -> Trigger input ", triggerInput.ljust(10), " is repeated \n"
         end
      end
      #------------------------------------      

      # Check if triggerType is a valid data provider and a trigger
      @arrTriggerTypeInputs.each {|triggerInput|
         if @orcReadConf.isValidDataType?(triggerInput) == true then
            trig = @orcReadConf.isDataTypeTrigger?(triggerInput) 
            if trig == nil
                  print "error   -> DataProvider  ", triggerInput.ljust(10), " has not a valid trigger value \n"
            else
               if trig == false then
                  print "warning -> Trigger input ", triggerInput.ljust(10), " is not trigger \n"
               end
            end
         else
            print "error   -> Trigger input ", triggerInput.ljust(10), " is not defined \n"
         end
      }
      #------------------------------------

       # Check if executable is in path
      @arrTriggerTypeInputs.each {|triggerInput|
         ex = @orcReadConf.getExecutable(triggerInput)
         ex = ex.sub(/\s(\w|\W)*/,'')
         ret = system("which #{ex} > /dev/null 2>&1")
         if ret == false
            print "error   -> Executable of ", triggerInput.ljust(10), " is not in path \n"
         end
      }
       #------------------------------------

      # Check Data type output is in data Provider
      arrOutputs = @orcReadConf.getAllOutputs
      arrOutputs.each { |output|
         if @orcReadConf.isValidDataType?(output) == false then
            print "error   -> output        ", output.ljust(10)," is not defined \n"
         end
      }
      #------------------------------------

      # Check coverage is in list TBD (atm the list is defined in the private section)
      @arrTriggerTypeInputs.each {|triggerInput|
         cov = @orcReadConf.getTriggerCoverageByInputDataType(triggerInput)

         #atm the list is defined in the private section of CheckerOrchestratorConfig
         arrCoverages = getListOfTriggerCoverages
         found = false
         arrCoverages.each{ |cover|
            if cover == cov then
               found = true
               break
            end
         }
         if found  == false
            print "error   -> Trigger input ", triggerInput.ljust(10)," :coverage ", cov.ljust(10)," is not a valid value \n"
         end
      }

      # Check input dependencies
      @arrTriggerTypeInputs.each {|triggerInput|

         arrListOfInputs = @orcReadConf.getListOfInputs(triggerInput)
         arrListOfInputs.each{|input|

            if @orcReadConf.isValidDataType?(input[:dataType]) == false then
               print "error   -> Trigger input ", triggerInput.ljust(10)," :Input ", input[:dataType].ljust(10)," not defined \n"
            end
            cov = input[:coverage]

            #atm the list is defined in the private section of CheckerOrchestratorConfig
            arrCoverages = getListOfDepCoverages
            found = false
            arrCoverages.each{ |cover|
               if cover == cov then
                  found = true
                  break                  
               end
            }
            if found  == false then
               print "error   -> Trigger input ", triggerInput.ljust(10)," :Input ", input[:dataType].ljust(10), " :coverage ",cov.ljust(10)," is not a valid value \n"
            end

            if input[:mandatory] != "true" and input[:mandatory] != "false"
               print "error   -> Trigger input ", triggerInput.ljust(10)," :Input ", input[:dataType].ljust(10), " :mandatory has not a valid value \n"
            end
         }
      }
   puts
   end #end of checkProcessingRules
   #-------------------------------------------------------------


   def checkMiscelanea
      puts "================================================"
      puts "Checking Miscelanea section :"
      puts

      def slashChecker(str,dir)
         if FileTest.exist?(dir) == false then
            puts "error   -> in #{dir}"
         end
      end
    
      pollDir = @orcReadConf.getPollingDir
      slashChecker("pollDir",pollDir)

      polFreq = @orcReadConf.getPollingFreq.to_i
      if polFreq == 0 then
         puts "error   -> in polling frequency (0 or not a number)"
      end
      if polFreq < 0 then
         puts "error   -> in polling frequency (negative value)"
      end

      procWorkingDir = @orcReadConf.getProcWorkingDir
      slashChecker("procWorkingDir",procWorkingDir)

      successDir = @orcReadConf.getSuccessDir
      slashChecker("successDir",successDir)

      failureDir = @orcReadConf.getFailureDir
      slashChecker("failureDir",failureDir)

      breakPointDir = @orcReadConf.getBreakPointDir
      slashChecker("breakPointDir",breakPointDir)

      tmpDir = @orcReadConf.getTmpDir
      slashChecker("tmpDir",tmpDir)
      
      puts
   end #end of checkMiscelanea
   #-------------------------------------------------------------

   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "ORC_CheckerOrchestratorConfig debug mode is on"
   end
   #-------------------------------------------------------------

private

   def getListOfTriggerCoverages
      return ["SAME","CONT","GMAT_RULE", "NRT"]
   end

   def getListOfDepCoverages
      return ["SAME","ALL","INTERSECT", "NEWEST", "OLDEST", "LAST", "PAST_IN", "PREV"]
   end
   #-------------------------------------------------------------

   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   #-------------------------------------------------------------

end # class

end # module
