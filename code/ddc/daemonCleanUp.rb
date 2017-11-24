#!/usr/bin/env ruby

# == Synopsis
#
# This is a Data Distributor Component command line tool that performs regular Clean-up tasks
# on files sent to a given I/F.
#
# == Usage
# daemonCleanUp.rb  --all [-R]| --mnemonic <MNEMONIC> --interval <seconds>
#     --all                 starts a clean-up daemon for each I/Fs
#     --Reload              force a Restart of all clean-up daemons
#     --stop <MNEMONIC>     it stops daemonCleanup for the given I/F
#     --Stop                it stops of all clean-up daemons
#     --check               it checks whether the daemons are running
#     --mnemonic <MNEMONIC> (mnemonic is case sensitive)
#     --interval            the frequency it is polled I/F given by MNEMONIC (in seconds)
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --version             shows version number      
# 
# == Author
# DEIMOS-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2007 ESA - DEIMOS Space S.L.
#


#########################################################################
#
# === Data Exchange Component -> Data Collector Component
#
# CVS: $Id: daemonCleanUp.rb,v 1.2 2008/07/03 11:38:26 decdev Exp $
#
#########################################################################


 # DDC Daemon CleanUp process that performs  listens to incoming files and dispatches them
 # into the proper directories, depending on the configuration file
 # ft_incoming_files.xml.
 # It agregates #DCC_Listener to implement a daemon.


require 'getoptlong'

require 'cuc/Listener'
require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'cuc/CheckerProcessUniqueness'
require 'cuc/CommandLauncher'
require 'ctc/ReadInterfaceConfig'
require 'dcc/ReadConfigDCC'

# Global variables
@@dateLastModification = "$Date: 2008/07/03 11:38:26 $"   


# MAIN script function
def main

   include CUC::DirUtils
   include CUC::CommandLauncher

   @isDebugMode        = false
   @launchAllListeners = false
   @bCheckListeners    = false
   @isReload           = false
   @mnemonic           = "" 
   @intervalSeconds    = 0
   
   # initialize logger
   loggerFactory = CUC::Log4rLoggerFactory.new("daemonCleanUp", "#{ENV['DCC_CONFIG']}/dec_log_config.xml")
   if @isDebugMode then
      loggerFactory.setDebugMode
   end
   @logger = loggerFactory.getLogger
   if @logger == nil then
      puts
		puts "Error in daemonCleanUp::main"
		puts "Could not set up logging system !  :-("
      puts "Check DEC logs configuration under \"#{ENV['DCC_CONFIG']}/dec_log_config.xml\"" 
		puts
		puts
		exit(99)
   end
   
   opts = GetoptLong.new(
      ["--mnemonic", "-m",       GetoptLong::REQUIRED_ARGUMENT],     
      ["--interval", "-i",       GetoptLong::REQUIRED_ARGUMENT],
      ["--stop", "-s",           GetoptLong::REQUIRED_ARGUMENT],
      ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
      ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
      ["--all", "-a",            GetoptLong::NO_ARGUMENT],
      ["--Stop", "-S",           GetoptLong::NO_ARGUMENT],
      ["--check", "-c",          GetoptLong::NO_ARGUMENT],
      ["--Reload", "-R",         GetoptLong::NO_ARGUMENT],
      ["--version", "-v",        GetoptLong::NO_ARGUMENT],
      ["--help", "-h",           GetoptLong::NO_ARGUMENT]
      )

   begin
      opts.each do |opt, arg|
         case opt
            when "--all"      then @launchAllListeners = true
	         when "--check"    then @bCheckListeners    = true
            when "--Debug"    then @isDebugMode = true
            when "--Reload"   then @isReload = true
            when "--version"  then
               print("\nESA - DEIMOS-Space S.L.  DCC ", File.basename($0))
               print("    $Revision: 1.2 $\n  [", @@dateLastModification, "]\n\n\n")
               exit(0)
            when "--mnemonic" then
               @mnemonic = arg            
            when "--help"     then usage
            when "--interval" then
               @intervalSeconds = arg.to_i
	         when "--stop"     then
               if existEntity?(arg.to_s) == false then
                  puts
                  puts "#{arg.to_s} is not a registered I/F"
                  puts
                  exit(99)
               end
               stopListener(arg.to_s)
               stopGetFromEntity(arg.to_s)
               exit(0)
            when "--Stop"     then 
	            stopListeners
	            puts "\nAll clean-up daemons have been killed ! }=-) \n\n"
	            exit(0)
            when "--usage"    then usage
         end
      end
   rescue Exception
      exit(99)
   end 
   
   if @bCheckListeners == true then
      checkListeners
      exit(0)
   end

   if @isReload == true and @launchAllListeners == false then
      usage
   end
 
   if @launchAllListeners == false and (@mnemonic == "" or @intervalSeconds == 0) then
      usage
   end
 
   # CheckModuleIntegrity
   checkModuleIntegrity
 
   @projectName = DCC::ReadConfigDCC.instance.getProjectName
   @projectID   = DCC::ReadConfigDCC.instance.getProjectID

   if @launchAllListeners == true then
      if @isReload == false then
         launchListeners
      else
         restartListeners
      end
      exit(0)
   else
      
      if existEntity?(@mnemonic) == false then
         puts
         puts "Could not start a clean-up daemon for #{@mnemonic} I/F !  :-("
         puts
         puts "#{@mnemonic} is not a registered I/F"
         puts
         exit(99)
      end
   
      # Register a listener for this I/F.
      # Create our lovely listener and start it.
      listener = CUC::Listener.new(File.basename($0), @mnemonic, @intervalSeconds,
                              self.method("triggerCleanUp").to_proc)

      trap("SIGHUP") {  
                        puts "\nClean-up requested for #{@mnemonic} I/F ...\n"
                        @logger.info("Clean-up Requested for #{@mnemonic} I/F")
                     }   

      if @isDebugMode == true
         listener.setDebugMode
      end
		   
      # start server
      listener.run
   end
