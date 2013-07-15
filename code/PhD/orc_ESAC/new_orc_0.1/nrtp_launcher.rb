#!/usr/bin/env ruby

# == Synopsis
# This is a command line tool that allows to trigger the NRTP manually without an HMI.
#
# -c <command> flag:
# It performs one of the following commands to the processor.
#     abort
#     status
#     stop
#
#
# == Usage
# nrtp_launcher.rb  --processor <proc> --job-order <job> [--Hostfile <path>] | --command <cmd>  [--PID <pid>]
#   --processor <proc>   path to the NRTP executable to use
#   --hostfile  <hots>   path to the hostfile
#   --job-order <job>    name of the job-order file
#   --PID <pid>          Observer process PID 
#   --Verbose            execution in verbose mode
#   --version            shows version number
#   --help      shows this help
#   --usage     shows the usage
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2007 ESA - Deimos Space S.L.
#

#########################################################################
#
# === SMOS Near Real-Time Processor
# 
# CVS: $Id: nrtp_launcher.rb,v 1.5 2007/02/06 13:38:56 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'orc/ProcessHandler'
require 'cuc/Log4rLoggerFactory'

# Global variables
@@dateLastModification = "$Date: 2007/02/06 13:38:56 $"   # to keep control of the last modification
                                     # of this script
@@verboseMode     = 0                # execution in verbose mode
@@hostfilepath    = ""
@@jobOrderName    = ""
@@processorPath   = ""
@@targetPID       = 0

# MAIN script function
def main
   @isDebugMode = false
   @commandNRTP = ""
   
   opts = GetoptLong.new(
     ["--command", "-c",        GetoptLong::REQUIRED_ARGUMENT],
     ["--Show", "-S",           GetoptLong::NO_ARGUMENT],
     ["--Verbose", "-V",        GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--processor", "-p",      GetoptLong::REQUIRED_ARGUMENT],
     ["--job-order", "-j",      GetoptLong::REQUIRED_ARGUMENT],
     ["--Hostfile", "-H",       GetoptLong::REQUIRED_ARGUMENT],
     ["--PID", "-P",            GetoptLong::REQUIRED_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Verbose"       then @@verboseMode = 1
            when "--Debug"         then @isDebugMode = true
            when "--version" then
               print("\nESA - Deimos-Space S.L.  DEC ", File.basename($0), " $Revision: 1.5 $  [", @@dateLastModification, "]\n\n\n")
               exit (0)
            when "--command" then
               @commandNRTP = arg.to_s        
            when "--Hostfile" then
               @@hostfilepath = arg.to_s
            when "--processor" then
               @@processorPath = arg.to_s
            when "--PID" then
               @@targetPID = arg.to_i
            when "--job-order" then 
               @@jobOrderName = arg.to_s
            when "--help"          then RDoc::usage
            when "--usage"         then RDoc::usage("usage")
            when "--Show"          then @@bShowMnemonics = true
         end
      end
   rescue Exception
      exit(99)
   end


   if (@@processorPath == "" or @@jobOrderName == "") and (@commandNRTP == "") then RDoc::usage end
   
   if @@hostfilepath == "" then
      @@hostfilepath = "#{ENV['NRTP_MPI_CONFIG']}/nrtp_mpi_hosts"
      if File.exists?(@@hostfilepath) == false then
         puts
         puts "MPI Hosts file #{@@hostfilepath} does not exist ! :-("
         puts
         exit(99)
      end
   end
   
   logFactory = CUC::Log4rLoggerFactory.new("NRTP_Launcher", "#{ENV['NRTP_CONFIG']}/logs/mpi_launcher_log4r.xml")
   
   if @isDebugMode then
      logFactory.setDebugMode
   end
   
   @logger = logFactory.getLogger
   
   cmd = "mpirun -hostfile #{@@hostfilepath} #{@@processorPath} -j #{@@jobOrderName}"
   
   if @isDebugMode then
      cmd = "#{cmd} -D"
   end
   
   @pHandler = NRTProcessHandler.new("nrtp_launcher.rb", cmd, @@targetPID)

   @logger.debug("Launching NRTProcessHandler for PID : #{@@targetPID}")
   @logger.debug("Cmd = #{cmd}")

   if @isDebugMode then
      @pHandler.setDebugMode
   end
   
   if @commandNRTP != "" then
      @logger.debug("Processing command : #{@commandNRTP}")
      processCommand
      exit
   end
   
   @logger.info("NRTP MPI Launcher is starting ...")
   ret = @pHandler.run
      
   if ret == false then
      puts "NRTP MPI Launcher is already running"
      @logger.warn("NRTP MPI Launcher was already running !")
      exit(0)
   else
      puts
      puts "NRTP Execution ended"
      puts
      puts "Bye ! ;-)"
      puts
   end
   
end

def processCommand
   cmd = @commandNRTP
   case cmd.downcase
      when "quit"        then processCmdQuit
      when "resume"      then processCmdResume
      when "stop"        then processCmdStop
      when "status"      then processCmdStatus
      when "abort"       then processCmdAbort
      when "pause"       then processCmdPause
      when "help"        then processCmdHelp
   else
      puts "Ilegal command #{cmd} ! :-("
      @logger.error("Ilegal command #{cmd} !")
      exit(99)
   end
   exit(0)
end
#===============================================================================

def processCmdQuit
   puts "Quitting ..."
   @logger.info("Quitting ...")
   ret = @pHandler.quit
   if ret == false then
      puts "ERROR Quitting ..."
      @logger.error("ERROR while quitting ...")
   end
end

#===============================================================================

def processCmdAbort
   puts "Aborting ..."
   @logger.info("NRTP MPI Launcher Aborting ...")
   ret = @pHandler.abort
   if ret == false then
      puts "ERROR Aborting ..."
      @logger.error("ERROR while aborting ...")
   end
end

#===============================================================================

def processCmdPause
   puts "Pausing ..."
   @logger.info("NRTP MPI Launcher Pausing ...")
   @pHandler.pause
end

#===============================================================================


def processCmdResume
   puts "Resuming ..."
   @logger.info("NRTP MPI Launcher Resuming ...")
   @pHandler.resume
end

#===============================================================================

def processCmdStop
   puts "Stopping ..."
   @logger.info("NRTP MPI Launcher Stopping ...")
   @pHandler.stop
end

#===============================================================================

def processCmdStatus
   ret = @pHandler.status(@@targetPID)
   if ret == true then
      puts "NRTP is running"
      @logger.debug("NRTP Status request : RUNNING")
      exit(0)
   else
      puts "NRTP is not running"
      @logger.debug("NRTP Status request : NOT RUNNING")
      exit(1)
   end
end

#===============================================================================

def processCmdHelp
   puts "abort  -> it aborts nrtp generation"
   puts "help   -> it prints this help"
   puts "pause  -> it pauses NRTP execution"
   puts "resume -> it resumes NRTP execution"
   puts "quit   -> it quits NRTP"
   puts "status -> it checks whether NRTP is running"
   puts "stop   -> it finishes generation on a sync point"
end

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
