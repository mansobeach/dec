#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #OrchestratorScheduler class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS => ORC Component
# 
# CVS: $Id: OrchestratorScheduler.rb,v 1.2 2008/12/16 11:45: decdev Exp $
#
# module ORC
#
#########################################################################

require 'orc/ReadOrchestratorConfig'
require 'orc/ORC_DataModel'
require 'orc/PriorityRulesSolver'
require 'orc/DependenciesSolver'

require 'cuc/Log4rLoggerFactory'
require 'cuc/EE_ReadFileName'

require 'minarc/FileRetriever'



module ORC


class OrchestratorScheduler

   #-------------------------------------------------------------
  
   # Class constructor

   def initialize(log, debug)
      checkModuleIntegrity
      @logger           = log
      @orcTmpDir        = ENV['ORC_TMP']
      @isDebugMode      = debug
      @arrQueuedFiles   = Array.new
      @arrPendingFiles  = Array.new
      @sleepSigUsr2 = false
      @sleepSigUsr1 = false
      @ftReadConf = ORC::ReadOrchestratorConfig.instance
      @@ss =0
   end
   #-------------------------------------------------------------

   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   #-------------------------------------------------------------   

   def init
      @arrQueuedFiles = OrchestratorQueue.getQueuedFiles           
   end
   #-------------------------------------------------------------   

   def start      
      @arrPendingFiles = Pending2QueueFile.getPendingFiles     
 
      @logger.debug("Loading Queue List")      
     
      #store on Orchestrator_Queue (sql) the new files obtained from the Pending2QueueFiles (ingester Queue)
      @arrPendingFiles.each{ |pf|
         decoder  = CUC::EE_ReadFileName.new(pf.filename)
         fileType = decoder.getFileType
         startVal = decoder.getStrDateStart
         stopVal  = decoder.getStrDateStop

         # If stop-date is EOM set a valid date
         if stopVal == "99999999T999999" then
            stopVal = "99991231T235959"
         end
       
         coverMode = @ftReadConf.getTriggerCoverageByInputDataType(@ftReadConf.getDataType(fileType))
         if coverMode == "NRT" then                        
            cmd = "queueOrcProduct.rb -f #{pf.filename} -a #{startVal} -b #{stopVal} -s NRT"
         else
            cmd = "queueOrcProduct.rb -f #{pf.filename} -a #{startVal} -b #{stopVal}"
         end
         if @isDebugMode == true then
            puts cmd
         end
         system(cmd)
      }

      # Merge the 2 lists into one     
      init
