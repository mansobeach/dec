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

require 'cuc/Log4rLoggerFactory'
require 'cuc/EE_ReadFileName'

require 'minarc/FileRetriever'

require 'orc/ReadOrchestratorConfig'
require 'orc/ORC_DataModel'
require 'orc/PriorityRulesSolver'
require 'orc/DependenciesSolver'


module ORC


class OrchestratorScheduler

   #-------------------------------------------------------------
  
   # Class constructor

   def initialize(log, debug)
      checkModuleIntegrity
      
      # Register Signals Handlers
      registerSignals
      
      @logger           = log
      @orcTmpDir        = ENV['ORC_TMP']
      @isDebugMode      = debug
      @arrQueuedFiles   = Array.new
      @arrPendingFiles  = Array.new
      @sleepSigUsr2     = false
      @sig1flag         = false
      @ftReadConf       = ORC::ReadOrchestratorConfig.instance
      
      # Get Orchestrator Configuration Dirs
      @procWorkingDir   = @ftReadConf.getProcWorkingDir  
      @successDir       = @ftReadConf.getSuccessDir
      @failureDir       = @ftReadConf.getFailureDir   
      
      @@ss              = 0
   end
   #-------------------------------------------------------------

   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   #-------------------------------------------------------------   

   # Get all Queued Files
   def loadQueue
      @arrQueuedFiles = OrchestratorQueue.getQueuedFiles           
   end
   #-------------------------------------------------------------   

   # Main method of this class:
   # - Get all Pending2Queue Files
   # - 
   def schedule   
     
      # Get Pending files pre-queued by the ingesterComponent.rb
      # They are referenced in PENDING2QUEUEFILE table
      @arrPendingFiles = Pending2QueueFile.getPendingFiles     
 
      @logger.debug("Loading Queue List")      

      @arrPendingFiles.each{|fileToQueue|
         @logger.debug("Queueing #{fileToQueue.filename}") 
      }
      
      # Queue in Orchestrator_Queue new files referenced 
      # in Pending2QueueFiles (ingester Queue)
      
      @arrPendingFiles.each{ |pf|
         decoder  = CUC::EE_ReadFileName.new(pf.filename)
         fileType = decoder.getFileType
         startVal = decoder.getStrDateStart
         stopVal  = decoder.getStrDateStop

         # If stop-date is EOM set a valid date
         if stopVal == "99999999T999999" then
            stopVal = "99991231T235959"
         end
       
         # Extract trigger-type coverage mode
         coverMode = @ftReadConf.getTriggerCoverageByInputDataType(@ftReadConf.getDataType(fileType))
         
         # In case coverage is NOT NRT, trigger product is marked UKN
         
         # In case it is coverage mode NRT, it is required to evaluate its classification.
         # This is whether it is:
         # OLD  => OLD     products
         # MIX  => MIXED   products
         # NRT  => NRT     products
         # FUT  => FUTURE  products
         
         if coverMode == "NRT" then
            depSolver = DependenciesSolver.new(pf.filename)
            depSolver.init    
            nrtType   = depSolver.getNRTType
            cmd = "queueOrcProduct.rb -f #{pf.filename} -s #{nrtType}"
            cmd = "queueOrcProduct.rb -f #{pf.filename} -s NRT"
         else
            cmd = "queueOrcProduct.rb -f #{pf.filename} -s UKN"
         end
         
         @logger.debug("\n#{cmd}")
         
         if @isDebugMode == true then
            puts cmd
         end
         
         ret = system(cmd)
         
         if ret == false then
            @logger.warn("Could not queue #{pf.filename}")
         end
      }

      # After registering all new trigger products
      # the processing queue is loaded
      loadQueue

      # Delete all files in the ingestor queue
      Pending2QueueFile.delete_all

      # Method that trigger the new job
      dispatch 
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


   #-------------------------------------------------------------
   
   # Class method that triggers the Processor Execution 
   def triggerJob(selectedQueuedFile)
      @logger.debug("*** Triggering Job => #{selectedQueuedFile.filename} ***")
      
      procWdControl = "#{@procWorkingDir}/#{selectedQueuedFile.id}/control"
      
      # --------------------------------
      # Retrieve the JobOrder filename
      prevDir = Dir.pwd    
      begin
         Dir.chdir(procWdControl) do
            d = Dir["SM*MPL_JOBORD*"]
            d.each{ |x|
               @jobOrderFile = x
            }
         end
      rescue SystemCallError
         @logger.warn("Could not get job #{selectedQueuedFile.id} Order file !")
      end    
      Dir.chdir(prevDir)
      # --------------------------------

      # Gather processing Inputs      

      cmd = "createProcessingScenario.rb -f #{procWdControl}/#{@jobOrderFile}"
      @logger.debug("\n#{cmd}") 
      retVal = system(cmd)

      if retVal == false then
         @logger.warn("Could not get job #{selectedQueuedFile.id} inputs")
         updateTriggerStatus(selectedQueuedFile.filename, "FAI")
         return false
      end

      # --------------------------------

      # Get configuration executable name      
      myPid    = Process.pid
      dataType = @ftReadConf.getDataType(selectedQueuedFile.filetype) 
      procCmd  = @ftReadConf.getExecutable(dataType)
      procCmd  = procCmd.gsub("%j", "-j #{procWdControl}/#{@jobOrderFile}")
      procCmd  = procCmd.gsub("%P", "-P #{myPid}")
      @logger.debug("\n#{procCmd}")
      
      # --------------------------------
      # TRIGGER PROCESSOR !!  :-)
      system(procCmd)
      # --------------------------------
      
      # Flag to manage only Processor SIGUSR2 signals
      # and skip Ingester SIGUSR1 ones
      @sleepSigUsr2 = true
      
      # Wait for Processor information
      sleep
   end
   #-------------------------------------------------------------

   # Method in charge of dispatching new jobs
   def dispatch
      @logger.debug("Dispatching new job(s)")
      @@ss = @@ss + 1
      # @logger.debug("[#{@@ss}]Orchestrator Scheduling jobs")        
      @procWorkingdir = ""
      inputsDir = ""

      # Scheduler sorting algorithm
      sortPendingJobs
      
      @selectedQueuedFile = nil

      # For each trigger in the queue, see whether its 
      # dependencies are resolved, and if they are
      # Trigger the Job 
      @arrQueuedFiles.each{|queuedFile|                         
         cmd = "createJobOrderFile.rb -f #{queuedFile.filename} -i #{queuedFile.id} -L #{@procWorkingDir}"
         puts
         puts cmd
         @logger.debug("\n#{cmd}")
         begin
            retVal = system(cmd)

            if retVal == true then
               @selectedQueuedFile = queuedFile
               @logger.debug("#{queuedFile.filename} solved its dependencies :-)")
               break
            else
               @logger.debug("#{queuedFile.filename} not solved its dependencies :-|")
            end
         rescue Exception => e
            @logger.error("Error when triggering createJobOrderFile.rb")
            @logger.error("Execute in the console:")
            @logger.error("\n#{cmd} -D")
         end
      }
      
      # --------------------------------
      # Trigger Job
      if @selectedQueuedFile != nil then
         triggerJob(@selectedQueuedFile)
         schedule
      else
         @logger.debug("No more pending jobs can be executed")
  
         # If there is pending notification from the Ingester
         # invoke the scheduler
         if @sig1flag == true then
            @sig1flag = false               
            schedule
         end
      end         
      # --------------------------------
               
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

      if !ENV['NRTP_HMI_TMP'] then
         puts "NRTP_HMI_TMP environment variable not defined !  :-(\n"
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

   # Update the trigger product with passed status
   
   def updateTriggerStatus(filename, status)
      cmd = "updateOrcProduct.rb -f #{filename} -s #{status}"
      @logger.debug("\n#{cmd}")
      retVal = system(cmd)
      if retVal == true then
         @logger.debug("#{filename} set to #{status}")
      end
   end
   #-------------------------------------------------------------

   # This method checks whether a new generated file by a Processor
   # is a Trigger file and there it must be queued
   def handleNewProducedFile(aFile)     
      decoder = CUC::EE_ReadFileName.new(aFile)            
         
      fileType = decoder.getFileType
         
      if @ftReadConf.isFileTypeTrigger?(fileType) == true then
         coverMode = @ftReadConf.getTriggerCoverageByInputDataType(@ftReadConf.getDataType(fileType))
         # If Cover is equal to NRT
         # It  must be calculated with DependenciesSolver whether it is
         # OLD | MIXED | NRT | FUTURE
         # TO BE DONE !!!!
         if coverMode == "NRT" then                        
            cmd = "queueOrcProduct.rb -f #{aFile} -s NRT"
         else
            cmd = "queueOrcProduct.rb -f #{aFile} -s UKN"
         end
            
         if @isDebugMode == true then
            puts cmd
         end
         @logger.debug("\n#{cmd}")
         retVal = system(cmd)
         if retVal == false then
            @logger.warn("Could not Queue #{aFile}")
         end
      else
         @logger.debug("New file #{aFile} is not trigger")
      end
   end
   #-------------------------------------------------------------

   # This method manages Processor outputs accordingly to the status
   # If success it archives all outputs and job-order from control
   # directory
   def manageProcOutputs(jobId)
      prevDir = Dir.pwd
      
      controlDir = "#{@procWorkingDir}/#{jobId}/control"
      outputsDir = "#{@procWorkingDir}/#{jobId}/outputs"
      workingDir = "#{@procWorkingDir}/#{jobId}"
      
      # --------------------------------
      # Store content of the Control directory.
      # This is mainly the job-order file
      
      Dir.chdir(controlDir)
      
      arrFiles = Dir["*"]
      
      arrFiles.each{|aFile|
         cmd    = "minArcStore.rb -m -f #{controlDir}/#{aFile}"
         @logger.debug("\n#{cmd}")
         retVal = system(cmd)
         
         if retVal == false then
            @logger.warn("Could not archive #{aFile}")
         end
      }
      
      # --------------------------------
      
      # --------------------------------
      # Store content of the Outputs directory.
      # This is the result of the Processor succesful execution
      # Such files are placed as well in the "Success" folder
      
      Dir.chdir(outputsDir)

      arrFiles = Dir["*"]
      
      arrFiles.each{|aFile|
      
         # Archive output file
         cmd    = "minArcStore.rb -m -f #{outputsDir}/#{aFile}"
         @logger.debug("\n#{cmd}")
         retVal = system(cmd)
         
         if retVal == false then
            @logger.warn("Could not archive #{aFile}")
            next
         end
         
         # Queue new File if Trigger
         handleNewProducedFile(aFile)
         
         # Place just Archived file in Success folder
         cmd = "minArcRetrieve.rb -H -f #{aFile} -L #{@successDir}"
         @logger.debug("\n#{cmd}")
         retVal = system(cmd)
         
         if retVal == false then
            @logger.warn("Could not retrieve #{aFile} from MINARC")
            next
         end
         
         # Register generated Production
         cmd = "registerProduction.rb -f #{aFile}"
         @logger.debug("\n#{cmd}")
         retVal = system(cmd)
         if retVal == false then
            @logger.warn("Could not register production for #{aFile}")
         end
         
      }      
      # --------------------------------
      
      # Back to previous directory
      Dir.chdir(prevDir)
      
      # Clean-up Processing Working Directory
      cmd = "\\rm -rf #{workingDir}"
      @logger.debug("Removing #{workingDir} directory")
      ret = system(cmd)
      
      if ret == false then
         @logger.debug("\n#{cmd}")
         @logger.warn("Could not remove #{workingDir} directory")
      end
      # --------------------------------
      
      
   end
   #-------------------------------------------------------------

   # This method is dummy
   def updateProcStatus(jobId, status)
   
      # This external command shall be substituted with own
      # ruby ORC_Datamodel code to save time
      cmd = "retrieveJobOrderId.rb -j #{jobId}"
      puts cmd
      @logger.debug("\n#{cmd}")
      
      triggerFile = nil
      
      IO.popen(cmd, "w+") {|pipe| triggerFile = pipe.gets}
      
      triggerFile = triggerFile.chop
      
      updateTriggerStatus(triggerFile, status)        
   end
   #-------------------------------------------------------------

   # This method manages processor
   # It must identify Job-Order-Id file
   # plus Status file and according to the status file
   # manage processor results
   def manageProcesor
      prevDir = Dir.pwd
      Dir.chdir(ENV['NRTP_HMI_TMP'])
      
      # Get Job Order Id of the processor
      
      jobFile = Dir["NRTP_JOBORDER*"]
      jobId   = -1
                     
      if jobFile.length > 0 then
         jobFile = jobFile[0]
         jobId = jobFile.slice(14, jobFile.length - 1).to_i
      else
         jobId = 0
      end

      File.delete(jobFile)

      # --------------------------------
      # Manage Processor successful execution
      
      if File.exist?("NRTP_STATUS_SUCCESS") == true then
         File.delete("NRTP_STATUS_SUCCESS")
         
         @logger.debug("Job #{jobId} Execution was SUCCESSFUL")
   
         # Update Trigger status with SUCCESS
         updateProcStatus(jobId, "SUC")
   
         # Manage Processor outputs
         manageProcOutputs(jobId)
         
         # We do not expect new SIGUSR2
         # signals for this processor
         @sleepSigUsr2 = false
      end
      # --------------------------------
      
      # --------------------------------
      # Manage Processor successful execution
      
      if File.exist?("NRTP_STATUS_FAILED") == true then
         File.delete("NRTP_STATUS_FAILED")
         @logger.debug("Job #{jobId} Execution FAILED")         
         
         # Update Trigger status with FAILURE
         updateProcStatus(jobId, "FAI")
         
         # We do not expect new SIGUSR2
         # signals for this processor
         @sleepSigUsr2 = false         
      end
      # --------------------------------
                     
      # --------------------------------
      # Manage Processor message Acknowledge
      if File.exist?("NRTP_STATUS_ACK") == true then
         File.delete("NRTP_STATUS_ACK")
         @logger.debug("Job #{jobId} message Acknowledge, keep on waiting")
         # Keep on sleeping and with
         # SIGUSR1 from ingester "masked"
         @sleepSigUsr2 = true
         sleep
      end
      # --------------------------------
      
      Dir.chdir(prevDir)
   end
   #-------------------------------------------------------------

   def registerSignals
      trap("SIGUSR1") {                          
                        signalHandler("usr1")               
                      }     

      trap("SIGUSR2") { 
                        signalHandler("usr2")
                      }                                         
                       
      trap("SIGHUP")  {                          
                        @logger.info("Restarting schedulerComponent")
                   #     self.restart  
                      }
   end
   #-------------------------------------------------------------

   # Method that manages Orchestrator Scheduler managed Signals:
   # - SIGUSR1: is received from Ingester to acknowledge new files
   # - SIGUSR2: is received from Scheduler to manage Processor executions
   #
   # In case there is a Processor running, SIGUSR1 signals are "ignored"
   # because scheduler will look for new files after Processor execution.

   def signalHandler(usr)
      bHandled = false
      
      # --------------------------------
      # Processor Signal Status management
      if (usr == "usr2") then
         bHandled = true
         @logger.debug("Scheduler received SIGUSR2 from Processor")
         @sleepSigUsr2 = true
         manageProcesor
      end
      # --------------------------------
      
      # --------------------------------
      # Ingester Signal Status management      
      if (usr == "usr1") then
         bHandled = true
         @logger.debug("Scheduler received SIGUSR1 from Ingester")
         if @sleepSigUsr2 == true then
            @sig1flag = true
            @logger.debug("Scheduler is managing a Processors")
            sleep
         else
            @sig1flag = false
            schedule
         end
      end
      # --------------------------------
     
      # --------------------------------
      # Unhandled Signal
      if bHandled == false then
         @logger.warn("Signal #{usr} not managed")
      end
      # --------------------------------
   end
   #-------------------------------------------------------------


end # class

end # module
