#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to generate the daily meteo files

# == Usage
#  getMonthlyStats.rb
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --Force               force mode
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
   @isForceMode   = false

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
            when "--Force"   then @isForceMode = true
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

   if @isForceMode == true then
      killEmAll
   end

   sleep(2)

   time           = Time.now
   now            = time.strftime("%Y%m%dT%H%M%S")
   year           = time.strftime("%Y")
   month          = time.strftime("%m")
   day            = time.strftime("%d")

   currentDay     = time.strftime("%Y%m%d")
   
   # If first day of the month, rewind one day
   if day.to_i == 1 then
      puts "First day of the month !"
      currentDay = "#{year}#{(month.to_i-1).to_s.rjust(2, "0")}31"
   end

   excelFilename  = %Q{#{currentDay.slice(0,6)}_stats_temperature_outdoor.xls}

   chartFilename  = %Q{METEO_STATS_#{currentDay.slice(0,6)}_temperature_outdoor.png}

   prevDir     = Dir.pwd
   toolsDir    = ENV['METEO_TOOLS']
   archiveDir  = ENV['METEO_ARCHIVE']
   outboxDir   = ENV['METEO_OUTBOX']
   
   Dir.chdir(archiveDir)

   Dir.chdir("excel")

   # -------------------------------------------------------
   # Generate Excel File

   cmd = "extractMeteoData.rb  -t #{currentDay.slice(0,6)} -p temperature_outdoor -e $PWD/#{excelFilename} -D"
   puts cmd

   system(cmd)

   # -------------------------------------------------------
   # Generate Chart File

   cmd = "excel2Chart.rb -e $PWD/#{excelFilename} -f #{chartFilename} -D"
   puts cmd

   system(cmd)

   # -------------------------------------------------------

   # -------------------------------------------------------

   # Copy Chart Files to Outbox

   cmd = "\\cp -f #{chartFilename} #{outboxDir}"
   
   if @isDebugMode == true then
      puts cmd
      puts
   end

   system(cmd)

   # -------------------------------------------------------

   # Move Chart File to charts

   cmd = "\\mv -f #{chartFilename} ../charts/monthly"
   
   if @isDebugMode == true then
      puts cmd
      puts
   end

   system(cmd)

   # -------------------------------------------------------

   # Copy monthly file

   cmd = "\\cp -f #{excelFilename} ../excel/monthly"
   
   if @isDebugMode == true then
      puts cmd
      puts
   end

   system(cmd)

   # -------------------------------------------------------

   Dir.chdir(prevDir)


   @locker.release
   exit(0)

end
#---------------------------------------------------------------------

# It sets up the process.
# The process is registered and checked with #CheckerProcessUniqueness
# class.
def init  
   @locker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true) 
   if @locker.isRunning == true then
      puts "\n#{File.basename($0)} is already running !\n\n"
      #exit(99)
   end

   registerSignals

   @locker.setRunning
end
#-------------------------------------------------------------
def killEmAll

   if @isDebugMode == true then
      puts "Force flag enabled: killing previous processes"
   end


   # KILL MY OLD MYSELVES

   oldProcess = CUC::CheckerProcessUniqueness.new("excel2Chart.rb", "", true) 

   oldProcess.setDebugMode

   arrPids = oldProcess.getAllRunningProcesses

   arrPids.each{|pid|
      if pid.to_s.length < 4 then
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

#    oldProcess = CUC::CheckerProcessUniqueness.new("reProcessAllMeteoFiles.rb", "", true) 
# 
#    if @isDebugMode == true then
#       oldProcess.setDebugMode
#    end
# 
#    arrPids = oldProcess.getAllRunningProcesses
# 
#    arrPids.each{|pid|
#       if pid.to_s.length < 4 then
#          next
#       end
#       if @isDebugMode == true then
#          puts "Killing process #{pid}"
#       end      
#       begin  
#          Process.kill(9, pid.to_i)
#       rescue Exception => e
#          puts e.to_s
#       end
#       sleep(1)
#    }

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

