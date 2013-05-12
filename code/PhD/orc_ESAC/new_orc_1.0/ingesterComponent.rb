#!/usr/bin/env ruby

# == Synopsis
#
# This is an Orchestrator command line tool that polls incoming files.
#
#
# == Usage
#
# ingesterComponent.rb -c start -d <full_path_dir> -i <seconds>
#
#     --command [ start | stop | status ]
#               start  -> it starts the ingester
#               stop   -> it stops the ingester
#               status -> it checks whether ingester is running
#
#     --dir <full_path_dir> directory to be polled)
#     --interval <time>     in-tray polling frequency (seconds)
#     --pid                 <process_pid_to_ack>
#     --Debug               shows Debug info during the execution
#     --help                shows this help
#     --version             shows version number      
#
#
# == Author
#
# DEIMOS-Space S.L. (algk)
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
# CVS: $Id: ingesterComponent.rb,v 1.2 2009/03/17 12:47:03 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'cuc/Listener'
require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'cuc/CheckerProcessUniqueness'
require 'cuc/CommandLauncher'

require 'orc/OrchestratorIngester'

# Global variables
@@dateLastModification = "$Date: 2009/03/17 12:47:03 $"   


# MAIN script function
def main

   include CUC::DirUtils
   include CUC::CommandLauncher

   @command            = ""
   @isDebugMode        = false
   @pollingDir			  = ""
   @intervalSeconds    = 0
   @pid                = nil
   
   # Check environment pre-requisites
   checkModuleIntegrity  
   
   @orcConfigDir       = ENV['ORC_CONFIG']

   opts = GetoptLong.new(
      ["--command", "-c",	      GetoptLong::REQUIRED_ARGUMENT],        
      ["--dir", "-d",	         GetoptLong::REQUIRED_ARGUMENT],
      ["--interval", "-i",       GetoptLong::REQUIRED_ARGUMENT],
      ["--pid", "-p",            GetoptLong::REQUIRED_ARGUMENT],
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
            when "--dir"  then
               @pollingDir = arg
            when "--interval" then
               @intervalSeconds = arg.to_i
            when "--pid"      then
               @pid = arg.to_i                         
            when "--Debug"    then 
               @isDebugMode = true                                    	                  
            when "--help"     then 
               RDoc::usage("usage")
               exit(0)
            when "--usage"    then 
               RDoc::usage("usage")
               exit(0)
            when "--version"  then
               print("\nESA - DEIMOS-Space S.L.  ORC ", File.basename($0))
               print("    $Revision: 1.2 $\n  [", @@dateLastModification, "]\n\n\n")
               exit(0)
         end
      end
   rescue Exception => e      
      RDoc::usage("usage")
      exit(99)
   end

   if @command == "" then
      RDoc::usage("usage")
      exit(0)
   end

   # initialize logger
   loggerFactory = CUC::Log4rLoggerFactory.new("IC", "#{@orcConfigDir}/orchestrator_log_config.xml")
   
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


   case @command
      when "start" then start         
      when "stop" then stopIngestor
      when "status" then status 
      when "abort" then puts "abort"
   else
      puts "wrong command argument"
      RDoc::usage("usage")
      exit(0)
   end
end


#===============================================================================

private

def start     

   # Check input parameters
   if (@intervalSeconds == 0 or @pollingDir == "") then
      puts "the polling dir or the interval are wrong"
      RDoc::usage("usage")
   end
   
   @logger.debug("Started ORC Ingester with freq #{@intervalSeconds} s")
       
   @OrcIng = ORC::OrchestratorIngester.new(@pollingDir, @intervalSeconds, @isDebugMode, @logger, @pid) 
        
   # Create our lovely listener and start it.
   listener = CUC::Listener.new(File.basename($0), "", @intervalSeconds, @OrcIng.method("poll").to_proc)

   trap("SIGHUP") {  
                     @logger.debug("Restart, Ingestor, Polling Requested for #{@pollingDir}")
                     self.restart
                  }   

   if @isDebugMode == true
      listener.setDebugMode
   end
		   
      # start server
      listener.run
end

#===============================================================================

# It stops the Orchestrator Ingestor 

def stopIngestor
   checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)
   pid     = checker.getRunningPID

   if pid == false then
#      if @isDebugMode == true then
         puts "There was no IngesterComponent daemon running !"
#      end
   else
#      if @isDebugMode == true then
         puts "Sending SIGKILL to Process #{pid} to stop IngesterComponent"
#      end      
      @logger.debug("Sending SIGKILL to Process #{pid} to stop IngesterComponent")
      Process.kill(9, pid.to_i)
      checker.release
   end
end

#===============================================================================


# It stops the Orchestrator Ingestor 
def restart
   checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)
   pid     = checker.getRunningPID

   if pid == false then
      @logger.debug("There was not an ingesterComponent daemon running !")
   else         
      @logger.debug("Sending signal SIGTERM to Process #{pid} to kill the ingesterComponent")         
      Process.kill(15, pid.to_i)
      checker = CUC::CheckerProcessUniqueness.new("schedulerComponent.rb", "", true)
      pid     = checker.getRunningPID
      @OrcIng = ORC::OrchestratorIngester.new(@pollingDir, @intervalSeconds, @isDebugMode, @logger, pid)     
   end
end

#===============================================================================

# It checks whether the Listener is running or not
def status   
    checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)

    if @isDebugMode == true then
       checker.setDebugMode
    end
    ret = checker.isRunning
    if ret == false then
#       if @isDebugMode == true then
         puts "No daemon for IngesterComponent is running"
#       end          
#       @logger.debug("No daemon for IngesterComponent is running")            
    else
#       if @isDebugMode == true then
         puts "There is a daemon running for the IngesterComponent with pid #{checker.getRunningPID}"
#       end  
#       @logger.debug("There is a daemon running for the IngesterComponent with pid #{checker.getRunningPID}")         
    end
end

#===============================================================================


# Check that everything required by the executable is present.  
def checkModuleIntegrity
   bDefined = true           
   if !ENV['ORC_CONFIG'] then
      @logger.debug("$ORC_CONFIG environment variable not defined !")
      bDefined = false
   end      
   if bDefined == false then
      @logger.error("Error in ingesterComponent.rb::checkModuleIntegrity")
      exit(99)
   end                             
end

#===============================================================================

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
