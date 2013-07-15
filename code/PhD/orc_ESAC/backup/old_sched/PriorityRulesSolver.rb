#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #PriorityRulesSolver class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS => ORC Component
# 
# CVS: $Id: PriorityRulesSolver.rb,v 1.3 2009/02/16 12:16:20 decdev Exp $
#
# module ORC
#
#########################################################################

require 'cuc/DirUtils'
require 'cuc/Log4rLoggerFactory'
require 'cuc/EE_ReadFileName'
require 'cuc/EE_DateConverter'

require 'orc/ReadOrchestratorConfig'
require 'orc/ORC_DataModel'



module ORC


class PriorityRulesSolver
   
   include CUC::DirUtils
   include CUC::EE_DateConverter

   #-------------------------------------------------------------
  
   # Class constructor

   def initialize
      @isDebugMode   = false
      @isConfigured  = false
      @isResolved    = false

      checkModuleIntegrity

      @ftReadConf = ORC::ReadOrchestratorConfig.instance
      if @isDebugMode == true then
         @ftReadConf.setDebugMode
      end

      @rules = @ftReadConf.getPriorityRules
   end
   #-------------------------------------------------------------

   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "PriorityRulesSolver debug mode is on"
   end
   #-------------------------------------------------------------

   #-------------------------------------------------------------
   
   # Main method of this class that performs the dependencies
   # checker
   def getNextTrigger
      sortQueue

      if @isDebugMode == true then
         puts "Next Job =>"
         if @nextTrigger != nil then
            puts @nextTrigger.filename
         end
         puts
      end
      return @nextTrigger
   end
   #-------------------------------------------------------------

   def showQueue
      sortQueue
      @arrArrCandidates.each{|arrFiles|
         puts "------------------------"
         arrFiles.each{|aTrigger|
            puts aTrigger.filename
         }
      }
   end
   #-------------------------------------------------------------
   
   def getNextResolved
      sortQueue
   
      @arrArrCandidates.each{|arrFiles|
         if @isDebugMode == true then
            puts "------------------------"
         end
         arrFiles.each{|aTrigger|
#             if @isDebugMode == true then
#                puts aTrigger.filename
#             end
            if areDependenciesSolved?(aTrigger.filename) == true then
               return aTrigger
            end
         }
      }
      return nil
   end

   #-------------------------------------------------------------

private
  
   #-------------------------------------------------------------
   # Check that everything needed by the class is present.
   
   def checkModuleIntegrity
   
      if !ENV['ORC_BASE'] then
         puts "ORC_BASE environment variable not defined !  :-(\n"
         bCheckOK = false
         bDefined = false
      end

      if !ENV['ORC_TMP'] then
         puts "ORC_TMP environment variable not defined !  :-(\n"
         bCheckOK = false
         bDefined = false
      else
         @orcTmpDir = ENV['ORC_TMP']
         checkDirectory("#{@orcTmpDir}/_ingestionError")
      end

      if bCheckOK == false or bDefined == false then
         puts "OrchestratorIngester::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end

   end
   #-------------------------------------------------------------

   def getQueuedFiles
      
      listFiles = OrchestratorQueue::getQueuedFiles
      
      if @isDebugMode == true then
         puts
         print "QUEUE_DATE------FILENAME-------------------------------------------------------STATUS", "\n"     

         listFiles.each{|triggerFile|
            print triggerFile.detection_date.strftime("%Y%m%dT%H%M%S "), 
                          triggerFile.filename.slice(0..59).ljust(63), triggerFile.initial_status.ljust(6), "\n"
         }
      end
      
      return listFiles
    
   end
   #-------------------------------------------------------------
   
   # Sort Queued Files
   def sortQueue
   
      @arrArrCandidates = Array.new
   
      currentRule   = nil
      @nextTrigger  = nil
      @queuedFiles  = getQueuedFiles
        
      if @queuedFiles.empty? == true then
         return
      end
   
      # --------------------------------
      # For each File-Type Rule
      
      @rules.each{|aRule|
      
         arrCandidates = Array.new
         currentRule   = aRule
         
         if @isDebugMode == true then
            print "Rule[", aRule.rank, "] - ", aRule.fileType, " - ", aRule.sort, "\n"
         end
      
         @queuedFiles.each{|queuedFile|
            if queuedFile.filetype == aRule.fileType then
               arrCandidates << queuedFile
            end
         }
      
         # Sort the file-types for such rule
         if arrCandidates.length > 0 then
            if aRule.sort != nil and aRule.sort != "" and aRule.sort != " " then
               arrCandidates = arrCandidates.sort
            end            
            if aRule.sort.to_s.upcase == "DESC" then
               arrCandidates = arrCandidates.reverse
            end
            @arrArrCandidates << arrCandidates  
         end
      }
      # --------------------------------
   
   end

   #-------------------------------------------------------------

   #-------------------------------------------------------------
   
   def areDependenciesSolved?(triggerFile)
      cmd = "createJobOrderFile.rb -f #{triggerFile}"
      if @isDebugMode == true then
         puts
         puts "============================================================="
         cmd = "#{cmd} -D"
         puts cmd
      end
      
      arrResult = `#{cmd}`
      
      if @isDebugMode == true then
         puts arrResult
      end
      
      if $? != 0 then
         return false
      else
         return true
      end
   end
   #-------------------------------------------------------------

end #end class

end #module
