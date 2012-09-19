#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to generate the daily meteo files

# == Usage
#  getDailyMeteoFile.rb
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
   currentDay     = time.strftime("%Y%m%d")

   meteoFilename  = %Q{EXCEL_METEO_CASALE_#{currentDay}.xls}
   meteoVFilename = %Q{EXCEL_METEO_CASALE_V_#{currentDay}.xls}

   prefixImage    = %Q{METEO_CASALE_#{currentDay}_}

   prevDir     = Dir.pwd
   toolsDir    = ENV['METEO_TOOLS']
   archiveDir  = ENV['METEO_ARCHIVE']
   outboxDir   = ENV['METEO_OUTBOX']
   
   Dir.chdir(archiveDir)

   Dir.chdir("xml")

   # -------------------------------------------------------
   # Generate Excel File

   cmd = "reProcessAllMeteoFiles.rb  -V -d $PWD -P METEO_CASALE*#{currentDay}"
   cmd = "#{cmd} -p date,time,temperature_outdoor,pressure,humidity_outdoor,dewpoint,rain_1hour,wind_speed,wind_direction,temperature_indoor"
   cmd = "#{cmd} -e #{meteoFilename}"

   if @isDebugMode == true then
      cmd = "#{cmd} -D"
      puts cmd
   else
      cmd = "#{cmd} -S"
   end

   regProcess = CUC::CheckerProcessUniqueness.new("reProcessAllMeteoFiles.rb", "DAILY", true) 

   # Change to IO.popen to be able to retrieve the PID

   ret = system(cmd)

   # regProcess.setExternalProcessRunning(pid)


   if ret == false then
      puts
      puts "Failed to reprocess meteo files for date #{currentDay}"
      puts
      regProcess.release
      exit(1)
   end

   # -------------------------------------------------------
   # Verify Excel File

   cmd = "verifyMeteoExcel.rb -s #{meteoFilename} -t #{meteoVFilename}"

   if @isDebugMode == true then
      cmd = "#{cmd} -D"
      puts cmd
      puts
   end

   system(cmd)

   # -------------------------------------------------------


   if File.exist?(meteoVFilename) == true then
      cmd = "excel2Chart.rb -e #{meteoVFilename} -p #{prefixImage}"
   else
      cmd = "excel2Chart.rb -e EXCEL_METEO_CASALE_#{currentDay}.xls -p #{prefixImage}"
   end

   # cmd = "excel2Chart.rb -e EXCEL_METEO_CASALE_#{currentDay}.xls -p #{prefixImage}"

   if @isDebugMode == true then
      cmd = "#{cmd} -D"
      puts cmd
      puts
   end

   system(cmd)

   # -------------------------------------------------------

   # Move Excel File to Outbox

   cmd = "\\mv -f #{meteoFilename} ../excel"
   
   if @isDebugMode == true then
      puts cmd
      puts
   end

   system(cmd)

   if File.exist?(meteoVFilename) == true then

      cmd = "\\mv -f #{meteoVFilename} ../excel"
   
      if @isDebugMode == true then
         puts cmd
         puts
      end

      system(cmd)
   end
   # -------------------------------------------------------

   # Duplicate files with name METEO_TODAY

   arrFiles = Dir["#{prefixImage}*.png"]

   arrFiles.each{|aFile|
      sufix = aFile.split(prefixImage)[-1]
      newFile = %Q{METEO_CASALE_TODAY_#{sufix}}

      cmd = "\\cp -f #{aFile}  #{newFile}"
   
      if @isDebugMode == true then
         puts cmd
         puts
      end

      system(cmd)

      cmd = "\\mv -f #{newFile}  #{outboxDir}"
   
      if @isDebugMode == true then
         puts cmd
         puts
      end

      system(cmd)

      cmd = "\\mv -f #{aFile} ../charts/daily"
   
      if @isDebugMode == true then
         puts cmd
         puts
      end

      system(cmd)

   }


   # -------------------------------------------------------

   # Move Chart Files to Outbox

   cmd = "\\mv -f #{prefixImage}*.png  #{outboxDir}"
   
   if @isDebugMode == true then
      puts cmd
      puts
   end

  # system(cmd)

   # -------------------------------------------------------

   # Remove Yesterday Files

   removePrevDayFiles

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

def removePrevDayFiles
   puts
   puts "Removing files generated yesterday"
   puts
   time           = Time.now
   time           = time - 86400
   yesterdayFile  = time.strftime("%Y%m%d")
   prefixFile     = %Q{METEO_CASALE_#{yesterdayFile}}

   cmd = "rm -rf #{prefixFile}*"
   system(cmd)

   prevDir = Dir.pwd

   Dir.chdir("../excel")

   prefixFile     = %Q{EXCEL_METEO_CASALE_V_#{yesterdayFile}}

   arr = Dir["#{prefixFile}*"]

   arr.each{|aFile|
   
      cmd = "minArcStore.rb -f #{Dir.pwd}/#{aFile} -t METEO_DAILY_V_XLS -d"

      if @isDebugMode == true then
         puts cmd
         puts
      end
      system(cmd)
   }

   Dir.chdir(prevDir)

   return

   arr = Dir["#{prefixFile}*"]

   arr.each{|aFile|
   
      cmd = "minArcStore.rb -f #{Dir.pwd}/#{aFile} -t METEO_DAILY_XML -d"

      if @isDebugMode == true then
         puts cmd
         puts
      end
      system(cmd)
   }




end
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

