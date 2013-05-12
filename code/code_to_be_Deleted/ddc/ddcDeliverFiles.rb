#!/usr/bin/env ruby


# == Synopsis
#
# This is a DDC command line tool that delivers all files from a given repository.
# The file repository is pointed by the DDC_ARCHIVE_ROOT environment variable.
# 
# This command can be used in order to send a given file just once 
# (for each delivery method: ftp, email) for a given Interface. 
# Use "-O" flag to enable this behaviour.
#
# -O flag:
# The "ONCE" flag registers in the Inventory all the files sent. As well it checks
# prior to the delivery whether a files has been previously sent or not to avoid 
# delivering it twice to the same Interface.
#
# -N flag:
# The "NOARCHIVE" flag skips the file(s) retrieval from Archive step.
# It may be useful for some deliveries retries in case of previous errors when
# no additional files are desired.
# As well when "external" processes using this command configure by themselves the
# files to be delivered.
#
# -p flag:
# The "params" flag allows when registering in the database, fill up some fields
# with the values specified.
#
# -R flag:
# The Report flag creates a Report with all files transferred to a given I/F.
#
# -K flag:      
# The Kill flag cancels an on-going delivery. It sends SIGTERM signal to all
# existing send2Interface.rb processes running.
#
#
# == Usage
# ddcDeliverFiles.rb [-O] [-N] [-p "Field1:Value Field2:Value"] [-R]
#        --ONCE      The file is just sent once for each I/F
#        --NOARCHIVE This flag skips the file archive retrieving step
#        --Report    This flag enables Delivered Files Reports creation.
#        --Kill      it cancels an ongoing delivery
#        --help      shows this help
#        --usage     shows the usage
#        --Debug     shows Debug info during the execution
#        --version   shows version number
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2006 ESA - Deimos Space S.L.
#


#########################################################################
#
# === Ruby script ddcDeliverFiles for sending all files to an Entity
# 
# === Written by DEIMOS Space S.L.   (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# CVS: $Id: ddcDeliverFiles.rb,v 1.8 2008/06/09 12:55:34 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'cuc/CheckerProcessUniqueness'
require 'ctc/ReadInterfaceConfig'

# Global variables
@@dateLastModification = "$Date: 2008/06/09 12:55:34 $"     # to keep control of the last modification
                                                            # of this script
                                                            # execution showing Debug Info
@isDebugMode      = false                  

