#!/usr/bin/env ruby

# == Synopsis
#
# This is a command line tool that performs regular tasks triggering command received
#
# == Usage
# daemonME.rb  --all [-R]| --mnemonic <COMMAND> --interval <seconds>
#     --Reload              force a Restart of all  daemons
#     --stop <COMMAND>      it stops daemonCleanup for the given 
#     --Force               it forces the execution of the command
#     --List                it lists all commands running as daemons
#     --Stop                it stops of all  daemons
#     --check  <COMMAND>    it checks whether the daemons are running
#     --mnemonic <COMMAND>  
#     --interval [20:00,]10 the frequency it is executed the COMMAND (in seconds)
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --version             shows version number      
# 
# == Author
# Casale & Beach
#
# == Copyright
# Borja Lopez Fernandez
#

require 'rubygems'
require 'optparse'

require 'cuc/Listener'
require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'cuc/CheckerProcessUniqueness'
require 'cuc/CommandLauncher'
require 'ctc/ReadInterfaceConfig'
require 'dcc/ReadConfigDCC'

# Global variables
@dateLastModification = "$Date: 2013/10/28 11:38:26 $"   


# MAIN script function
def main

   include CUC::DirUtils
   include CUC::CommandLauncher

   @isDebugMode        = false
   @isForceMode        = false
   @launchAllListeners = false
   @bCheckListeners    = false
   @isReload           = false
   @bList              = false
   @mnemonic           = "" 
   @intervalSeconds    = 0
   
   cmdOptions = {}


   begin
      cmdParser = OptionParser.new do |opts|

         opts.banner = "daemonME.rb  --all [-R]| --mnemonic <COMMAND> --interval <seconds>"

         opts.on("-m s", "--mnemonic=s", String, "command to be launched") do |arg|
            cmdOptions[:mnemonic] = arg.to_s
            @mnemonic = arg.to_s
         end

         opts.on("-i s", "--interval=s", String, "[20:00,]10 the frequency it is executed the COMMAND (in seconds)") do |arg|
            cmdOptions[:interval] = arg.to_s
            decodeIntervalTime(arg.to_s)
         end

         opts.on("-c s", "--check=s", String, "it checks if <COMMAND> is running as daemon") do |arg|
            cmdOptions[:check] = true
            @mnemonic = arg.to_s
         end

         opts.on("-s c", "--stop=c", "it stops <COMMAND> running as daemon") do |arg|
            cmdOptions[:stop] = arg.to_s
            stopDaemon(arg.to_s)
            return
         end

         opts.on("-F", "--Force", "it forces the execution of the command") do
            cmdOptions[:force] = true
            @isForceMode       = true
         end

         opts.on("-L", "--List", "it lists all commands running as daemons") do
            cmdOptions[:list] = true
         end

         opts.separator ""
         opts.separator "Common options:"
         opts.separator ""
         
         opts.on("-D", "--Debug", "Run in debug mode") do
            cmdOptions[:debug] = true
            @isDebugMode = true
         end

         opts.on_tail("-v", "--version", "shows version number") do
            print("\nCasale & Beach ", File.basename($0))
            print("    $Revision: 1.0 $\n  [", @dateLastModification, "]\n\n\n")
            return
         end

         opts.on_tail("-h", "--help", "Show this message") do
            usage
         end

      end.parse!
   rescue Exception => e
      puts e.to_s
      exit(99)
   end

#    p cmdOptions
#    p ARGV

   if cmdOptions[:list] == true then
      listAllListeners
      exit(0)
   end

   if cmdOptions[:check] == true then
      checkDaemons(@mnemonic)
      exit(0)
   end

   begin
      cmdParser.parse!
      
      mandatory = [:mnemonic, :interval]
      
      missing = mandatory.select{ |param| cmdOptions[param].nil? }
  
      if not missing.empty?
         puts "Missing options: #{missing.join(', ')}"
         puts
         puts cmdParser
         puts
         puts
         usage
      end
   rescue OptionParser::InvalidOption, OptionParser::MissingArgument
      puts $!.to_s
      puts cmdParser
      exit
   end
 
   if @mnemonic == "" or @intervalSeconds == 0 then
      puts cmdParser
      exit(99)
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
         
      # Register a listener for this .
      # Create our lovely listener and start it.
      listener = CUC::Listener.new(File.basename($0), @mnemonic, @intervalSeconds,
                              self.method("triggerCommand").to_proc, @intervalStartTime)

      trap("SIGHUP") {  
                        puts "\n requested for #{@mnemonic}  ...\n"
                     }   

      if @isDebugMode == true
         listener.setDebugMode
      end

      if @isForceMode == true
         listener.setForceMode
         listener.exec(@mnemonic)
      else
         # start server
         listener.run
      end

		   
   end
end
#-------------------------------------------------------------