exit
      # Deleting files in the ingestor queue (in sql)
      Pending2QueueFile.delete_all

      schedule 
   end
   #-------------------------------------------------------------


   # This method will implement Processing Rule Priorities.
   # It will sort @arrQueuedFiles object to trigger pending jobs
   # sorted by priority
   def sortPendingJobs
      @logger.debug("Sorting Pending jobs")
      resolver = ORC::PriorityRulesSolver.new
      @arrQueuedFiles = resolver.getSortedQueue
      i = 1
      @arrQueuedFiles.each{|queuedFile|
         @logger.debug("[#{i}] - #{queuedFile.id}   #{queuedFile.filename}")
         i = i + 1
      }
      return
   end
   #-------------------------------------------------------------


   # This method manage the outputs of a trigger that has been
   # processed correctly.
   def success
      # store new file on minarc and check if its a trigger      
      d = Dir.chdir("#{@procWorkingDir}/#{@selectedQueuedFile.id}/outputs")

      d=Dir["*"]
      d.each{|polledFile|

         #store on minarc

         cmd ="minArcStore.rb -f #{@procWorkingDir}/#{@selectedQueuedFile.id}/outputs/#{polledFile}"
         @logger.debug(cmd)
         retVal = system(cmd)
         if retVal == true then
            @logger.debug("store on minarc succesful")
         end

         #store on success folder         
         cmd = "cp #{@procWorkingDir}/#{@selectedQueuedFile.id}/outputs/#{polledFile} #{@successDir}"
         @logger.debug(cmd)
         retVal = system(cmd)
         if retVal == true then
            @logger.debug("store on success folder succesful")
         end
   
         #store on trigger_products if its a trigger
         decoder  = CUC::EE_ReadFileName.new(polledFile)            
         fileType = decoder.getFileType
         if @ftReadConf.isFileTypeTrigger?(fileType) then
            startVal = decoder.getStrDateStart
            stopVal  = decoder.getStrDateStop

            # If stop-date is EOM set a valid date
            if stopVal == "99999999T999999" then
               stopVal = "99991231T235959"
            end
        
         coverMode = @ftReadConf.getTriggerCoverageByInputDataType(@ftReadConf.getDataType(fileType))  
         if coverMode == "NRT" then                        
            cmd = "queueOrcProduct.rb -f #{pf.filename} -a #{startVal} -b #{stopVal} -s NRT"
         else
            cmd = "queueOrcProduct.rb -f #{pf.filename} -a #{startVal} -b #{stopVal}"
         end
            if @isDebugMode == true then
               puts cmd
            end
            system(cmd)
   
         end #if trigger   
      }
      
      #register the production
      cmd = "registerProduction.rb -f #{@selectedQueuedFile.filename}"
      retVal = system(cmd)
      if retVal == true then
         @logger.debug("register production succesful")
      end

      
      depSolver = DependenciesSolver.init(@selectedQueuedFile)      
      nrtType = depSolver.getNRTType
      @selectedQueuedFile.update_attributes(:runtime_status => nrtType)

      # Update the trigger product that created the outputs
      cmd= "updateOrcProduct.rb -f #{@selectedQueuedFile.filename} -s SUC"
      @logger.debug(cmd)
      retVal = system(cmd)
      if retVal == true then
         @logger.debug("UPDATE SUCCESFUL -- stat-> Succesful")
      end
   
      # Remove from code queue
      @arrQueuedFiles.delete(@selectedQueuedFile)

   end
   #-------------------------------------------------------------
     
   # This method manage a trigger that has been processed wrong.
   def failure      
      
      # There was a problem processing the trigger product
      cmd= "updateOrcProduct.rb -f #{@selectedQueuedFile.filename} -s FAI"
      @logger.debug(cmd)
      retVal = system(cmd)
      if retVal == true then
         @logger.debug("UPDATE SUCCESFUL - stat->Failure")
      end
