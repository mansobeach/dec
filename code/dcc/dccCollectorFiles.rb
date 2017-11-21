#!/usr/bin/env ruby

# == Synopsis
#
# This is a DCC command line tool that polls all the I/Fs
# registered on interfaces.xml and on the database, for retrieving 
# files of registered filetypes. As well It retrieves the I/F 
# exchange directory file content linked to a time-stamp.
# 
# -l flag:
#
# With this option, only "List" of new availables files for Retrieving and Tracking is done.
# This flag overrides configuration flags RegisterContentFlag RetrieveContentFlag in interfaces.xml
# So Check ONLY of new Files is performed anyway.
#
# -R flag:
#
# With this option (Reporting), DCC Reports will be created (see dcc_config.xml). 
# Report files are initally placed in the Interface local inbox and
# if configured in files2InTrays.xml disseminated as nominal retrieved file.
#
# -K flag:      
# The Kill flag cancels an on-going retrieval. It sends SIGTERM signal to all
# existing getFromInterface.rb processes running.
#
# -T flag:
# The timeout flag is used to set a timeout time, that when expired sends a SIGTERM to the dccCollectorFiles
# It is an automated Kill. The timeout value is in seconds
#
#
# == Usage
# dccCollectorFiles.rb [-l] [-R]  [-T <timeout>]
#     --list               list only (not downloading and no ingestion)
#     --receipt            create only receipt file-list with the content available
#     --Report             create a Report when new files have been retrieved
#     --Unknown            shows Unknown files
#     --Kill               it cancels an ongoing delivery
#     --Timeout <timeout>  make dccCollector stop in a given period (in seconds)
#     --help               shows this help
#     --usage              shows the usage
#     --Debug              shows Debug info during the execution
#     --version            shows version number
# 
# == Author
# DEIMOS-Space S.L. (algk)
#
# == Copyright
# Copyright (c) 2009 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# === Data Collector Component
#
# CVS: $Id: dccCollectorFiles.rb,v 1.9 2012/11/07 12:18:53 algs Exp $
#
#########################################################################

require 'getoptlong'

require 'cuc/CheckerProcessUniqueness'
require 'ctc/ReadInterfaceConfig'


