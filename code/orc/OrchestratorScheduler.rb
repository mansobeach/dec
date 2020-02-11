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

module ORC

class OrchestratorScheduler

   ## -------------------------------------------------------------
  
   ## Class constructor

   def initialize(log, debug)

      checkModuleIntegrity
            
      @logger           = log
      
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
      
      @bFirstSchedule      = true
      @orcTmpDir           = ENV['ORC_TMP']
      @isDebugMode         = debug
      @arrQueuedFiles      = Array.new
      @arrPendingFiles     = Array.new
      @sleepSigUsr2        = false
      @sig1flag            = false
      @bJobJustTriggered   = false
      @bProcRunning        = false

      ## --------------------------------
      ## Get Orchestrator Configuration
      @ftReadConf          = ORC::ReadOrchestratorConfig.instance
      @procWorkingDir      = @ftReadConf.getProcWorkingDir  
      @successDir          = @ftReadConf.getSuccessDir
      @failureDir          = @ftReadConf.getFailureDir   
      @freqScheduling      = @ftReadConf.getSchedulingFreq.to_f
      @resourceManager     = @ftReadConf.getResourceManager
      # --------------------------------

      @bExit               = false      
            
      @sigUsr1Received    = false
      @sigUsr1Count       = 0
      
      registerSignals
   end
   ## -----------------------------------------------------------

   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "OrchestratorScheduler debug mode is on"
   end
   ## -----------------------------------------------------------   

   ## Get all Queued Files
   def loadQueue
      msg = "OrchestratorScheduler::loadQueue begin"
      
      @logger.debug(msg)
      
#      if @isDebugMode == true then
#         puts "Scheduler PAUSED / press any key"
#         STDIN.getc
#      end
      
      HandleDBConnection.new      
      
      @arrQueuedFiles = OrchestratorQueue.getQueuedFiles
      
      @arrQueuedFiles.each{|item|
         @logger.debug("queued : #{item.filename}")
      }
      
      msg = "OrchestratorScheduler::loadQueue completed"
      @logger.debug(msg) 
   end
   ## -----------------------------------------------------------  

   ## This method gets all files referenced in Pending2QueueFile
   ## table and adds them to Orchestrator_Queue table
   def enqueuePendingFiles_BULK

      msg = "OrchestratorScheduler::enqueuePendingFiles begin"
      # puts msg
      @logger.debug(msg) 

      @arrPendingFiles = Pending2QueueFile.getPendingFiles     

      if @arrPendingFiles.empty? == true then
         msg = "No new input files are pending to be queued"
         # puts msg
         @logger.debug(msg)
         return
      end
      
      cmd = "orcQueueInput --Bulk"          
      @logger.debug("#{cmd}")
                  
      ret = system(cmd)
         
      if ret == false then
         @logger.error("Could not queue PENDING files")
      end
   end
   
   ## -------------------------------------------------------------
   
   ## -----------------------------------------------------------  

   ## This method gets all files referenced in Pending2QueueFile
   ## table and adds them to Orchestrator_Queue table
   def enqueuePendingFiles

      msg = "OrchestratorScheduler::enqueuePendingFiles begin"
      @logger.debug(msg) 

      @arrPendingFiles = Pending2QueueFile.getPendingFiles     

      if @arrPendingFiles.empty? == true then
         msg = "No new input files are pending to be queued"
         @logger.debug(msg)
         return
      end
      
      arrIds = Array.new
  
      OrchestratorQueue.transaction do
      
         @arrPendingFiles.each{|file|
             
            new_queued_file = OrchestratorQueue.new
            new_queued_file.trigger_product_id = file.trigger_product_id
            new_queued_file.save
            
            @logger.info("queued pending file #{file.filename}")
            
            Pending2QueueFile.destroy_by(trigger_product_id: file.trigger_product_id)
            
         }
   
      end
         
   end
   
   ## -------------------------------------------------------------
   
   
   def schedule
      msg = "Orchestrator::schedule started"
      puts msg
      @logger.info(msg)
      @sigUsr1Received = false
      while true do
         loadQueue
         dispatch
         enqueuePendingFiles
         msg = "Orchestrator::schedule completed"
         @logger.info(msg)
         if @arrPendingFiles.empty? == true and @sigUsr1Received == false then
            @logger.info("Waiting for new inputs / enabling SIGUSR1 / #{@sigUsr1Count}")
            sleep 10.0 until @sigUsr1Received
         end
         @sigUsr1Received = false
      end
   end
   ## -------------------------------------------------------------

   ## -----------------------------------------------------------

   ## This method will implement Processing Rule Priorities.
   ## It will sort @arrQueuedFiles object to trigger pending jobs
   ## sorted by priority
   def sortPendingJobs
      
      msg = "OrchestratorScheduler::Sorting Pending jobs / PriorityRulesSolver"
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
   ## -----------------------------------------------------------

   ## It removes from execution current job
   def abortCurrentJob
      cmd = "#{@helperExecutable} -c abort"
      @logger.debug("\n#{cmd}")
      system(cmd)
      @logger.debug("Aborting current job #{@currentTrigger.filename}")
      sleep(5)
   end
   ## -----------------------------------------------------------
   
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
         @logger.error("Retrieving input #{selectedQueuedFile.filename}")
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
         @logger.error("Failed job #{procCmd}")
         cmd = "orcQueueUpdate -f #{selectedQueuedFile.filename} -s FAILURE"
         @logger.debug(cmd)
         retVal = system(cmd)
         if retVal == false then
            @logger.error("Failed exec of #{cmd}")
         end
      end
   
      # sleep(@freqScheduling)
   
   end
   ## -------------------------------------------------------------

   ## -------------------------------------------------------------
   ##
   ## Method in charge of dispatching new jobs
   def dispatch
   
      msg = "OrchestratorScheduler::dispatch => Dispatching new job(s)"
      @logger.debug(msg)

      @procWorkingdir   = ""
      inputsDir         = ""

      # --------------------------------
      
      # Scheduler sorting algorithm
      sortPendingJobs
      
      # --------------------------------
      # Trigger Jobs
      
      while !@arrQueuedFiles.empty? do

         triggerJobS2(@arrQueuedFiles.shift)

         cmd = "#{@resourceManager}"
         
         retVal = system(cmd)
         
         while (retVal == false) do
            @logger.debug("No resources available / queue length: #{@arrQueuedFiles.length} / sleeping #{@freqScheduling} s")
            sleep(@freqScheduling)
            retVal = system(cmd)
         end         
      end
   end
   ## -------------------------------------------------------------



