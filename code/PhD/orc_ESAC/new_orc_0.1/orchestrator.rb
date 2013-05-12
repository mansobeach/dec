#!/usr/bin/env ruby

# == Synopsis
#
# This is command line tool that manages all Orchestrator elements.
# (Ingester, Scheduler).
#
#
# == Usage
#
# orchestrator.rb -c [start | stop | status | abort ]
#
#     --command             (start | stop | status | abort)
#     --Debug               shows Debug info during the execution
#     --help                shows this help
#     --version             shows version number      
#
# 
# == Author
#
# DEIMOS-Space S.L. (ALGK)
#
#
# == Copyright
#
# Copyright (c) 2009 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# === Ruby source for #Orchestrator
#
# === Written by DEIMOS Space S.L. (algk)
#
# === MDS-LEGOS => ORC Component
# 
# CVS: $Id: orchestrator.rb,v 1.3 2009/03/17 12:48:23 decdev Exp $
#
# module ORC
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'cuc/Log4rLoggerFactory'
require 'cuc/CheckerProcessUniqueness'
require 'cuc/CommandLauncher'

require 'orc/ReadOrchestratorConfig'

include CUC::CommandLauncher

def main
   checkModuleIntegrity  
   @orcConfigDir       = ENV['ORC_CONFIG']
   @isDebugMode        = false
   @bCheckIngester     = false  
   @bStop              = false
   @hashTable          = Hash.new()     
   @command            = ""

   opts = GetoptLong.new(
      ["--command", "-c",	      GetoptLong::REQUIRED_ARGUMENT],
      ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
      ["--usage", "-u",          GetoptLong::NO_ARGUMENT],                   
      ["--help", "-h",           GetoptLong::NO_ARGUMENT],
      ["--version", "-v",        GetoptLong::NO_ARGUMENT]
      )

   begin
      opts.each do |opt, arg|
         case opt
            when "--command" then
               @command = arg           
            when "--Debug"    then 
               @isDebugMode = true                                    	                  
            when "--help"     then 
               RDoc::usage("usage")
            when "--version"  then
               print("\nESA - DEIMOS-Space S.L.  ORC ", File.basename($0))
               print("    $Revision: 1.3 $\n  [", @dateLastModification, "]\n\n\n")
               exit(0)
         end
      end
   rescue Exception => e
      puts e.message
      exit(99)
   end 

   if @command == "" then
      RDoc::usage("usage")
      exit(0)
   end

   if @command != "start" and @command != "stop" and @command != "status" and @command != "abort" then
      puts "Wrong command"      
      exit(0)
   end

   # initialize logger
   loggerFactory = CUC::Log4rLoggerFactory.new("Orchestrator", "#{@orcConfigDir}/orchestrator_log_config.xml")
   
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

#    #check if there is an orchestrator allready runnning
#    @locker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)
#    if @locker.isRunning == true then
#       puts "\nOrchestrator is running !\n\n"        
#    else      
#       @locker.setRunning
#    end

   @schedulerChecker = CUC::CheckerProcessUniqueness.new("schedulerComponent.rb", "", true)
   @ingesterChecker  = CUC::CheckerProcessUniqueness.new("ingesterComponent.rb", "", true)
   
   case @command
      when "start"   then start         
      when "stop"    then stop
      when "status"  then processStatus 
      when "abort"   then puts "abort"
   end
        
end #main
#---------------------------------------------- 


def start 
   puts "Starting Orchestrator"
   @logger.debug("Starting Orchestrator")
   
   @ftReadConf       = ORC::ReadOrchestratorConfig.instance 
   @pollingDir       = @ftReadConf.getPollingDir
   @intervalSeconds  = @ftReadConf.getPollingFreq
   
   # -----------------------------------
   # Scheduler command management
   if @schedulerChecker.isRunning == false then      
      cmd = "schedulerComponent.rb -c start"
      if @isDebugMode == true
         cmd = "#{cmd} -D"
         puts cmd
      end
      
      # Creates a new process 
      fork { exec(cmd) }
      
      # Give time to the process to register its PID
      sleep(10)

      pid = @schedulerChecker.getRunningPID
      puts "Scheduler started with pid #{pid}"
      puts
   #   @logger.debug("Scheduler started with pid #{pid}")
   else                                         
      puts "Scheduler is already running"
      @logger.warn("Scheduler is already running")
      exit(99)
   end
   # -----------------------------------

   # -----------------------------------
   # Ingester command management
   
   checker = CUC::CheckerProcessUniqueness.new("ingestorComponent.rb", "", true)
   if @ingesterChecker.isRunning == false then
      cmd= "ingesterComponent.rb -c start -d #{@pollingDir} -i #{@intervalSeconds} -p #{pid}" 
      if @isDebugMode == true
         puts cmd
      end
      
      # Creates a new process
      fork { exec(cmd) }

      # Give time to the process to register its PID
      sleep(5)
      
      pid = @ingesterChecker.getRunningPID
      puts "Ingester started with pid #{pid}"
 #     @logger.debug("Ingester started with pid #{pid}")
   else
      puts "Ingester is already running"
      @logger.warn("Ingester is already running")
      exit(99)
   end
   # -----------------------------------

   puts "Orchestrator Started"
   @logger.info("Orchestrator Started")
 
