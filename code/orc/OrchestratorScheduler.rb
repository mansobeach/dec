#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #OrchestratorScheduler class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Orchestrator => ORC Component
# 
# CVS: $Id: OrchestratorScheduler.rb,v 1.9 2009/04/30 11:58:52 decdev Exp $
#
# module ORC
#
#########################################################################

require 'cuc/Log4rLoggerFactory'

require 'orc/ReadOrchestratorConfig'
require 'orc/ORC_DataModel'
require 'orc/PriorityRulesSolver'
#require 'orc/DependenciesSolver'


module ORC


class OrchestratorScheduler

   #-------------------------------------------------------------
  
   # Class constructor

   def initialize(log, debug)

      checkModuleIntegrity
      
      
      @logger           = log
      
      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("Orchestrator", "#{ENV['ORC_CONFIG']}/orchestrator_log_config.xml")
   
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      
      @logger = loggerFactory.getLogger   
      if @logger == nil then
         puts
		   puts "Error in OrchestratorIngester::initialize"
     	   puts "Could not initialize logging system !  :-("
         puts "Check ORC logs configuration under \"#{@orcConfigDir}/orchestrator_log_config.xml\"" 
 	      puts
   	   exit(99)
      end
      
      
      
      
      @orcTmpDir        = ENV['ORC_TMP']
      @isDebugMode      = debug
      @arrQueuedFiles   = Array.new
      @arrPendingFiles  = Array.new
      @sleepSigUsr2     = false
      @sig1flag         = false
      @bJobJustTriggered= false
      @bProcRunning     = false

      @ftReadConf       = ORC::ReadOrchestratorConfig.instance

      # Get Orchestrator Configuration Dirs
      @procWorkingDir   = @ftReadConf.getProcWorkingDir  
      @successDir       = @ftReadConf.getSuccessDir
      @failureDir       = @ftReadConf.getFailureDir   
      @freqScheduling   = @ftReadConf.getSchedulingFreq.to_f
      @resourceManager  = @ftReadConf.getResourceManager
      
      @bExit            = false      

      @@ss              = 0
      
      # Register Signals Handlers
      registerSignals

      
   end
   #-------------------------------------------------------------

   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "OrchestratorScheduler debug mode is on"
   end
   #-------------------------------------------------------------   

   # Get all Queued Files
   def loadQueue
      msg = "OrchestratorScheduler::loadQueue"
      # puts msg
      @logger.debug(msg) 
      @arrQueuedFiles = OrchestratorQueue.getQueuedFiles 
