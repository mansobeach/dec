#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to generate the daily meteo files

# == Usage
#  getYesterdayMeteoFiles.rb
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
require 'cuc/DirUtils'

# MAIN script function
def main

   include CUC::DirUtils

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
   time           = time - 86400
   currentDay     = time.strftime("%Y%m%d")

   stationName    = "CASALE"
   meteoFilename  = %Q{DAILY_RAW_#{stationName}_#{currentDay}.xls}
   meteoVFilename = %Q{DAILY_CORRECTED_#{stationName}_#{currentDay}.xls}
   prefixImage    = %Q{DAILY_#{stationName}_#{currentDay}_}

   prevDir     = Dir.pwd
   toolsDir    = ENV['METEO_TOOLS']
   archiveDir  = ENV['METEO_ARCHIVE']
   tempDir     = ENV['METEO_TEMP']
#   outboxDir   = ENV['METEO_OUTBOX']
   outboxDir   = "#{ENV['METEO_BASE']}/data/outtray/ftp"
   minArcDir   = ENV['MINARC_ARCHIVE_ROOT']


   currentTime = Time.new
   currentTime.utc
   str  = currentTime.strftime("%Y%m%d_%H%M%S")
                                      
   tempDir = %Q{#{ENV['METEO_TEMP']}/.#{str}_#{stationName}_YESTERDAY_CONSO}  

   checkDirectory(tempDir)

   Dir.chdir(minArcDir)
   Dir.chdir("REALTIME_XML")
   Dir.chdir(stationName)

   begin
      Dir.chdir(time.strftime("%Y"))
      Dir.chdir(time.strftime("%m"))
      Dir.chdir(time.strftime("%d"))
   rescue Exception => e
      # puts e.to_s
      puts
      puts "No REALTIME_XML Files for #{stationName} were archived yesterday"
      puts
      exit(99)
   end


   Dir.chdir(tempDir)

   cmd = "rm -f DAILY*.png" 
   system(cmd)


  path = "#{minArcDir}/REALTIME_XML/#{stationName}/#{time.strftime("%Y")}/#{time.strftime("%m")}/#{time.strftime("%d")}"


   # -------------------------------------------------------
   # Generate Excel File

   cmd = "reProcessAllMeteoFiles.rb  -V -d #{path} -P REALTIME_#{stationName}*#{currentDay}*"
   cmd = "#{cmd} -p date,time,temperature_outdoor,pressure,humidity_outdoor,dewpoint,rain_1hour,wind_speed,wind_direction,temperature_indoor"
   cmd = "#{cmd} -e #{meteoFilename}"


   if @isDebugMode == true then
      cmd = "#{cmd} -D"
      puts cmd
   else
      cmd = "#{cmd} -S"
      puts cmd
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
   else
      puts cmd
   end

   system(cmd)

   # -------------------------------------------------------


   if File.exist?(meteoVFilename) == true then
      cmd = "excel2Chart2.rb -e #{meteoVFilename} -p #{prefixImage}"
   else
      cmd = "excel2Chart2.rb -e EXCEL_METEO_CASALE_#{currentDay}.xls -p #{prefixImage}"
   end

   # cmd = "excel2Chart2.rb -e EXCEL_METEO_CASALE_#{currentDay}.xls -p #{prefixImage}"

   if @isDebugMode == true then
      cmd = "#{cmd} -D"
      puts cmd
      puts
   else
      puts cmd
   end

   system(cmd)

   # -------------------------------------------------------

   # Archive Daily Excel Sheets
   currDir = Dir.pwd


   cmd = "minArcStore2.rb -f #{currDir}/#{meteoFilename} -d -u -t DAILY_RAW_XLS"

   if @isDebugMode == true then
      cmd = "#{cmd} -D"
      puts cmd
      puts
   end

   system(cmd)

   if File.exist?(meteoVFilename) == true then

      cmd = "minArcStore2.rb -f #{currDir}/#{meteoVFilename} -d -u -t DAILY_CORRECTED_XLS"
   
      if @isDebugMode == true then
         cmd = "#{cmd} -D"
         puts cmd
         puts
      end

      system(cmd)
   end

   # -------------------------------------------------------

   # Archive Chart files

   arrFiles = Dir["DAILY_*#{stationName}_*.png"]

   arrFiles.each{|aFile|

      vble        = aFile.split(prefixImage)[-1].gsub("_","-").upcase.split(".")[0]      
      newFile     = %Q{DAILY_#{vble}_#{stationName}_#{currentDay}.png}
      
      cmd = "\\mv -f #{aFile}  #{newFile}"
   
      if @isDebugMode == true then
         puts aFile
         puts cmd
         puts
      end

      system(cmd)

      cmd = "minArcStore2.rb -f #{currDir}/#{newFile} -d -u -t DAILY_VARIABLE_PNG"
   
      if @isDebugMode == true then
         cmd = "#{cmd} -D"
         puts cmd
         puts
      end

      system(cmd)

   }


   # -------------------------------------------------------

   # Remove temporal directory

   Dir.chdir(prevDir)

   cmd = %Q{\\rm -rf #{tempDir} }
      
   if @isDebugMode == true then
      puts "\nRemoving #{tempDir} ..."
      puts cmd
   end
      
   system(cmd)

   # -------------------------------------------------------

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