def decodeIntervalTime(interval)
   if interval.include?(",") == true then
      @intervalStartTime   = interval.split(",")[0]
      @intervalSeconds     = interval.split(",")[1].to_i
   else
      @intervalStartTime   = nil
      @intervalSeconds     = interval.to_i
   end
end

#-------------------------------------------------------------

# By requirements it is needed one listener per  with an
# independent PollingInterval for each one.
def triggerCommand
   startTime = Time.new
   startTime.utc

   if @isDebugMode == true then
      puts "#{@mnemonic}"
   end

   retVal = system(@mnemonic)
      
   if retVal == true then
      puts "Finished #{@mnemonic} execution\n\n"
   else
      puts "Error in #{@mnemonic} execution :-( !\n\n"
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

# By requirements it is needed one listener per  with an
# independent PollingInterval for each one.
#
# It is required to provide a method to trigger and restart
# all s Listeners on demand.
def restartListeners
   
   ftReadConf   = CTC::ReadInterfaceConfig.instance
   arrEntities  = ftReadConf.getAllExternalMnemonics
   arrPIDs      = Array.new
   
   arrEntities.each{|x|
       if ftReadConf.isEnabled4Receiving?(x) == true then
	       checker = CUC::CheckerProcessUniqueness.new(File.basename($0), x, true)
         if checker.getRunningPID == false then
            puts "\nThere was not a listener for #{x}  running !\n"
            launchListener(x)
         else
            pid = checker.getRunningPID
            puts "Sending signal 1 to Process #{pid} for restarting #{x} "
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
   arrEntities.each{|x|
      if ftReadConf.isEnabled4Receiving?(x) == true then
         stopListener(x)
      end
   }
end
#-------------------------------------------------------------

# It stops the listener for the given 
def stopDaemon(mnemonic)
   checker = CUC::CheckerProcessUniqueness.new(File.basename($0), mnemonic, true)
   pid     = checker.getRunningPID
   if pid == false then
      puts "There was not a daemon for #{mnemonic}  running !"
   else
      puts "Sending signal SIGKILL to Process #{pid} for killing  daemon #{mnemonic} "
      Process.kill(9, pid.to_i)
	   checker.release
   end
end
#-------------------------------------------------------------

# It checks whether the Listeners are running or not
# It returns:
# * 0 -> All listeners are running
# * 1 -> All listeners are not running
# * 2 -> Some of them are not running
#
def checkDaemons(mnemonic)

       checker = CUC::CheckerProcessUniqueness.new(File.basename($0), mnemonic, true)
       if @isDebugMode == true then
          checker.setDebugMode
       end
       ret     = checker.isRunning
       if ret == false then
            puts "DaemonME with #{mnemonic} is NOT running"
       else
          puts "DaemonME with #{mnemonic} is running"
          bNone = false
       end
   puts
#    if bAll == true then
#       exit(0)
#    end
#    if bNone == true then
#       exit(1)
#    end
#    exit(2)
end
#-------------------------------------------------------------

def listAllListeners
   checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)
       
   if @isDebugMode == true then
      checker.setDebugMode
   end
   ret  = checker.getAllRunningProcesses

   ret.each{|aLine|
      puts aLine
# Code commented 20121004
# No interfaces but just programs daemonized 
#       if aLine.include?("-m") == false then
#          next
#       end 
#       puts aLine.split(File.basename($0))[1]
#       puts
   }


end
#-------------------------------------------------------------

# By requirements it is needed one listener per  with an
# independent PollingInterval for each one.
def launchListeners      
   ftReadConf   = CTC::ReadInterfaceConfig.instance
   arrEntities  = ftReadConf.getAllExternalMnemonics
   
   puts "Polling #{@projectName} Interfaces ..."
	puts
   
   
   startTime = Time.new
   startTime.utc
        
   # Create a process for sending the Files to each entity
	arrEntities.each{|entity|
      if ftReadConf.getCleanUpFreq(entity) != 0 then
	      launchListener(entity)
      else
         msg = "Task for #{entity} is disabled"
         puts msg
      end
	}
   puts
   return 0   
end
#-------------------------------------------------------------

# It creates a new process Listener for the .
def launchListener(entity)
   ftReadConf   = CTC::ReadInterfaceConfig.instance      
   pI = ftReadConf.getCleanUpFreq(entity)
   if @isDebugMode == true then
      command  = %Q{daemonME.rb --mnemonic #{entity} --interval #{pI} -D}
   else
      command  = %Q{daemonME.rb --mnemonic #{entity} --interval #{pI}}
   end
   puts command
   #---------------------------------------------
   # Create a new process for each Entity
   pid = fork {
      Process.setpriority(Process::PRIO_PROCESS, 0, 1)
      if @isDebugMode == true then
         puts command
      end
      retVal = execute(command, "daemonME")
      if retVal == true then
			exit(0)
      else
         # @logger.error("Could not launch listener for #{entity}")
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
      puts "\nError in daemonME::checkModuleIntegrity :-(\n\n"
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