#      if @isDebugMode == true then
#         puts "--------------------"
#         puts "queue:"
#         @arrQueuedFiles.each{|item|
#            puts item.filename
#         }
#         puts "---------------------"
#      end         
   end
   #-------------------------------------------------------------   

   # This method gets all files referenced in Pending2QueueFile
   # table and adds them to Orchestrator_Queue table
   def enqueuePendingFiles

      msg = "OrchestratorScheduler::enqueuePendingFiles"
      # puts msg
      @logger.debug(msg) 

      @arrPendingFiles = Pending2QueueFile.getPendingFiles     

      if @arrPendingFiles.empty? == true then
         msg = "No new input files are pending to be queued"
         # puts msg
         @logger.debug(msg)
         return
      end
      
      # Queue in Orchestrator_Queue new files referenced 
      # in Pending2QueueFiles (ingester Queue)
      
      # Ignore additional SIGUSR1 from Ingester
      Signal.trap("SIGUSR1", "IGNORE")

      
      @arrPendingFiles.each{ |pf|

         cmd = "orcQueueInput -f #{pf.filename} -s UKN"          
         @logger.debug("#{cmd}")
                  
         ret = system(cmd)
         
         if ret == false then
            @logger.error("Could not queue #{pf.filename}")
         end

         Pending2QueueFile.where(filename: pf.filename).destroy_all
      }
      
      
      # Register Signals Handlers
      registerSignals


   end
   #-------------------------------------------------------------

   # Main method of this class:
   # - Get all Pending2Queue Files
   # - 
   def schedule

      @bScheduling = false

      msg = "Orchestrator::schedule new inputs"
      # puts msg
      @logger.debug(msg)

      # Verify Database connection
      # ActiveRecord::Base.verify_active_connections!

      # @logger.debug("Loading Queue List")
      
      # Get Pending files pre-queued by the ingesterComponent.rb
      # They are referenced in PENDING2QUEUEFILE table

      enqueuePendingFiles

      # After registering all new trigger products
      # the processing queue is loaded
      loadQueue

      # Method that trigger the new job
      dispatch

      if @arrQueuedFiles.empty? then
         sleep(@freqScheduling)
      end


   end
   #-------------------------------------------------------------


   # This method will implement Processing Rule Priorities.
   # It will sort @arrQueuedFiles object to trigger pending jobs
   # sorted by priority
   def sortPendingJobs
      
      msg = "Sorting Pending jobs / PriorityRulesSolver"
      # puts msg
      @logger.debug(msg)
      
      resolver = ORC::PriorityRulesSolver.new
      
      if @isDebugMode == true then
         resolver.setDebugMode
      end
      
      @arrQueuedFiles = Array.new 
      @arrQueuedFiles = resolver.getSortedQueue
       
      i = 1
      
      @arrQueuedFiles.each{|queuedFile|
         @logger.debug("[#{i.to_s.rjust(2)}] - #{queuedFile.id.to_s.rjust(4)}   #{queuedFile.filename}")
         i = i + 1
      }
 
      return
   end
   #-------------------------------------------------------------

   # It removes from execution current job
   def abortCurrentJob
      cmd = "#{@helperExecutable} -c abort"
      @logger.debug("\n#{cmd}")
      system(cmd)
      @logger.debug("Aborting current job #{@currentTrigger.filename}")
      sleep(5)
   end
   # -------------------------------------------------------------
   
   def triggerJobS2(selectedQueuedFile)
      @bJobJustTriggered = true
      
      @logger.debug("*** Triggering Job => #{selectedQueuedFile.filename} ***")
      
      cmd = ""
      if selectedQueuedFile.filename.include?(".TGZ") == true then      
         cmd = "minArcRetrieve --noserver -f #{selectedQueuedFile.filename} -L #{@procWorkingDir} -H"
      else
         cmd = "minArcRetrieve --noserver -f #{selectedQueuedFile.filename} -L #{@procWorkingDir} -H -U"
      end

      if @isDebugMode == true then
         puts cmd
      end

      @logger.debug(cmd)

      ret = system(cmd)

      if ret == false then
         @logger.debug("Failed to retrieve input")
      end
     
      dataType = @ftReadConf.getDataType(selectedQueuedFile.filetype)
      procCmd  = @ftReadConf.getExecutable(dataType)
      procCmd  = procCmd.gsub("%F", "#{@procWorkingDir}/#{selectedQueuedFile.filename}")
      @logger.debug(procCmd)
      
      # --------------------------------
      # TRIGGER PROCESSOR !!  :-)
  
      retVal = system(procCmd)
      
      # fork { exec(cmd) }
      # --------------------------------
   
      # # Update Trigger status with SUCCESS
      # retVal = true

      if retVal == true then
         cmd = "orcQueueUpdate -f #{selectedQueuedFile.filename} -s SUCCESS"
         @logger.debug(cmd)
         retVal = system(cmd)
         if retVal == false then
            @logger.error("Failed exec of #{cmd}")
         end
      else
         cmd = "orcQueueUpdate -f #{selectedQueuedFile.filename} -s FAILURE"
         @logger.debug(cmd)
         system(cmd)      
      end
   
      # sleep(@freqScheduling)
   
   end
   # -------------------------------------------------------------
   
   # Class method that triggers the Processor Execution 
   def triggerJob(selectedQueuedFile)
      @bJobJustTriggered = true
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
         @logger.error("Could not create Job-Order file #{selectedQueuedFile.id}")
         updateTriggerStatus(selectedQueuedFile.filename, "FAI")
         Dir.chdir(prevDir)
         return false
      end
    
      Dir.chdir(prevDir)
      # --------------------------------

      # Gather processing Inputs      

      cmd = "createProcessingScenario.rb -f #{procWdControl}/#{@jobOrderFile} -H"
      @logger.debug("\n#{cmd}") 
      retVal = system(cmd)

      if retVal == false then
         @logger.error("Could not get Job-Order #{selectedQueuedFile.id} inputs")
         updateTriggerStatus(selectedQueuedFile.filename, "FAI")
         return false
      end

      # --------------------------------

      # Get configuration executable name      
      myPid    = Process.pid
      dataType = @ftReadConf.getDataType(selectedQueuedFile.filetype)
      procCmd  = ""
      procCmd  = @ftReadConf.getExecutable(dataType)
      procCmd  = procCmd.gsub("%j", "-j #{procWdControl}/#{@jobOrderFile}")
      procCmd  = procCmd.gsub("%P", "-P #{myPid}")
      @logger.debug("\n#{procCmd}")
      
      # --------------------------------
      # TRIGGER PROCESSOR !!  :-)
  
      system(procCmd)
      
      # fork { exec(cmd) }
      # --------------------------------
      # procCmd  = ""      

      # Flag to manage only Processor SIGUSR2 signals
      # and skip Ingester SIGUSR1 ones
      @helperExecutable    = procCmd.split(" ")[0]
      @currentTrigger      = selectedQueuedFile
      @runProcStatus       = selectedQueuedFile.runtime_status
      @initProcStatus      = selectedQueuedFile.initial_status
      @sleepSigUsr2        = true
      @bJobJustTriggered   = false
      
      # Wait for Processor information
      sleep
   end
   # -------------------------------------------------------------

   # Method in charge of dispatching new jobs
   # Now it shall take into account whether there is a job running
   # and in case it has lower prio than one incoming, 
   # it shall be aborted
   def dispatch
   
      msg = "OrchestratorScheduler::dispatch => Dispatching new job(s)"
      @logger.debug(msg)
      @@ss = @@ss + 1

      @procWorkingdir   = ""
      inputsDir         = ""

      # --------------------------------
      
      # Scheduler sorting algorithm
      sortPendingJobs
      
      # --------------------------------
      # Trigger Job
      
      
      while !@arrQueuedFiles.empty? do

         triggerJobS2(@arrQueuedFiles.shift)

