#!/usr/bin/env ruby


# == Synopsis
#
# This is the command line tool to start the meteo Casale
#
# == Usage
#  startMeteoCasale.rb
#     --help                shows this help
#     --start               it 
#     --Debug               shows Debug info during the execution
#     --Force               forces a new execution
#     --version             shows version number      
# 
# == Author
# Borja Lopez Fernandez
#
# == Copyright
# Casale Beach


require 'getoptlong'
require 'rdoc/usage'

require 'cuc/CheckerProcessUniqueness'

# MAIN script function
def main
   @locker        = nil
   @isDebugMode   = false
   @bForce        = false
   @bStart        = false
   @bStop         = false

   opts = GetoptLong.new(
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--start", "-s",          GetoptLong::NO_ARGUMENT],
     ["--kill", "-k",           GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt     
            when "--Debug"   then @isDebugMode = true
            when "--Force"   then @bForce = true
            when "--start"   then @bStart = true
            when "--kill"   then  @bStop = true
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

   if @bStart == false and @bStop == false then
      RDoc::usage("usage")
   end  

   if @bStart == true and @bStop == true then
      RDoc::usage("usage")
   end  

   init

   if @bStart == true then
      startMeteoCasale
   end

   if @bStop == true then
      stopMeteoCasale
   end


   @locker.release
   exit(0)

end
#---------------------------------------------------------------------

def startMeteoCasale
   
   # -------------------------------------------------------

   cmd = "daemonME.rb -m \"triggerMeteoData.rb -D\" -i 20"
   cmd = "daemonME.rb -D -m \"getHttpMeteoFile2.rb -D\" -i 20"

   if @isDebugMode == true then
  #    cmd = "#{cmd} -D"
      puts cmd
      puts
   end

   system(cmd)

   sleep(1)
   # -------------------------------------------------------

#    cmd = "daemonME.rb -m \"triggerMeteoData.rb -H -D\" -i 600 -D"
# 
#    if @isDebugMode == true then
#       cmd = "#{cmd} -D"
#       puts cmd
#       puts
#    end
# 
#    system(cmd)

   # -------------------------------------------------------

#    cmd = "daemonME.rb -i 50 -m \"ddcDeliverFiles.rb\" "
# 
#    if @isDebugMode == true then
#       cmd = "#{cmd} -D"
#       puts cmd
#       puts
#    end
# 
#    system(cmd)

   # -------------------------------------------------------

   cmd = "daemonME.rb -F -i 600 -m \"genDailyMeteoFile2.rb -F\" -D"

#    if @isDebugMode == true then
#       cmd = "#{cmd} -D"
#       puts cmd
#       puts
#    end

   system(cmd)

   sleep(1)
   # -------------------------------------------------------

   cmd = "daemonME.rb -F -i 00:10,86400 -m \"genYesterdayMeteoFiles2.rb\" -D"

    if @isDebugMode == true then
       cmd = "#{cmd} -D"
       puts cmd
       puts
    end

   system(cmd)

   sleep(1)
   # -------------------------------------------------------

   cmd = "daemonME.rb -F -i 01:00,86400 -m \"genMonthlyStats.rb\" -D"

   if @isDebugMode == true then
      cmd = "#{cmd} -D"
      puts cmd
      puts
   end

   system(cmd)

   sleep(1)

end
#---------------------------------------------------------------------

def stopMeteoCasale
   cmd = "daemonME.rb -s \"triggerMeteoData.rb -H -D\" "
   system(cmd)

   cmd = "daemonME.rb -s \"triggerMeteoData.rb -D\" "
   system(cmd)

   cmd = "daemonME.rb -s ddcDeliverFiles.rb"
   system(cmd)

   cmd = "daemonME.rb -s genDailyMeteoFile.rb"
   system(cmd)

   cmd = "daemonME.rb -s genMonthlyStats.rb"
   system(cmd)

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
      puts "\nRe-starting #{File.basename($0)}\n"
      sleep(2)
   end
   
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
                    
                  }
      
end
#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================