private

	## -------------------------------------------------------------
   ##
   ## Check that everything needed by the class is present.
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
   ## -----------------------------------------------------------

   ## This method loads from database queued files
   def getQueuedFiles 
      return OrchestratorQueue.getQueuedFiles
   end
   ## -----------------------------------------------------------

   def getFilesToBeQueued
      return Pending2QueueFile.getPendingFiles
   end
   ## -----------------------------------------------------------

   ## -----------------------------------------------------------

   def registerSignals
      @logger.debug("Registering signals")
      puts
      puts "OrchestratorScheduler::registerSignals"
      
      Signal.trap("SIGTERM") { 
                        signalHandler("sigterm")
                      }                                         


      Signal.trap("SIGUSR1") {                          
                        signalHandler("usr1")               
                      }     

      Signal.trap("SIGUSR2") { 
                        signalHandler("usr2")
                      }                                         
                       
      Signal.trap("SIGHUP")  {
                        signalHandler("sighup")
                      }
   end
   ## -----------------------------------------------------------

   ## -----------------------------------------------------------

   def signalHandler(usr)
      puts
      puts "OrchestratorScheduler::signalHandler=>#{usr}"
      puts
      ## --------------------------------
      
      if (usr == "usr1") then
         @sigUsr1Received = true
         @sigUsr1Count    = @sigUsr1Count + 1
      end

      ## --------------------------------
     
      if (usr == "sigterm") then
         bHandled = true
         puts
         puts "SIGTERM received / sayonara baby :-O"
         puts
         exit(0)
      end

      ## --------------------------------
      ## Unhandled Signal
      if bHandled == false then
         puts "Signal #{usr} not managed"
      end
      ## --------------------------------


   end
   ## -------------------------------------------------------------


end # class

end # module