# 
#      #store on failure folder
#      cmd = "cp #{@procWorkingDir}/#{@selectedQueuedFile.id}/outputs/#{polledFile} #{@failureDir}"
#      @logger.debug(cmd)
#      retVal = system(cmd)
#      if retVal == true then
#         @logger.debug("store on failure folder succesful")
#      end
   
       # Remove from code queue
       @arrQueuedFiles.delete(@selectedQueuedFile)
   end
   #-------------------------------------------------------------

   # Method that decides if the process as been successful or
   # as been wrong; calling success or failure respectively
   def status
      prevDir = Dir.pwd
      Dir.chdir(ENV['NRTP_HMI_TMP'])
      if File.exist?("NRTP_STATUS_SUCCESS") == true then
         @logger.debug("NRTP Execution was successfull !")
         File.delete("NRTP_STATUS_SUCCESS")
         success
      end

      if File.exist?("NRTP_STATUS_FAILED") == true then
         @logger.debug("NRTP Execution FAILED !")         
         File.delete("NRTP_STATUS_FAILED")
         failure
      end
                     
      if File.exist?("NRTP_STATUS_ACK") == true then
         @logger.debug("Message Acknowledge, keep on waiting !")
         File.delete("NRTP_STATUS_ACK")
         sleep
      end
      Dir.chdir(prevDir)
   end
   #-------------------------------------------------------------


   def signalHandler(usr)
      if (@sleepSigUsr2 == true and usr == "usr2") then
         @logger.debug("Scheduler called from the processor, resolve status")
         status
      else 
         if (@sleepSigUsr2 == true and usr == "usr1") then 
            @logger.debug("ingestor called (SIGUSR1), tho we are waiting for the processor to end (@sleepSigUsr2)")
            @sig1flag = true           
            sleep
         else
            if (@sleepSigUsr2 == false and usr == "usr1") then
               @logger.debug("Scheduler called from the ingestor, keep scheduling")
               # implicit call to start by the listener
            else #an unknown signal called when we are waiting another signal               
               sleep
            end
         end
      end     
   end
   #-------------------------------------------------------------


   def triggerJob(selectedQueuedFile)
      @logger.debug("Triggering Job => #{selectedQueuedFile.filename}")
     
      #get JobOrder name
      prevDir = Dir.pwd    
      begin 
         Dir.chdir("#{@procWorkingDir}/#{selectedQueuedFile.id}/control") do
            d=Dir["*"]
            d.each{ |x|
            @xmlFileName = x
           }
         end     #end do 
      rescue SystemCallError
        @logger.error("Could not get the jobOrder file name  !")
      end    
      Dir.chdir(prevDir)

      cmd = "createProcessingScenario.rb -f #{@procWorkingDir}/#{selectedQueuedFile.id}/control/#{@xmlFileName}"
      @logger.debug("\n#{cmd}") 
      retVal = system(cmd)

      if retVal == true then
         # create outputs
         dataType = @ftReadConf.getDataType(selectedQueuedFile.filetype) 
         execute = @ftReadConf.getExecutable(dataType)
         execute = execute.gsub("%j", "-j #{@procWorkingDir}/#{selectedQueuedFile.id}/control/#{@xmlFileName}")
         checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)
         pid     = checker.getRunningPID
         execute = execute.gsub("%P", "-P #{pid}")
         @logger.debug(execute)      
         system(execute)
      
         @sleepSigUsr2 = true
            sleep #for SIGUSR2 who will call status.
         @sleepSigUsr2 = false  
      end    

   end
   #-------------------------------------------------------------

   def schedule
      @@ss = @@ss + 1
      @logger.debug("[#{@@ss}]Orchestrator Scheduling jobs")        
      @procWorkingdir = ""
      inputsDir = ""

      # Scheduler sorting algorithm
      sortPendingJobs
      
      # Get  Orchestrator Configuration Dirs
      @procWorkingDir   = @ftReadConf.getProcWorkingDir  
      @successDir       = @ftReadConf.getSuccessDir
      @failureDir       = @ftReadConf.getFailureDir   

      @selectedQueuedFile = nil

      # For each trigger in the queue, see whether its 
      # dependencies are resolved, and if they are
      # Trigger the Job 
      @arrQueuedFiles.each{|queuedFile|                         
         cmd ="createJobOrderFile.rb -f #{queuedFile.filename} -i #{queuedFile.id} -L #{@procWorkingDir}"
         @logger.debug("\n#{cmd}")
         retVal = system(cmd)

         if retVal == true then
            @selectedQueuedFile = queuedFile
            break    
         end
      }
      # Trigger Job
      if @selectedQueuedFile != nil then
         triggerJob(@selectedQueuedFile)
         start
      else
         @logger.debug("sleeping: No more trigger jobs can be executed")
  
#         if @sig1flag == true then
#            @sig1flag = false               
#            start
#         end

      end         

      @logger.debug("[#{@@ss}]fin de schedule")                          
      @@ss = @@ss - 1
   end
   #-------------------------------------------------------------


private

	#-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
   
      if !ENV['ORC_TMP'] then
         puts "ORC_TMP environment variable not defined !  :-(\n"
         bCheckOK = false
         bDefined = false
      end

      if bCheckOK == false then
         puts "OrchestratorScheduler::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end

   end
   #-------------------------------------------------------------

   # This method loads from database queued files
   def getQueuedFiles
      # Gather from database queued files
      return OrchestratorQueue.getQueuedFiles
   end
   #-------------------------------------------------------------

   def getFilesToBeQueued
      # Gather from database files to be queued
      return Pending2QueueFile.getPendingFiles
   end
   #-------------------------------------------------------------

end # class

end # module
