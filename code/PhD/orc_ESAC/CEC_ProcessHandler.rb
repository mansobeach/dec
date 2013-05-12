#!/usr/bin/env ruby

#########################################################################
#
# = Ruby source for #ProcessHandler class
#
# = Written by DEIMOS Space S.L. (bolf)
#
# = Data Exchange Component -> Common Utils Component
# 
# CVS:
#   $Id: CEC_ProcessHandler.rb,v 1.3 2009/03/25 09:20:43 decdev Exp $
#
#########################################################################

   # This class implements a generic listener (daemon).
   # It is checked that it is not running a listener with a given name.

require "cuc/DirUtils"
require "cuc/CheckerProcessUniqueness"


NRTP_STATUS = ["NRTP_STATUS_SUCCESS", "NRTP_STATUS_FAILED", "NRTP_STATUS_ACK", "NRTP_STATUS_OFF"]

NRTP_STATUS_SUCCESS     = 0
NRTP_STATUS_FAILED      = 1
NRTP_STATUS_ACK         = 2
NRTP_STATUS_OFF         = 3

class CEC_ProcessHandler

   include CUC::DirUtils
   #-------------------------------------------------------------
   
   # Class constructor.
   # IN Parameters:
   # * string: the name of the listener process.
   # * string: param of the listener process.
   # First of all check if it is already running.
   # Only one process Listener is allowed.
   def initialize(processName = "", cmd = "", pidObserver = 0)
      checkModuleIntegrity
      @pidObserver = pidObserver
      @processName = processName
      @cmd         = cmd

      # Extract from the command the job-order ID 
      begin
         @strJobOrder   = cmd.split("MPL_JOBORD_")[1].slice(32,15)
         @intJobOrder   = @strJobOrder.tr("0", "").to_i
         @intJobOrder   = @strJobOrder.to_i
         @strJobIdFile  = %Q{NRTP_JOBORDER_#{@intJobOrder}}
      rescue Exception => e
         @strJobOrder   = "0"
         @intJobOrder   = 0
         @strJobIdFile  = "NRTP_JOBORDER_0"
      end

      @procLocker = CUC::CheckerProcessUniqueness.new(processName, "", false)     

      if @procLocker.isRunning == true then
         @pidHandler = @procLocker.getRunningPID
         if @pidHandler == false then
            @pidHandler = 0
         else
            @pidHandler = @pidHandler.to_i
         end
      else
         @pidHandler = 0
      end  
      @isDebugMode = false
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "NRTProcessHandler debug mode is on"
      @procLocker.setDebugMode
   end
   #-------------------------------------------------------------   

   def stop
      puts "ProcessHandler::stop"
      if @procLocker.isRunning == false then
         return false
      end
      puts "Sending Signal SIGUSR1 to #{@pidHandler}"
      Process.kill("USR1", @pidHandler)
   end
   #-------------------------------------------------------------

   def resume
      puts "ProcessHandler::resume"
      if @procLocker.isRunning == false then
         return false
      end
      puts "Sending Signal SIGCONT to #{@pidHandler}"
      Process.kill("CONT", @pidHandler)
   end
   #-------------------------------------------------------------

   def quit
      puts "ProcessHandler::quit"
      if @procLocker.isRunning == false then
         return false
      end
      puts "Sending Signal SIGKILL to #{@pidHandler}"
      Process.kill("KILL", @pidHandler)
   end
   
   
   #-------------------------------------------------------------



   def abort
      puts "ProcessHandler::abort"
      @procLocker.setDebugMode
      if @procLocker.isRunning == false then
         return false
      end
      puts "Sending Signal SIGINT to #{@pidHandler}"
      Process.kill("INT", @pidHandler)
   end
   
   
   #-------------------------------------------------------------

   def status(pidClient = 0)
      if pidClient != 0 then
         if @procLocker.isRunning == true then
            createStatusFile(NRTP_STATUS_ACK)
         else
            updateStatusFile(NRTP_STATUS_OFF)
         end   
         begin
            Process.kill("SIGUSR2", pidClient)
         rescue Exception => e
            puts
            puts "Could not send signal to process Observer #{pidClient} :-|"
            puts e.to_s
            #puts
         end
      end
      
      return @procLocker.isRunning
   end
   #-------------------------------------------------------------
   
   def pause
      puts "ProcessHandler::abort"
      if @procLocker.isRunning == false then
         return false
      end
      puts "Sending Signal SIGTSTP to #{@pidHandler}"
      Process.kill("SIGTSTP", @pidHandler)
   end
   #-------------------------------------------------------------
   
   def run
   
      if @procLocker.isRunning == true then
         return false
      end
      
      # Parent exists, child continue
      exit!(0) if fork
   
      # Become session leader without a controlling TTY
      Process.setsid
   
      exit!(0) if fork
         
      @procLocker.setRunning
         
      # Dir.chdir("/")   
      File.umask(0000)
   
      if @isDebugMode == true then
         puts "#{File.basename($0)} set as daemon with pid #{Process.pid}\n\n"
      end
   
  #   Redirect standard streams    
      STDIN.reopen("/dev/null")
  
      if @isDebugMode == false then
         STDOUT.reopen("/dev/null")
         STDERR.reopen STDOUT
      end   
   
#       # Pass as an argument, current process (daemon) PID
#       myPID = Process.pid 
#       @cmd  = "#{@cmd} -p #{myPID}"
      
      # Register Signals
      registerSignals
      
      @@childPID     = 0
      @childStatus   = 99
      
      executable = @cmd.split(" ")[0]

      @childPid = -1
      
      @childPid = fork {
      
         @@childPID = Process.pid
         @mpiLocker = CUC::CheckerProcessUniqueness.new(executable, "", false)
         @mpiLocker.setExternalProcessRunning(@@childPID)
         puts @cmd

         # We place into the HOME directory 
         # before triggering the execution

	      Dir.chdir(ENV["HOME"]){
         	exec(@cmd)
	      }

         # system(@cmd)
      }

      # Parent waits for child
      if @childPid != nil then
         
         # Emulate ACK to Orchestrator | HMI
         processSIGUSR2
         
         # Process.detach(@childPid)

         begin
            Process.wait
            processSIGCHILD
         rescue Exception => e
            puts
            puts "ERROR DEL CARAJO" 
            puts e.to_s
            puts
            createStatusFile(NRTP_STATUS_FAILED)
            sendSignal2Observer
         end
      end

      @procLocker.release
      return true
   
   end
   #-------------------------------------------------------------
   
private

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
   
      if !ENV['NRTP_HMI_TMP'] then
        puts "\nNRTP_HMI_TMP environment variable not defined !  :-(\n\n"
        bCheckOK = false
        bDefined = false
      end

      if !ENV['NRTP_BIN'] then
        puts "\nNRTP_BIN environment variable not defined !  :-(\n\n"
        bCheckOK = false
        bDefined = false
      end
      
      if bCheckOK == false then
        puts "NRTProcessHandler::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
      @hmiStatusDirectory = ENV['NRTP_HMI_TMP']
      checkDirectory(@hmiStatusDirectory)
   end
   #-------------------------------------------------------------
   
   # Register Signals
   def registerSignals
   
      trap("SIGHUP") {  puts "\nPolling requested for #{@mnemonic} I/F ...\n" }
   
      trap("USR1")   {  
                        processSIGUSR1 
                     }
      
      trap("USR2")   {  
                        processSIGUSR2
                     }
      
      trap("SIGTSTP"){  
                        puts "\nSignal SIGTSTP received ...\n"
                        processSIGTSTP
                     }
      
      trap("CONT")   {  
                        puts "\nSignal SIGCONT received ...\n"
                        processSIGCONT
                     }
    
      trap("CLD")    {  
                        puts "\nSignal SIGCHILD received :-)...\n"
                        processSIGCHILD
                     }
   
      trap("INT")    {  
                        puts "\nSignal SIGINT (CTRL+C) received ...\n"
                        processSIGINT 
                     }
      
   end
   #-------------------------------------------------------------

   #
   def processSIGUSR1

      executable = @cmd.split(" ")[0]

      @mpiLocker = CUC::CheckerProcessUniqueness.new(executable, "", false)
      ret = @mpiLocker.getRunningPID
      if ret != false then
         Process.kill("USR1", ret.to_i)
      else
         puts "#{executable} is not present"
      end
      createStatusFile(NRTP_STATUS_ACK)
      sendSignal2Observer
   end
   
   #-------------------------------------------------------------
   
   #   
   def processSIGUSR2
      createStatusFile(NRTP_STATUS_ACK)
      sendSignal2Observer
   end
      
   #-------------------------------------------------------------

   #   
   def processSIGCHILD

      if $?.pid != @childPid then
         # puts "You are not my child !  ;-p"
         return
      end

      if $?.exitstatus == 0 then
         createStatusFile(NRTP_STATUS_SUCCESS)
      else
         createStatusFile(NRTP_STATUS_FAILED)
      end
      sendSignal2Observer
   end
      
   #-------------------------------------------------------------

   #   
   def processSIGCONT
      executable = @cmd.split(" ")[0]
      @mpiLocker = CUC::CheckerProcessUniqueness.new(executable, "", false)
      ret = @mpiLocker.getRunningPID
      if ret != false then
         Process.kill("CONT", ret.to_i)
      else
         puts "#{executable} is not present"
      end
   end
   #-------------------------------------------------------------

   #   
   def processSIGTSTP
      executable = @cmd.split(" ")[0]
      @mpiLocker = CUC::CheckerProcessUniqueness.new(executable, "", false)
      ret = @mpiLocker.getRunningPID
      if ret != false then
         Process.kill("SIGTSTP", ret.to_i)
      else
         puts "Could not send SIGTSTP to #{executable}"
      end
   end
   #-------------------------------------------------------------
      
   # CTRL + C to Abort Execution  
   def processSIGINT
      executable = @cmd.split(" ")[0]
      @mpiLocker = CUC::CheckerProcessUniqueness.new(executable, "", false)
      ret = @mpiLocker.getRunningPID
      if ret != false then
         if @isDebugMode == true then
            puts "Target PID - #{ret}"
         end
         Process.kill("KILL", ret.to_i)
      else
         puts "Could not send SIGINT to #{executable}"
      end
      createStatusFile(NRTP_STATUS_FAILED)
   end
   #-------------------------------------------------------------
   # Update the file status. If there is a previous file, it is not
   # overidden 
   
   def updateStatusFile(status)
      strStatus = ""
      case status         
         when NRTP_STATUS_SUCCESS then strStatus = "NRTP_STATUS_SUCCESS"
         when NRTP_STATUS_FAILED  then strStatus = "NRTP_STATUS_FAILED"
         when NRTP_STATUS_ACK     then strStatus = "NRTP_STATUS_ACK"
         when NRTP_STATUS_OFF     then strStatus = "NRTP_STATUS_OFF"
      else
         puts
         puts "#{status} ststus not supported ! :-("
         puts "NRTProcessHandler::createStatusFile"
         puts   
      end
      
      pwd = Dir.pwd
      
      Dir.chdir(@hmiStatusDirectory)
      
      # Delete any inconsistence status
      begin
         File.delete("NRTP_STATUS_ACK")
      rescue
      end
      
      bFound = false
      
      # Override all previous msg Files
      NRTP_STATUS.each{|statusFile|
         if File.exist?(statusFile) == true then
            bFound = true
         end
      }
      
      if bFound == false then
         cmd = "touch #{strStatus}"
         system(cmd)
      end
      
      Dir.chdir(pwd)      
   end
   #-------------------------------------------------------------
   
   # Create Status notification file
   def createStatusFile(status)
      case status         
         when NRTP_STATUS_SUCCESS then strStatus = "NRTP_STATUS_SUCCESS"
         when NRTP_STATUS_FAILED  then strStatus = "NRTP_STATUS_FAILED"
         when NRTP_STATUS_ACK     then strStatus = "NRTP_STATUS_ACK"
         when NRTP_STATUS_OFF     then strStatus  = "NRTP_STATUS_OFF"
      else
         puts
         puts "#{status} ststus not supported ! :-("
         puts "NRTProcessHandler::createStatusFile"
         puts   
      end
   
      pwd = Dir.pwd
      
      Dir.chdir(@hmiStatusDirectory)
      
      # Override all previous msg Files
      NRTP_STATUS.each{|statusFile|
         begin
            File.delete(statusFile)
         rescue Exception => e
         end
      }
      
      # Delete previous job-order notification files
      cmd = "\\rm -rf NRTP_JOBORDER_*"
      system(cmd)

      # Write job-oder ack file
      if status != NRTP_STATUS_OFF then
         cmd = "touch #{@strJobIdFile}"
         system(cmd) 
      end
      
      # Write NRTP status file
      cmd = "touch #{strStatus}"
      system(cmd)
      
      Dir.chdir(pwd)
      
   end
   #-------------------------------------------------------------
   
   def sendSignal2Observer
      
      #-------------------------------------------------
      
      # Inform Process Observer
      if @pidObserver != 0 then
         begin
            Process.kill("SIGUSR2", @pidObserver)
         rescue Exception => e
            puts
            puts "Could not send signal to process Observer #{@pidObserver} :-|"
            puts e.to_s
            #puts
         end
      end
      #-------------------------------------------------      
   end
   #-------------------------------------------------------------
   
end # class