#         if @isDebugMode == true then
#            puts "#queue length: #{@arrQueuedFiles.length}"
#         end

         cmd = "#{@resourceManager}"
         
         retVal = system(cmd)
         
         while (retVal == false) do
            @logger.debug("No resources available / queue length: #{@arrQueuedFiles.length} / sleeping #{@freqScheduling} s")
            sleep(@freqScheduling)
            retVal = system(cmd)
         end
         
      end
         
      @@ss = @@ss - 1
   end
   # -------------------------------------------------------------

   # This method checks whether it is possible to dispatch a new job
   def canDispatchNewTrigger?
      if @bProcRunning == false then
         return true
      else
         # Only OLD processors can be aborted and leave execution
         # for new triggers
         if @initProcStatus.to_s.upcase == "OLD" then
            return true
         else
            return false
         end
      end
   end
   # -------------------------------------------------------------


private

	#-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
   
      if !ENV['ORC_TMP'] then
         puts "ORC_TMP environment variable not defined !  :-(\n"
         bCheckOK = false
         bDefined = false
      end

#      if !ENV['NRTP_HMI_TMP'] then
#         puts "NRTP_HMI_TMP environment variable not defined !  :-(\n"
#         bCheckOK = false
#         bDefined = false
#      end

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
   
   def updateTriggerStatus2(jobId, status)
      cmd = "updateOrcProduct.rb -i #{jobId} -s #{status}"
      puts cmd
      @logger.debug("\n#{cmd}")
      retVal = system(cmd)
      if retVal == false then
         @logger.warn("Could not set Status #{status} to job #{jobId}")
      end
   end
   #-------------------------------------------------------------

   # Update the trigger product with passed status
   
   def updateTriggerStatus(filename, status)
      cmd = "updateOrcProduct.rb -f #{filename} -s #{status}"
      @logger.debug("\n#{cmd}")
      retVal = system(cmd)
      if retVal == false then
         @logger.warn("Could not set Status #{status} to #{filename}")
      end
   end
   #-------------------------------------------------------------


   #-------------------------------------------------------------


   #-------------------------------------------------------------

   # This method changes Job Status
   def updateProcStatus(jobId, status)

      updateTriggerStatus2(jobId, status)
      return
      
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
      
      theJobFile = jobFile[0]
         
      # Currently PhD is only able to manage
      # one job at a time so if this true ... ups !
  
      if jobFile.length > 1 then
         @logger.fatal("Found more than a Job-Oder ID file")
         jobFile.each{|aJob|
            @logger.fatal(aJob)
         }
         exit(99)
      end
          
      if jobFile.length == 1 then
         jobFile = jobFile[0]
         jobId = jobFile.slice(14, jobFile.length - 1).to_i
         @currentJobId = jobId
      else
         jobId = @currentJobId
      end
      
      # @logger.debug("DELETING #{theJobFile}")
      if theJobFile != nil then
         File.delete(theJobFile)
      end

      # Flags to keep current management status
      @bManagingSuccess = false
      @bManagingFailure = false
      @bManagingAck     = false

      # --------------------------------
      # Manage Processor successful execution
      
      if File.exist?("NRTP_STATUS_SUCCESS") == true or @bManagingSuccess == true then
         
         Signal.trap("SIGUSR1", "IGNORE")

         @bProcRunning = false

         if @bManagingSuccess == true then
            @logger.debug("Managing Prev Success for #{jobId}")
         end
         
         @bManagingSuccess = true
         
         if File.exist?("NRTP_STATUS_SUCCESS") == true then
            File.delete("NRTP_STATUS_SUCCESS")
            @logger.debug("Delete NRTP_STATUS_SUCCESS for #{jobId}")
         end

         @logger.info("Job #{jobId} Execution was SUCCESSFUL")
         
         # Update Trigger status with SUCCESS
         updateProcStatus(jobId, "SUC")
   
         # Manage Processor outputs
         manageProcOutputs(jobId)
         
         # We do not expect new SIGUSR2
         # signals for this processor
         @bManagingSuccess = false
         @sleepSigUsr2     = false

         # Restore Signal handler for the Ingester
         registerSignal4Ingester
      end
      # --------------------------------
      
      # --------------------------------
      # Manage Processor successful execution
      
      if File.exist?("NRTP_STATUS_FAILED") == true or @bManagingFailure == true then
                  
         # Ignore Signals from Ingester
         Signal.trap("SIGUSR1", "IGNORE")

         @bProcRunning = false

         if @bManagingFailure == true then
            @logger.debug("Managing Prev Failure for #{jobId}")
         end

         @bManagingFailure = true

         if File.exist?("NRTP_STATUS_FAILED") == true then
            File.delete("NRTP_STATUS_FAILED")
            @logger.debug("Delete NRTP_STATUS_FAILED for #{jobId}")
         end

         @logger.error("Job #{jobId} Execution FAILED")         
         
         # Update Trigger status with FAILURE
         updateProcStatus(jobId, "FAI")
         
         # We do not expect new SIGUSR2
         # signals for this processor
         @bManagingFailure = false
         @sleepSigUsr2     = false

         # Restore Signal handler for the Ingester
         registerSignal4Ingester
      end
      # --------------------------------

      # Manage Processor Aborted
      
      if File.exist?("NRTP_STATUS_ABORTED") == true then
         @bProcRunning = false
         
         if File.exist?("NRTP_STATUS_ABORTED") == true then
            File.delete("NRTP_STATUS_ABORTED")
            @logger.debug("Delete NRTP_STATUS_ABORTED for #{jobId}")
         end
         
         @sleepSigUsr2     = false
         @logger.warn("Job #{jobId} Execution has been ABORTED")
      end
                           
      # --------------------------------
      # Manage Processor message Acknowledge
      if File.exist?("NRTP_STATUS_ACK") == true then
         @bProcRunning = true
         File.delete("NRTP_STATUS_ACK")
         @logger.debug("Job #{jobId} message Acknowledge, keep on waiting")
         # Keep on sleeping and with
         # SIGUSR1 from ingester "masked"
         @sleepSigUsr2 = true
         sleep
      end
      # --------------------------------
      
      # Currently there is a processor running
      
      if @sleepSigUsr2 == true then
      # @sig1flag = true
      
         sleep
      end

      # --------------------------------

      begin
         Dir.chdir(prevDir)
      rescue Exception => e
      end
   end
   #-------------------------------------------------------------

   def registerSignals
      trap("SIGTERM") { 
                        signalHandler("sigterm")
                      }                                         


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

   def registerSignal4Ingester
      trap("SIGUSR1") { signalHandler("usr1") }
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
         # @logger.debug("Scheduler received SIGUSR2 from Processor")
         @sleepSigUsr2 = true
         manageProcesor
      end
      # --------------------------------
      
      # --------------------------------
      # Ingester Signal Status management      
      if (usr == "usr1") then
         
         # Ignore additional SIGUSR1 from Ingester
         Signal.trap("SIGUSR1", "IGNORE")

      
         @bScheduling = false
         bHandled = true
         msg = "Scheduler received SIGUSR1 from Ingester / invoke schedule"
         # puts msg
         # puts @sleepSigUsr2
         # puts @bScheduling
         # @logger.debug(msg)
         if @sleepSigUsr2 == true then
            @sig1flag = true
            # @logger.debug("Scheduler is managing a Processor")
            # manageProcesor
            # schedule
         else
            @sig1flag = false
            
            if @bScheduling == false then
            
               # puts "SIGUSR to call scheduling"
            
               @bScheduling = true
                              
               aThread = Thread.new{
                  # puts "I'm the thread in"
                  @logger.debug(msg) 
                  schedule
                  # puts "I'm the thread out" 
               }
                            
               aThread.join
             
               
               @bScheduling = false
            else
               puts "I'm scheduling already"
            end
            # 
         end
         
         registerSignals
         
      end
      # --------------------------------
     
      if (usr == "sigterm") then
         bHandled = true
         
         Thread.new{
               @logger.info("SIGTERM received / sayonara baby") 
            }
         
         @bExit   = true
         
         exit(0)
         
         
      end

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
