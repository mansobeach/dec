#!/usr/bin/env ruby

# == Synopsis
#
# This is a Data Collector Component command line tool that manages the I/Fs listeners.
#
# == Usage
# ddcListener.rb  -s --interval <seconds> | -S  [-O] [-N] [-R]
#     --start               it starts the listener
#     --Stop                it stops the listener
#     --check               it checks whether the listeners are running
#     --interval            the frequency it is polled I/F given by MNEMONIC (in seconds)
#
#     --ONCE                The files are just sent once for each I/F
#     --NOARCHIVE           This flag skips the file archive retrieving step
#     --Report              This flag enables Delivered Files Reports creation
#
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --version             shows version number      
# 
# == Author
# DEIMOS-Space S.L. (algk)
#
# == Copyright
# Copyright (c) 2005 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# === Data Exchange Component -> Data Collector Component
#
# CVS: $Id: ddcListener.rb,v 1.7 2011/08/24 18:57:52 algs Exp $
#
#########################################################################

require 'getoptlong'

require 'cuc/Listener'
require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'cuc/CheckerProcessUniqueness'
require 'ddc/ReadConfigDDC'

# MAIN script function
def main

   include CUC::DirUtils

   @isDebugMode         = false
   @launchAllListeners  = false
   @bCheckListener      = false
   @isReload            = false
   @intervalSeconds     = 0
   @flags               = ""
 
   # CheckModuleIntegrity
   checkModuleIntegrity
   
   # initialize logger
   begin
      loggerFactory = CUC::Log4rLoggerFactory.new("ddcListener", "#{ENV['DCC_CONFIG']}/dec_log_config.xml")
   rescue Exception => e
      puts
      puts "Error in minArcThreshold::main"
      puts "Could not set up logging system !  :-("
      puts e
      puts
      exit(99)
   end

   if @isDebugMode then
      loggerFactory.setDebugMode
   end

   @logger = loggerFactory.getLogger
   if @logger == nil then
      puts
		puts "Error in ddcListener.rb::main"
		puts "Could not set up logging system !  :-("
      puts "Check DEC logs configuration under \"#{ENV['DCC_CONFIG']}/dec_log_config.xml\"" 
		puts
		puts
		exit(99)
   end
   

   opts = GetoptLong.new(   
      ["--interval", "-i",       GetoptLong::REQUIRED_ARGUMENT],
      ["--start", "-s",          GetoptLong::NO_ARGUMENT],
      ["--stop", "-S",           GetoptLong::NO_ARGUMENT],
      ["--ONCE", "-O",           GetoptLong::NO_ARGUMENT],
      ["--NOARCHIVE", "-N",      GetoptLong::NO_ARGUMENT],
      ["--Report", "-R",         GetoptLong::NO_ARGUMENT],
      ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
      ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
      ["--check", "-c",          GetoptLong::NO_ARGUMENT],
      ["--version", "-v",        GetoptLong::NO_ARGUMENT],
      ["--help", "-h",           GetoptLong::NO_ARGUMENT]
      )

   begin
      opts.each do |opt, arg|
         case opt
            when "--start"    then  @bStart           = true
            when "--interval" then  @intervalSeconds  = arg.to_i
            when "--stop"     then  stopListener
	                                 puts "\nddcListener has been killed ! }=-) \n\n"
	                                 @ex=true
	         when "--check"    then  @bCheckListener  = true
            when "--ONCE"     then  @flags += " -O"
            when "--NOARCHIVE"then  @flags += " -N"
            when "--Report"   then  @flags += " -R"
            when "--Debug"    then  @isDebugMode      = true
            when "--usage"    then  usage
            when "--help"     then  usage
            when "--version"  then
               projectName = DDC::ReadConfigDDC.instance
               version = File.new("#{ENV["DECDIR"]}/version.txt").readline
               print("\nESA - DEIMOS-Space S.L.  DEC   ", version," \n[",projectName.getProjectName,"]\n\n\n")
               @ex=true
         end
      end
   rescue Exception => e
      puts e
      exit(99)
   end 
   
   #exit doesnt work on opts. Workaround.
   if @ex then exit(0) end

   if @bCheckListener == true then
      checkListener
   end

   if !@bStart or @intervalSeconds == 0 then
      usage
   end
 
   # Register a listener for this I/F.
   # Create our lovely listener and start it.
   listener = CUC::Listener.new(File.basename($0), "", @intervalSeconds, self.method("ddcDeliverFiles").to_proc)

   if @isDebugMode == true
      listener.setDebugMode
   end
		   
   # start server
   listener.run

end
#-------------------------------------------------------------

# By requirements it is needed one listener per I/F with an
# independent PollingInterval for each one.
def ddcDeliverFiles
   startTime = Time.new
   startTime.utc   
 
   puts "Polling #{ENV["DDC_ARCHIVE_ROOT"]} "
   @logger.info("Polling #{ENV["DDC_ARCHIVE_ROOT"]} ...")
     
    if @isDebugMode == true then
       command  = %Q{ddcDeliverFiles.rb -D #{@flags}}
       puts "#{command}"
    else
       command  = %Q{ddcDeliverFiles.rb #{@flags}}
    end

   retVal = system(command)
   
   if @isDebugMode then
            
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


# def restartListener
#    
#    ftReadConf   = CTC::ReadInterfaceConfig.instance
#    arrEntities  = ftReadConf.getAllExternalMnemonics
#    arrPIDs      = Array.new
#    
#    arrEntities.each{|x|
#        if ftReadConf.isEnabled4Receiving?(x) == true then
# 	       checker = CUC::CheckerProcessUniqueness.new(File.basename($0), x, true)
#          if checker.getRunningPID == false then
#             puts "\nThere was not a listener for #{x} I/F running !\n"
#             launchListener(x)
#          else
#             pid = checker.getRunningPID
#             puts "Sending signal 1 to Process #{pid} for restarting #{x} I/F"
#             Process.kill(1, pid.to_i)
#          end     
#        end
#    }   
#    
# end


#-------------------------------------------------------------

# It stops the listener for the given I/F
def stopListener
   checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)
   pid     = checker.getRunningPID
   if pid == false then
      puts "There was not a listener for ddcListener running !"
      @logger.info("ddcListener was not running")
   else
      puts "Sending signal SIGKILL to Process #{pid} for killing ddcListener"
      Process.kill(9, pid.to_i)
	   checker.release
      @logger.info("ddcListener has been disabled")
   end
end
#-------------------------------------------------------------

# It checks whether the Listener is running or not
def checkListener
   checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true)
   if @isDebugMode == true then
      checker.setDebugMode
   end
   ret     = checker.isRunning

   if ret then 
      puts "ddclistener is running with pid #{checker.getRunningPID}"
      exit(0)
   else
      puts "There is not a ddcListener running !"
      exit(1)
   end
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
      puts "\nError in ddcListener::checkModuleIntegrity :-(\n\n"
      exit(99)
   end                             
end
#-------------------------------------------------------------

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -54 #{fullpathFile}"}`
      
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
