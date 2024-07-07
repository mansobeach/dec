#!/usr/bin/env ruby

# == Synopsis
#
# This is a Minarc command line tool that manages the Minarc Cleanup Deamon.
# Clean-up tasks are specified in the configuration file minarc_config.xml
# MINARC configuration file is placed in $MINARC_CONFIG directory.
#
# Clean-up rules are specified in the configuration file.
# + Filetype
# + Rule      : Older | Newer
# + Date      : validity_start | validity_stop | archive_date | last_access_date
# + Age       : time value
# + Unit      : s - seconds | d - days
#
# == Usage
# minArcCleanup.rb  --start --frequency <seconds> | --stop 
#     --start               starts the cleanup deamon
#     --stop                kills the cleanup deamon
#     --frequency <seconds>
#     --list                Activates the list-only mode
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --version             shows version number      
# 
#


# MinArc Deamon that removes obsolete files from the archive


require 'getoptlong'
require 'rdoc'

require 'cuc/Listener'
require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'cuc/CheckerProcessUniqueness'
require 'cuc/CommandLauncher'

require 'arc/ReadMinarcConfig'
require 'arc/MINARC_DatabaseModel'

# Global variables
@dateLastModification = "$Date$"   


# MAIN script function
def main

   include CUC::DirUtils
   include CUC::CommandLauncher

   @listOnly            = false
   @isDebugMode         = false
   @action              = nil
   @id                  = nil

   showVersion = false

   @intervalSeconds    = 0
   
   opts = GetoptLong.new(
      ["--start", "-s",          GetoptLong::NO_ARGUMENT],
      ["--stop",                 GetoptLong::NO_ARGUMENT],
      ["--frequency", "-f",      GetoptLong::REQUIRED_ARGUMENT],
      ["--list", "-l",           GetoptLong::NO_ARGUMENT],
      ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
      ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
      ["--version", "-v",        GetoptLong::NO_ARGUMENT],
      ["--help", "-h",           GetoptLong::NO_ARGUMENT]
      )

   begin
      opts.each do |opt, arg|
         case opt
            when "--Debug"       then @isDebugMode = true
            when "--version"     then showVersion = true         
            when "--help"        then usage
	         when "--start"       then @action = "start"
	         when "--stop"        then @action = "stop"
	         when "--list"        then @listOnly = true
            when "--frequency"   then @id = arg.to_i
            when "--usage"       then usage
         end
      end
   rescue Exception
      exit(99)
   end 

   if showVersion then 
      if File.exist?("#{ENV['MINARC_BASE']}/bin/minarc/version.txt") then
         aFile = File.new("#{ENV['MINARC_BASE']}/bin/minarc/version.txt")
      else
         puts "version.txt is not present !"
         exit(99)
      end

      binVersion = aFile.gets.chomp

      puts
      puts "Mini-Archive Component - Version #{binVersion}"
      puts

      aFile.close
      exit(0)
   end

   # -----------------
   # initialize logger
   loggerFactory = CUC::Log4rLoggerFactory.new("minArcCleanup", "#{ENV['MINARC_CONFIG']}/minarc_log_config.xml")
   if @isDebugMode then
      loggerFactory.setDebugMode
   end
   @logger = loggerFactory.getLogger
   if @logger == nil then
      puts
		puts "Error in minArcCleanup::main"
		puts "Could not set up logging system !  :-("
      puts "Check MINARC logs configuration under \"#{ENV['MINARC_CONFIG']}/minarc_log_config.xml\"" 
	   puts
		puts
		exit(99)
   end

   if @action == nil
      puts
      puts "No action defined, please specify --start or --stop"
      puts
      usage
      exit(0)
   elsif @action == "start" and @id != nil

      @intervalSeconds = @id

      #Create our lovely listener and start it.
      listener = CUC::Listener.new(File.basename($0), "Clean_#{@intervalSeconds}", @intervalSeconds, self.method("clean").to_proc)

      if @isDebugMode == true
         listener.setDebugMode
      end
		   
      #start server
      listener.run

   elsif @action == "start"
      # load Configuration
      confReader = ARC::ReadMinarcConfig.instance
      arrFreqs = confReader.getFrequencies

      listStr = ""
      if @listOnly then
         listStr = "--list"
      end
      
      arrFreqs.each{|freq|

         if @isDebugMode == true then
            command  = %Q{minArcCleanup.rb --start --frequency #{freq} -D #{listStr}}
         else
            command  = %Q{minArcCleanup.rb --start --frequency #{freq} #{listStr}}
         end

         #---------------------------------------------
         # Create a new process for each Entity
         pid = fork {
            Process.setpriority(Process::PRIO_PROCESS, 0, 1)
            if @isDebugMode == true then
               puts command
            end

            @logger.info("Starting minarc cleanup deamon 'Clean_#{freq}'")

            retVal = execute(command, "minArcCleanup")

            if retVal == true then
      		   exit(0)
            else
      		   puts "Error launching deamon for frequency #{freq} :-("
               @logger.error("Failed to launch minarc cleanup deamon 'Clean_#{freq}'")
               exit(99)
            end            
         }
         #---------------------------------------------
      }
   elsif @id != nil
      checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "Clean_#{@id}", true)
      pid     = checker.getRunningPID
      if pid == false then
         puts "The deamon Clean_#{@id} was not running !"
         @logger.warn("There was an attempt to stop cleanup deamon 'Clean_#{@id}' that was not running !")
      else
         puts "Sending signal SIGKILL to Process #{pid} for killing 'Clean_#{@id}' deamon"
         Process.kill(9, pid.to_i)
   	   checker.release
         @logger.info("Killed minarc cleanup deamon 'Clean_#{@id}' (pid #{pid})")
      end
   else
      # load Configuration
      confReader = ARC::ReadMinarcConfig.instance
      arrFreqs = confReader.getFrequencies
      
      arrFreqs.each{|freq|

         checker = CUC::CheckerProcessUniqueness.new(File.basename($0), "Clean_#{freq}", true)
         pid     = checker.getRunningPID
         if pid == false then
            puts "The deamon Clean_#{freq} was not running !"
            @logger.warn("There was an attempt to stop cleanup deamon 'Clean_#{freq}' that was not running !")
         else
            puts "Sending signal SIGKILL to Process #{pid} for killing Clean_#{freq} deamon"
            Process.kill(9, pid.to_i)
   	      checker.release
            @logger.info("Killed minarc cleanup deamon 'Clean_#{freq}' (pid #{pid})")
         end
      }
   end


      
end
#-------------------------------------------------------------

def clean
   startTime = Time.new
   startTime.utc 

   @logger.debug("Polling minarc cleanup operation")

   # load Configuration
   confReader = ARC::ReadMinarcConfig.instance
   rules = confReader.getAllRules
   
   #-------------------###

   rules.each{|ru|
      operator = nil
      dateUsed = nil
      calculedDate = nil

      arrFiles = Array.new
      arrToDel = Array.new

      if ru[:frequency] == @intervalSeconds then
         case ru[:rule]
            when "Older" then operator = "<"
            when "Newer" then operator = ">"
         end
         if operator == nil then next end

         if ru[:date] != nil and ru[:date] != "" then
            dateUsed = ru[:date].upcase
         else
            next
         end

         if ru[:age] > 0 then
            calculedDate = Time.at(Time.new.to_i - ru[:age]).strftime("%Y-%m-%d").upcase
         else
            next
         end

         arrFiles = ArchivedFile.find(:all, :conditions => [ "filetype = :filetype AND #{dateUsed} #{operator} :date",{
            :filetype => ru[:filetype], :date => calculedDate 
         } ])

         if @isDebugMode then
            puts
            puts "------MINARC CLEANUP DEAMON------"
            puts "Looking for files matching :"
            puts "FileType : #{ru[:filetype]}"
            puts "Constraint : #{dateUsed} #{operator} #{calculedDate}"
            puts 
            puts "Found #{arrFiles.length} results"
            puts "---------------------------------"
            puts
         end

         listStr = ""
         if @listOnly then
            listStr = "--list"
         end

         @logger.debug("#{arrFiles.length} file(s) from type '#{ru[:filetype]}' matched the rule '#{dateUsed} #{operator} #{calculedDate}'")


         arrFiles.each{|aFile|

            if @isDebugMode == true then
               cmd = %Q{minArcDelete.rb --file #{aFile.filename} -D #{listStr}}
               puts
               puts cmd
               puts
            else
               cmd = %Q{minArcDelete.rb --file #{aFile.filename} #{listStr}}
            end

            retVal = execute(cmd, "minArcDelete")
            if !retVal then
               puts
      		   puts "Error executing minArcDelete !"
               puts "Command was : #{cmd}"
               puts
               @logger.error("#{aFile.filename} could not be removed from the archive : minArcDelete failed !")
            else
               if !@listOnly then
                  @logger.info("#{aFile.filename} was removed from the archive")
               end
            end
         }

      end
   }

   @logger.debug("End of cleanup")

   #-------------------###

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

#-------------------------------------------------------------

def usage
   fullpathFile = `which #{File.basename($0)}` 
   system("head -24 #{fullpathFile}")
   exit
end

#-------------------------------------------------------------

#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