end
#-------------------------------------------------------------

# By requirements it is needed one listener per I/F with an
# independent PollingInterval for each one.
def triggerCleanUp
   startTime = Time.new
   startTime.utc
   puts "Clean-up files delivered to #{@mnemonic} I/F ..."
   @logger.info("Triggering #{@mnemonic} I/F delivered files clean-up")
      
   if @isDebugMode == true then
      command  = %Q{fileCleaner.rb --mnemonic #{@mnemonic} -D}
   else
      command  = %Q{fileCleaner.rb --mnemonic #{@mnemonic}}
   end
   if @isDebugMode == true then
      puts "#{command}"
   end

# DCC Commands provide a lot of console output
# Because of this, if it is desired to use DCC_CommandLauncher execute
# They must implement a kind of silent mode.   
#   retVal = execute(command, "daemonCleanUp")
   retVal = system(command)
      
   if retVal == true then
      puts "Finished #{@mnemonic} I/F clean-up\n\n"
      @logger.info("Finished clean-up #{@mnemonic} I/F !")
   else
      puts "Error in #{@mnemonic} I/F clean-up task !\n\n"
      @logger.error("Failure in #{@mnemonic} I/F clean-up task")
   end 

   # calculate required time and new interval time.
   stopTime     = Time.new
   stopTime.utc   
   requiredTime = stopTime - startTime
   
   nwIntSeconds = @intervalSeconds - requiredTime.to_i
   
   if @isDebugMode == true and nwIntSeconds > 0 then
      puts "New Trigger Interval is #{nwIntSeconds} seconds | #{@intervalSeconds} - #{requiredTime.to_i}"
   end
   
   if @isDebugMode == true and nwIntSeconds < 0 then
      puts "Time performed for polling is higher than interval Server !"
      puts "polling interval -> #{@intervalSeconds} seconds "
      puts "time required    -> #{requiredTime.to_i} seconds "
      puts
   end
      
   # The lowest time we return is one second. 
   # 0 would produce the process to sleep forever.
    
   if nwIntSeconds > 0 then
      return nwIntSeconds
   else
      return 1
   end
   
end
#-------------------------------------------------------------

# By requirements it is needed one listener per I/F with an
# independent PollingInterval for each one.
#
# It is required to provide a method to trigger and restart
# all I/Fs Listeners on demand.
def restartListeners
   
   ftReadConf   = CTC::ReadInterfaceConfig.instance
   arrEntities  = ftReadConf.getAllExternalMnemonics
   arrPIDs      = Array.new
   
   arrEntities.each{|x|
       if ftReadConf.isEnabled4Receiving?(x) == true then
	       checker = CUC::CheckerProcessUniqueness.new(File.basename($0), x, true)
         if checker.getRunningPID == false then
            puts "\nThere was not a listener for #{x} I/F running !\n"
            launchListener(x)
         else
            pid = checker.getRunningPID
            puts "Sending signal 1 to Process #{pid} for restarting #{x} I/F"
            Process.kill(1, pid.to_i)
         end     
       end
   }   
   
end
#-------------------------------------------------------------

# It Stops all the Listeners
def stopListeners
   ftReadConf   = CTC::ReadInterfaceConfig.instance
   arrEntities  = ftReadConf.getAllExternalMnemonics
   arrPIDs      = Array.new
   @logger.info("Stopping all I/Fs ...")
   arrEntities.each{|x|
      if ftReadConf.isEnabled4Receiving?(x) == true then
         stopListener(x)
      end
   }
end
#-------------------------------------------------------------

# It stops the listener for the given I/F
def stopListener(mnemonic)
   checker = CUC::CheckerProcessUniqueness.new(File.basename($0), mnemonic, true)
   pid     = checker.getRunningPID
   if pid == false then
      puts "There was not a clean-up daemon for #{mnemonic} I/F running !"
      @logger.info("Clean-up daemon for #{mnemonic} I/F was not running")
   else
      puts "Sending signal SIGKILL to Process #{pid} for killing clean-up daemon #{mnemonic} I/F"
      Process.kill(9, pid.to_i)
	   checker.release
      @logger.info("Clean-up daemon for #{mnemonic} I/F has been disabled")
   end
end
#-------------------------------------------------------------

# It checks whether the Listeners are running or not
# It returns:
# * 0 -> All listeners are running
# * 1 -> All listeners are not running
# * 2 -> Some of them are not running
#
def checkListeners
   ftReadConf   = CTC::ReadInterfaceConfig.instance
   arrEntities  = ftReadConf.getAllExternalMnemonics
   bAll  = true
   bNone = true
   arrEntities.each{|x|
       checker = CUC::CheckerProcessUniqueness.new(File.basename($0), x, true)
       if @isDebugMode == true then
          checker.setDebugMode
       end
       ret     = checker.isRunning
       if ret == false then
          if ftReadConf.isEnabled4Receiving?(x) == true then
             puts "There is not a clean-up daemon for #{x} I/F running !"
             bAll = false
          end  
       else
          puts "Clean-up Daemon for #{x} I/F is running"
          bNone = false
       end
   }
   puts
   if bAll == true then
      exit(0)
   end
   if bNone == true then
      exit(1)
   end
   exit(2)
end
#-------------------------------------------------------------

# By requirements it is needed one listener per I/F with an
# independent PollingInterval for each one.
def launchListeners      
   ftReadConf   = CTC::ReadInterfaceConfig.instance
   arrEntities  = ftReadConf.getAllExternalMnemonics
   
   puts "Polling #{@projectName} Interfaces ..."
	puts
   
   @logger.info("Starting all daemons ...")
   
   startTime = Time.new
   startTime.utc
        
   # Create a process for sending the Files to each entity
	arrEntities.each{|entity|
      if ftReadConf.getCleanUpFreq(entity) != 0 then
	      launchListener(entity)
      else
         msg = "Clean-up Task for #{entity} is disabled"
         puts msg
         @logger.info(msg)
      end
	}
   puts
   return 0   
end
#-------------------------------------------------------------

# It creates a new process Listener for the I/F.
def launchListener(entity)
   ftReadConf   = CTC::ReadInterfaceConfig.instance      
   pI = ftReadConf.getCleanUpFreq(entity)
   if @isDebugMode == true then
      command  = %Q{daemonCleanUp.rb --mnemonic #{entity} --interval #{pI} -D}
   else
      command  = %Q{daemonCleanUp.rb --mnemonic #{entity} --interval #{pI}}
   end
   puts command
   @logger.info("Starting clean-up daemon for #{entity} I/F")
   #---------------------------------------------
   # Create a new process for each Entity
   pid = fork {
      Process.setpriority(Process::PRIO_PROCESS, 0, 1)
      if @isDebugMode == true then
         puts command
      end
      retVal = execute(command, "daemonCleanUp")
      if retVal == true then
			exit(0)
      else
         # @logger.error("Could not launch listener for #{entity} I/F")
		   puts "Error launching listener for #{entity}"
         exit(99)
      end            
   }
   #---------------------------------------------
end
#-------------------------------------------------------------

# It exists?
def existEntity?(mnemonic)
   ftReadConf   = CTC::ReadInterfaceConfig.instance   
   return ftReadConf.exists?(mnemonic)
end
#-------------------------------------------------------------

# Check that everything needed by the class is present.
def checkModuleIntegrity
   bDefined = true     
   if !ENV['DCC_TMP'] then
      puts "\nDCC_TMP environment variable not defined !\n"
      bDefined = false
   end      
   if bDefined == false then
      puts "\nError in daemonCleanUp::checkModuleIntegrity :-(\n\n"
      exit(99)
   end                             
end
#-------------------------------------------------------------

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -25 #{fullpathFile}"}`
      
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
