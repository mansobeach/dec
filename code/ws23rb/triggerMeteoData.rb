#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to extract data from the wsStation
#
# == Usage
#  triggerMeteoData.rb [-H]
#     --help                shows this help
#     --Historic            generates Historic XML file 
#     --Debug               shows Debug info during the execution
#     --Force               forces a new execution
#     --version             shows version number      
# 
# == Author
# Borja Lopez Fernandez
#
# == Copyright
# Casale Beach


#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#
#########################################################################


require 'optparse'
require 'getoptlong'
require 'timeout'

require 'cuc/CheckerProcessUniqueness'
require 'cuc/Log4rLoggerFactory'
require 'ctc/ReadInterfaceConfig'

# MAIN script function
def main
   @locker        = nil
   @isDebugMode   = false
   @bForce        = false
   @bVerify       = false
   @bHistoric     = false

   opts = GetoptLong.new(
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",          GetoptLong::NO_ARGUMENT],
     ["--Historic", "-H",       GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--Verify", "-V",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt
            when "--Debug"       then @isDebugMode = true
            when "--Historic"    then @bHistoric   = true
            when "--Force"       then @bForce      = true
            when "--Verify"      then @bVerify     = true
            when "--version" then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--usage"   then usage
            when "--help"    then usage                 
         end
      end
   rescue Exception
      exit(99)
   end

   init

#    # initialize logger
#    loggerFactory = CUC::Log4rLoggerFactory.new("triggerMeteoData", "#{ENV['METEO_CONFIG']}/dec_log_config.xml")
#    if @isDebugMode then
#       loggerFactory.setDebugMode
#    end
#    @logger = loggerFactory.getLogger
#    if @logger == nil then
#       puts
# 	   puts "Error in triggerMeteoData::main"
# 		puts "Could not set up logging system !  :-("
#       puts "Check logs configuration under \"#{ENV['METEO_CONFIG']}/dec_log_config.xml\"" 
# 		puts
# 		puts
# 		exit(99)
#    end

   prevDir        = Dir.pwd
   toolsDir       = ENV['METEO_TOOLS']
#   archiveDir     = ENV['METEO_ARCHIVE']
#   cnfDir         = ENV['METEO_CONFIG']
   stationName    = ENV['METEO_STATION']
   interfaceName  = "METEO_#{stationName}"

   # -----------------------------------
   # outgoing folder
   #
   @ftReadConf  = CTC::ReadInterfaceConfig.instance
   @outboxDir   = @ftReadConf.getOutgoingDir(interfaceName)
   @outboxDir   = "#{@outboxDir}/ftp"
   
#    puts @outboxDir
#    exit
   
   #
   # -----------------------------------

   time           = Time.now
   now            = time.strftime("%Y%m%dT%H%M%S")   
   meteoFilename  = %Q{METEO_#{stationName}_#{now}.xml}

   Dir.chdir(toolsDir)

   cmd = "triggerRTMeteoData.rb -a -F #{meteoFilename}"

   if @bHistoric == true then
      meteoFilename = %Q{METEO_HISTORIC_#{stationName}_#{now}.xml}
      cmd = "./xml2300 #{meteoFilename}"
   end

   # @logger.debug(cmd)
  
   if @isDebugMode == true then
      cmd = "#{cmd} -D"
      puts
      puts Time.now
      puts
      # cmd = "time #{cmd}"
      puts cmd
   end

   # -------------------------------------------------------
   
   # 20160611 Patch to restart if timeout arises
   
   begin
      Timeout.timeout(100) do
         system(cmd)
      end
   rescue Timeout::Error
      puts
      puts "Timeout when polling weather station"
      puts
      cmd = "sudo reboot"
      puts cmd
      system(cmd)
      exit(99)
   end

   # -------------------------------------------------------

   if @bVerify == true then
      cmd = "verifyMeteoData.rb -f #{meteoFilename}"

      if @isDebugMode == true then
         cmd = "#{cmd} -D"
      end

      # @logger.debug(cmd)

      if @isDebugMode == true then
         puts
         puts Time.now
         puts
         # cmd = "time #{cmd}"
         puts cmd
      end

      retVal = system(cmd)

      if retVal == false then
         puts "Error in #{meteoFilename}"
         # @logger.error("Error in #{meteoFilename}")
 
         cmd = "\\cp #{meteoFilename} ../data/archive/xml"
         system(cmd)
 
         cmd = "\\mv #{meteoFilename} ../data/archive/error"
         system(cmd)
         exit(99)
      end
   end

#   cmd = "cp #{meteoFilename} METEO_#{stationName}.xml"
   cmd = "mv #{meteoFilename} METEO_#{stationName}.xml"

   if @bHistoric == true then
      cmd = "cp #{meteoFilename} METEO_HISTORIC.xml"
   end

   system(cmd)

   # ---------------------------------------------------------------------
   #
   # To be replaced by configuration directory specified in interfaces.xml
   #
   
   # cmd = "\\cp -f METEO_#{stationName}.xml ../data/outtray/ftp"

   cmd = "\\mv -f METEO_#{stationName}.xml #{@outboxDir}"

   if @bHistoric == true then
      cmd = "\\cp -f METEO_HISTORIC.xml ../data/outbox/METEO"
   end

   # @logger.debug(cmd)
   system(cmd)

   cmd = "send2Interface.rb -m METEO_#{stationName} --nodb"
   puts cmd
   system(cmd)

   exit(0)

   # -----------------------------------
   # Archive new file
   cmd = "minArcStore.rb -f #{Dir.pwd}/#{meteoFilename} -t METEO_DAILY_XML"

   if @bHistoric == true then
      cmd = "minArcStore.rb -f #{Dir.pwd}/#{meteoFilename} -t METEO_HISTORIC_XML"
   end

   if @isDebugMode == true then
      puts
      puts cmd
      puts
   end
   ret = system(cmd)
   # -----------------------------------

   exit(0)

   cmd = "\\mv METEO_#{stationName}* ../data/archive/xml"

   if @bHistoric == true then
      cmd = "\\mv METEO_HISTORIC* ../data/archive/xml"
   end

   system(cmd)

   Dir.chdir(prevDir)

   if @isDebugMode == true then
      puts
      puts Time.now
      puts
   end

   @locker.release
   exit(0)

end
#---------------------------------------------------------------------

# It sets up the process.
# The process is registered and checked with #CheckerProcessUniqueness
# class.
def init
   
   return

   param = ""

   cmd = "triggerRTMeteoData.rb"
   
   if @bHistoric == true
      cmd = "xml2300"
   end

   if @bHistoric == true then
      param = "-H"
   end

   @locker = CUC::CheckerProcessUniqueness.new(cmd, param, true) 
   if @locker.isRunning == true and @bForce == false then
      puts "\n#{cmd} is already running !\n\n"
      exit(99)
   end

   if @locker.isRunning == true and @bForce == true then
      puts
      puts "Killing previous execution - #{@locker.getRunningPID}"
      puts
      @locker.kill
      puts "\nRe-starting #{File.basename($0)}\n"
      sleep(2)
   end
   

   if @bForce == true then
      cmd = "killall #{cmd}"
      if @isDebugMode == true then
         puts
         puts cmd
         puts
      end
      system(cmd)
   end


   oldProcess = CUC::CheckerProcessUniqueness.new(cmd, param, true) 

   if @isDebugMode == true then
      oldProcess.setDebugMode
   end

   arrPids = oldProcess.getAllRunningProcesses("daemonME.rb")

   myPid       = Process.pid

   arrPids.each{|pid|

      if myPid == pid.to_i then
         next
      end

      if @isDebugMode == true then
         puts "Killing process #{pid}"
      end
      begin  
         Process.kill(9, pid.to_i)
      rescue Exception => e
         puts e.to_s
      end
      sleep(1)
   }


   registerSignals

   @locker.setRunning
end
#-------------------------------------------------------------

#-------------------------------------------------------------

# Register Signals
def registerSignals
   
   trap("SIGHUP") {  
                     puts "Hello ... [#{File.basename($0)}]\n"
                     killEmAll
                  }
   
   trap("USR1")   {  
                     puts "\nSignal SIGUSR2 received ...\n"
                  }
      
   trap("USR2")   {  
                     puts "\nSignal SIGUSR2 received ...\n"
                  }
      
   trap("SIGTSTP"){  
                     puts "\nSignal SIGTSTP received ...\n"
                  }
      
   trap("CONT")   {  
                     puts "\nSignal SIGCONT received ...\n"
                        
                  }
    
#       trap("CLD")    {  
#                         puts "\nSignal SIGCHILD received :-)...\n"
#                         processSIGCHILD
#                      }
   
   trap("INT")    {  
                     puts "\nSayonara Baby ... [#{File.basename($0)}]\n"
                     killEmAll
                  }
      
end
#-------------------------------------------------------------

#-------------------------------------------------------------

def usage
   fullpathFile = `which #{File.basename($0)}` 
   system("head -20 #{fullpathFile}")
   exit
end

#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================

