#!/usr/bin/env ruby

# == Synopsis
#
# This is an Orchestrator command line tool that schedules new jobs.
#
#
# -Q flag:
#
# This option is use to only queue pending files.
# 
#
# == Usage
#
# schedulerComponent.rb  -c <cmd>  | -Q
#
#     --command             [ start | stop | status ]
#     --Queue               it queues pending files
#     --Debug               shows Debug info during the execution
#     --help                shows this help
#     --version             shows version number      
#
#
# == Author
#
# DEIMOS-Space S.L. (BOLF)
#
#
# == Copyright
#
# Copyright (c) 2009 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# === MDS-LEGOS -> Orchestrator
#
# CVS: $Id: schedulerComponent.rb,v 1.3 2009/03/17 12:46:28 decdev Exp $
#
#########################################################################



require 'getoptlong'
require 'rdoc/usage'

require 'orc/OrchestratorScheduler'

require 'cuc/Listener'
require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'cuc/CheckerProcessUniqueness'
require 'cuc/CommandLauncher'


# Global variables
@@dateLastModification = "$Date: 2009/03/17 12:46:28 $"   


# MAIN script function
def main

   include CUC::DirUtils
   include CUC::CommandLauncher
   
   @command            = ""
   @bQueueFiles        = false
   @isDebugMode        = false
   checkModuleIntegrity 
   @orcConfigDir       = ENV['ORC_CONFIG']
   
   opts = GetoptLong.new(        

      ["--command", "-c",	      GetoptLong::REQUIRED_ARGUMENT],
      ["--Queue", "-Q",          GetoptLong::NO_ARGUMENT],
      ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
      ["--usage", "-u",          GetoptLong::NO_ARGUMENT],                   
      ["--help", "-h",           GetoptLong::NO_ARGUMENT],
      ["--version", "-v",        GetoptLong::NO_ARGUMENT]
      )

   begin
      opts.each do |opt, arg|
         case opt 
            when "--command"  then
               @command = arg
            when "--Queue"  then
               @bQueueFiles = true
            when "--Debug"    then 
               @isDebugMode = true                                    	                  
            when "--help"     then 
               RDoc::usage("usage")
            when "--usage"    then 
               RDoc::usage("usage")
            when "--version"  then
               print("\nESA - DEIMOS-Space S.L.  ORC ", File.basename($0))
               print("    $Revision: 1.3 $\n  [", @@dateLastModification, "]\n\n\n")
               exit(0)
         end
      end
   rescue Exception => e
      exit(99)
   end 
     
   if @command == "" and @bQueueFiles == false then
      RDoc::usage("usage")
      exit(0)
   end 

   if @command != "" and @bQueueFiles == true then
      RDoc::usage("usage")
      exit(0)
   end 

   # initialize logger
   loggerFactory = CUC::Log4rLoggerFactory.new("SC", "#{@orcConfigDir}/orchestrator_log_config.xml")
   
   if @isDebugMode then
      loggerFactory.setDebugMode
   end
      
   @logger = loggerFactory.getLogger
   
   if @logger == nil then
      puts
		puts "Could not initialize logging system !  :-("
      puts "Check ORC logs configuration under \"#{@orcConfigDir}/orchestrator_log_config.xml\"" 
		exit(99)
   end

   # ---------------------------------------------
   
   # Just queue files present in Pending2QueueFiles
   if @bQueueFiles == true then
      puts "Queueing new files"
      @OrcSch = ORC::OrchestratorScheduler.new(@logger, @isDebugMode)

      if @isDebugMode == true then
         @OrcSch.setDebugMode
      end

      @OrcSch.enqueuePendingFiles
      exit(0)
   end
   # ---------------------------------------------


   case @command
      when "start" then start         
      when "stop" then stopScheduler
      when "status" then status 
      when "abort" then puts "abort"
   else
      puts "wrong command argument"
      RDoc::usage("usage")
      exit(0)
   end

end #main
#-------------------------------------------------------------
private


def start

   @logger.debug("Starting ORC Scheduler daemon")
        
   @OrcSch = ORC::OrchestratorScheduler.new(@logger, @isDebugMode)
     
   #Create our listener and start it.
   
   listener = CUC::Listener.new(File.basename($0), "", 0, @OrcSch.method("schedule").to_proc)       

   if @isDebugMode == true
      listener.setDebugMode
   end
		   
   # Start server
   listener.run
   
end
#-------------------------------------------------------------


# It stops the Orchestrator scheduler 
   def stopScheduler
      checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)
      pid     = checker.getRunningPID
      
      if pid == false then         
         @logger.debug("There was not a SchedulerComponent daemon running")
      else
         @logger.debug("Sending signal SIGKILL to Process #{pid} to kill the SchedulerComponent")
         Process.kill(9, pid.to_i)         
	      checker.release
         puts "Scheduler Stoped"
      end
   end
#-------------------------------------------------------------


# It restarts the Orchestrator scheduler 
   def restart
      checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)
      pid     = checker.getRunningPID
      
      if pid == false then
         @logger.debug("There was not a SchedulerComponent daemon running")
      else
         @logger.debug("Sending signal SIGTERM to Process #{pid} to kill schedulerComponent")
         Process.kill(15, pid.to_i)
         @OrcSch = ORC::OrchestratorScheduler.new(@logger, @isDebugMode)
      end
   end
#-------------------------------------------------------------


# It checks whether the Listener is running or not
   def status   
       checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)
       if @isDebugMode == true then
          checker.setDebugMode
       end
       ret = checker.isRunning
       if ret == false then
          puts "There is not a SchedulerComponent daemon running"
          @logger.debug("There is not a SchedulerComponent daemon running")            
       else
          puts "There is a daemon running for the SchedulerComponent with pid #{checker.getRunningPID}"
          @logger.debug("There is a daemon running for the SchedulerComponent with pid #{checker.getRunningPID}")           
       end
   end
#-------------------------------------------------------------


# Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true     
      if !ENV['ORC_CONFIG'] then
         puts "\nORC_CONFIG environment variable not defined !\n"
         bDefined = false
      end      
      if bDefined == false then
         puts "\nError in schedulerComponent.rb::checkModuleIntegrity :-(\n\n"
         exit(99)
      end                             
   end
#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