# MAIN script function
def main

   #======================================================================
   
   def SIGTERMHandler
      puts "\n[#{File.basename($0)}] SIGTERM signal received ... sayonara, baby !\n"
      self.killInProgressSend2Interfaces
      @locker.release
      exit(0)
   end
   #======================================================================

   # It sends SIGTERM signal to the in-progress send2Entity <I/F> processes
   def killInProgressSend2Interfaces
      ddcIntConfig  = CTC::ReadInterfaceConfig.instance
      arrInterfaces = ddcIntConfig.getAllMnemonics
   
      arrInterfaces.each{|x|
         puts
         puts "Stopping delivery to #{x}"
         checker = CUC::CheckerProcessUniqueness.new("send2Interface.rb", x, true)
         if @isDebugMode == true then
            checker.setDebugMode
         end
         pid = checker.getRunningPID
         if pid == false then
            if @isDebugMode == true then
               puts "send2Interface for #{x} I/F was not running \n"
            end
         else
            if @isDebugMode == true then
               puts "Sending signal SIGTERM to Process #{pid} for killing send2Interface.rb #{x}"
            end
            Process.kill(15, pid.to_i)
         end         
      }
   end   
   #======================================================================
   @isDeliveredOnce  = false
   @skipGetFiles     = false
   @strParams        = ""
   @createReport     = false
   bKill             = false

   opts = GetoptLong.new(
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--ONCE", "-O",           GetoptLong::NO_ARGUMENT],
     ["--NOARCHIVE", "-N",      GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--Report", "-R",         GetoptLong::NO_ARGUMENT],
     ["--params", "-p",         GetoptLong::REQUIRED_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--Kill", "-K",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt
            when "--ONCE"      then @isDeliveredOnce = true
            when "--NOARCHIVE" then @skipGetFiles = true
            when "--Debug"   then @isDebugMode = true
            when "--version" then
               print("\nESA - Deimos-Space S.L.  DEC ", File.basename($0), " $Revision: 1.8 $  [", @@dateLastModification, "]\n\n\n")
               exit (0)
            when "--Report"  then @createReport = true
            when "--help"    then RDoc::usage
            when "--usage"   then RDoc::usage("usage")
            when "--params"  then @strParams = arg.to_s
            when "--Kill"    then bKill = true
         end
      end
   rescue Exception
      exit(99)
   end

   if bKill == true then
      killInProgressDelivery
   end

   if @strParams != "" and @isDeliveredOnce == false then
      puts "params argument -p requires -O option enabled ! :-p"
      exit(99)
   end
   
   # Register a handler for SIGTERM
   trap 15,proc{ self.SIGTERMHandler }

   # This assures there is only one send2Interface running for a given I/F. 
   @locker = CUC::CheckerProcessUniqueness.new(File.basename($0), nil, true)

   if @locker.isRunning == true then
      puts "\n#{File.basename($0)} is already running !\n\n"
      exit(99)
   end

   # Register in lock file the process
   @locker.setRunning

   if @skipGetFiles == false then
      cmd = "getFilesToBeTransferred.rb"
   
      if @isDebugMode == true then
         cmd = %Q{#{cmd} -D}
      end
   
      ret = system(cmd)
   
      if ret == false then
         puts
         puts "Error executing #{cmd}"
         puts
         puts "Could not retrieve files to be sent from Archive ! :-("
         puts 
         exit(99)
      end
   end
      
   # Deliver to all Interfaces
   deliver2Interfaces
   
end

#---------------------------------------------------------------------

#---------------------------------------------------------------------

# Deliver 2 all interfaces
def deliver2Interfaces
   ddcIntConfig  = CTC::ReadInterfaceConfig.instance
   arrInterfaces = ddcIntConfig.getAllMnemonics
   processInfo   = Hash.new
   
   arrInterfaces.each{|interface|

      if ddcIntConfig.isEnabled4Sending?(interface) == false then
         next
      end

      if @isDebugMode == true then
         command  = %Q{send2Interface.rb --mnemonic #{interface} -D}
      else
         command  = %Q{send2Interface.rb --mnemonic #{interface}}
      end

      if @isDeliveredOnce == true then
         command = %Q{#{command} -O}
      end

      if @createReport == true then
         command = %Q{#{command} -R}
      end

      if @strParams != "" then
         command = %Q{#{command} -p "#{@strParams}"}
      end

      # Create a new process for each Interface
      pid = fork { 
         Process.setpriority(Process::PRIO_PROCESS, 0, 1)
#         if @isDebugMode == true then
            puts command
#         end
         exec(command)
      }
      
      sleep(2)
      processInfo[pid] = interface

   }
   
   # Wait for all processes
   bSuccess = true

   arrInterfaces.each{|interface|

      if ddcIntConfig.isEnabled4Sending?(interface) == false then
         next
      end

      pid     = Process.wait
      resCode = $? >> 8         
      
      if resCode != 0 then
         print("\nFAILED to Send the files to ", processInfo[pid], " I/F !\n\n")
         bSuccess = false
      end
   
   }
   return bSuccess
end
#---------------------------------------------------------------------

#==========================================================================

# It sends SIGTERM signal to the active in-progress ddcDeliverFiles process
def killInProgressDelivery
   checker = CUC::CheckerProcessUniqueness.new(File.basename($0), nil, true)
   if @isDebugMode == true then
      checker.setDebugMode
   end
   if checker.getRunningPID == false then
      puts "#{File.basename($0)} was not running !\n"
      exit(99)
   else
      pid = checker.getRunningPID
      puts "Sending signal SIGTERM to Process #{pid} for killing #{File.basename($0)} "
      Process.kill(15, pid.to_i)
      exit(0)
   end
end
#==========================================================================

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
