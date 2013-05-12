#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to extract data from the wsStation
#
# == Usage
#  triggerMeteoData.rb
#     --help                shows this help
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


require 'getoptlong'
require 'rdoc/usage'

require 'cuc/CheckerProcessUniqueness'

# MAIN script function
def main
   @locker        = nil
   @isDebugMode   = false
   @bForce        = false

   opts = GetoptLong.new(
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt     
            when "--Debug"   then @isDebugMode = true
            when "--Force"   then @bForce = true
            when "--version" then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--usage"   then RDoc::usage("usage")
            when "--help"    then RDoc::usage                         
         end
      end
   rescue Exception
      exit(99)
   end

   init

   time           = Time.now
   now            = time.strftime("%Y%m%dT%H%M%S")
   meteoFilename  = %Q{METEO_CASALE_#{now}.xml}


   prevDir     = Dir.pwd
   toolsDir    = ENV['METEO_TOOLS']
   archiveDir  = ENV['METEO_ARCHIVE']
   
   Dir.chdir(toolsDir)

   cmd = "./xml2300 #{meteoFilename}"

   if @isDebugMode == true then
      puts
      puts Time.now
      puts
      cmd = "time #{cmd}"
      puts cmd
   end
   
   system(cmd)

   cmd = "verifyMeteoData.rb -f #{meteoFilename}"

   if @isDebugMode == true then
      puts
      puts Time.now
      puts
      cmd = "time #{cmd}"
      puts cmd
   end

   retVal = system(cmd)

   if retVal == false then
      puts "Error in #{meteoFilename}"
      cmd = "\\cp #{meteoFilename} ../data/archive/xml"
      system(cmd)
 
      cmd = "\\mv #{meteoFilename} ../data/archive/error"
      system(cmd)
      exit(99)
   end

   cmd = "cp #{meteoFilename} METEO_CASALE.xml"
   system(cmd)

   cmd = "\\cp -f METEO_CASALE.xml ../data/outbox/METEO"
   system(cmd)

   # -----------------------------------
   # Archive new file
   cmd = "minArcStore.rb -f #{Dir.pwd}/#{meteoFilename} -t METEO_DAILY_XML"

   if @isDebugMode == true then
      puts
      puts cmd
      puts
   end
   ret = system(cmd)
   # -----------------------------------


   cmd = "\\mv METEO_CASALE* ../data/archive/xml"
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
   @locker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true) 
   if @locker.isRunning == true and @bForce == false then
      puts "\n#{File.basename($0)} is already running !\n\n"
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
      cmd = "killall xml2300"
      if @isDebugMode == true then
         puts
         puts cmd
         puts
      end
      system(cmd)
   end


   oldProcess = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true) 

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


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================