# MAIN script function
def main

   
   def SIGTERMHandler
      puts "\n[#{File.basename($0)}] SIGTERM signal received !\n"
      self.killInProgressGetFromInterfaces
      @locker.release
      exit(0)
   end
   #======================================================================

   # It sends SIGTERM signal to the in-progress send2Entity <I/F> processes
   def killInProgressGetFromInterfaces
      dccIntConfig  = CTC::ReadInterfaceConfig.instance
      arrInterfaces = dccIntConfig.getAllMnemonics
   
      arrInterfaces.each{|interface|
         if !dccIntConfig.isEnabled4Receiving?(interface) then
            next
         end
         puts
         puts "Stopping retrieval from #{interface}"
         checker = CUC::CheckerProcessUniqueness.new("getFromInterface.rb", interface, true)
         if @isDebugMode == true then
            checker.setDebugMode
         end
         pid = checker.getRunningPID
         if pid == false then
            if @isDebugMode == true then
               puts "getFromInterface for #{interface} I/F was not running \n"
            end
         else
            if @isDebugMode == true then
               puts "Sending signal SIGTERM to Process #{pid} for killing getFromInterface.rb #{interface}"
            end
            Process.kill(15, pid.to_i)
         end         
      }
   end   
   #======================================================================

   @isDebugMode   = false
   @createReport  = false
	@createReceipt = false
   @listUnknown   = false 
   @listOnly      = false
   bKill          = false
   timeout        = 0

   opts = GetoptLong.new(
     ["--Report", "-R",         GetoptLong::NO_ARGUMENT],
	  ["--receipt", "-r",        GetoptLong::NO_ARGUMENT],
     ["--Unknown", "-U",        GetoptLong::NO_ARGUMENT],
     ["--list", "-l",           GetoptLong::NO_ARGUMENT],
     ["--Kill", "-K",           GetoptLong::NO_ARGUMENT],
     ["--Timeout", "-T",        GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Report"        then @createReport = true
				when "--receipt"       then @createReceipt = true
            when "--Unknown"       then @listUnknown  = true
            when "--list"          then @listOnly = true
            when "--Kill"          then bKill = true
	         when "--Timeout"       then timeout = arg
            when "--Debug"         then @isDebugMode = true
			   when "--help"          then usage
	         when "--usage"         then usage
            when "--version" then
               projectName = DCC::ReadConfigDCC.instance
               version = File.new("#{ENV["DECDIR"]}/version.txt").readline
               print("\nESA - DEIMOS-Space S.L.  DEC   ", version," \n[",projectName.getProjectName,"]\n\n\n")
               exit (0)
         end
      end
   rescue Exception
      exit(99)
   end

   if bKill == true then
      killInProgressRetrieval
      exit(0)
   end

   if @listOnly == true and  @createReceipt == true then
      puts "--list and --receipt are incompatible flags"
      puts
      exit(99)
   end

   if @listUnknown == true and @listOnly == false then
      puts "--Unknown flag requires to specify --list flag"
      puts
      exit(99)
   end

   # Register a handler for SIGTERM
      trap 15,proc{ self.SIGTERMHandler }
   # Register a handler for SIGINT
      trap 2, proc{ self.SIGTERMHandler }

   # This assures there is only one dccCollectorFile running for a given I/F. 
   @locker = CUC::CheckerProcessUniqueness.new(File.basename($0), nil, true)

   if @locker.isRunning == true then
      puts "\n#{File.basename($0)} is already running !\n\n"
      exit(99)
   end

   # Register in lock file the process
   @locker.setRunning

   # Timeout daemon
   # Check each 5 seconds if the parent is dead
   # If parent is dead the daemon stops, if timeout runs out, SIGTERM is called
   if timeout != 0 then
      fork { 
         Process.setpriority(Process::PRIO_PROCESS, 0, 1)
         counter= 0
         timeout= timeout.to_i

         while timeout >= counter do
            exit!(0) if Process.ppid == 1
            sleep(5)
            counter=counter + 5
         end

         self.SIGTERMHandler
      }
   end

   # Collect from all Interfaces
   collectFromInterfaces

end #main


#---------------------------------------------------------------------

# Retrieve from all interfaces
def collectFromInterfaces
   dccIntConfig  = CTC::ReadInterfaceConfig.instance
   arrInterfaces = dccIntConfig.getAllMnemonics
   processInfo   = Hash.new
   
   arrInterfaces.each{|interface|

      if dccIntConfig.isEnabled4Receiving?(interface) == false then
         next
      end

      command  = %Q{getFromInterface.rb --mnemonic #{interface}}

      if @isDebugMode == true then
         command = %Q{#{command} -D}
      end

      if @createReport == true then
         command = %Q{#{command} -R}
      end

      if @createReceipt == true then
         command = %Q{#{command} -r}
      end

      if @listUnknown == true then
         command = %Q{#{command} -U}
      end

      if @listOnly == true then
         command = %Q{#{command} -l}
      end


      # Create a new process for each Interface
      pid = fork { 
         Process.setpriority(Process::PRIO_PROCESS, 0, 1)
#         if @isDebugMode == true then
            puts command
#         end
         exec(command)
      }
      
      sleep(2)
      processInfo[pid] = interface

   }
   
   # Wait for all processes
   bSuccess = true

   arrInterfaces.each{|interface|

      if dccIntConfig.isEnabled4Receiving?(interface) == false then
         next
      end

      pid     = Process.wait
      resCode = $? >> 8         
      
      if resCode != 0 then
         print("\nFAILED to Receive files from ", processInfo[pid], " I/F !\n\n")
         bSuccess = false
      end
   
   }
   return bSuccess
end
#---------------------------------------------------------------------

#==========================================================================

# It sends SIGTERM signal to the active in-progress dccCollectorFiles process
def killInProgressRetrieval
   checker = CUC::CheckerProcessUniqueness.new(File.basename($0), nil, true)
   if @isDebugMode == true then
      checker.setDebugMode
   end
   if checker.getRunningPID == false then
      puts "#{File.basename($0)} was not running !\n"
      exit(99)
   else
      pid = checker.getRunningPID
      puts "Sending signal SIGTERM to Process #{pid} for killing #{File.basename($0)} "
      Process.kill(15, pid.to_i)
      exit(0)
   end
end
#==========================================================================

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -50 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
   exit   
end
#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================