end   
#-------------------------------------------

# 
# def restart      
#    pid= @hashTable["scheduler"]   
#    if pid == false then
#       if @isDebugMode then
#          @logger.debug("Restarting: Scheduler daemon was not running, starting it")
#       end
#       start
#    else
#       if @isDebugMode then        
#          @logger.info("Restarting Orchestrator Scheduler daemon [#{pid}]")
#       end
#       Process.kill(1, pid.to_i)	      
#    end 
# 
#    sleep(2)
#    pid= @hashTable["ingestor"]        
#    if pid == false then
#       if @isDebugMode then
#          @logger.debug("Restarting: Ingester daemon was not running, starting it")
#       end
#       start
#    else
#       if @isDebugMode then        
#          @logger.info("Restarting Orchestrator Ingester daemon [#{pid}]")
#       end
#       Process.kill(1, pid.to_i)	      
#    end     
#    @logger.debug("Restarting orchestrator succesfull")
# end
# #---------------------------------------------------


def processStatus

   puts "Checking status"

   if @ingesterChecker.isRunning == false then 
      puts "No daemon is running for the Ingester  component"
      # @logger.debug("There is not a daemon running for the ingestor component")
   else
      puts "Ingester  component is running with pid #{@ingesterChecker.getRunningPID}"
      # @logger.debug("There is a daemon running for the ingestor component with pid #{@ingesterChecker.getRunningPID}")
   end

   if @schedulerChecker.isRunning == false then
      puts "No daemon is running for the Scheduler component"
      # @logger.debug("There is not a daemon running for the scheduler component")
   else
      puts "Scheduler component is running with pid #{@schedulerChecker.getRunningPID}"
      # @logger.debug("There is a daemon running for the scheduler component with pid #{@schedulerChecker.getRunningPID}")
   end

end
#===============================================================================


def stop
   @logger.debug("Stopping Orchestrator")
   puts "Stopping Orchestrator:"

   if @ingesterChecker.isRunning == true then
      pid = @ingesterChecker.getRunningPID
      puts "Sending signal SIGTERM to Process #{pid} to kill IngesterComponent"
      @logger.debug("Stopping orchestrator ingestor  daemon")
      Process.kill(15, pid.to_i)
   else
      puts "Ingester  was not running"
   end

   if @schedulerChecker.isRunning == true then
      pid = @schedulerChecker.getRunningPID
      puts "Sending signal SIGTERM to Process #{pid} to kill SchedulerComponent"
      @logger.debug("Stopping orchestrator scheduler daemon")
      Process.kill(15, pid.to_i)
      sleep(60)
      if @schedulerChecker.isRunning == true then
         puts "Sending signal SIGKILL to Process #{pid} to kill SchedulerComponent"
         Process.kill(9, pid.to_i)
      end
   else
      puts "Scheduler was not running"
      puts
   end
   @logger.info("Orchestrator Stopped")
end
#===============================================================================


private
  

#===============================================================================

# Check that everything needed by the class is present.
def checkModuleIntegrity
   if !ENV['ORC_BASE'] then
      puts "ORC_BASE environment variable not defined !  :-(\n"
      bCheckOK = false
      bDefined = false
   end

   if !ENV['ORC_CONFIG'] then
      puts "ORC_CONFIG environment variable not defined !  :-(\n"
      bCheckOK = false
      bDefined = false
   end

   isToolPresent = `which ingesterComponent.rb`
      
   if isToolPresent[0,1] != '/' then
      puts "ingesterComponent.rb tool not present in PATH !  :-(\n"
      bCheckOK = false
   end

   isToolPresent = `which schedulerComponent.rb`
      
   if isToolPresent[0,1] != '/' then
      puts "schedulerComponent.rb tool not present in PATH !  :-(\n"
      bCheckOK = false
   end

   if bCheckOK == false then
      puts
      puts "orchestrator.rb::checkModuleIntegrity FAILED ! =-O \n\n"
      exit(99)
   end

end

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
