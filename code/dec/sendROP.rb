#!/usr/bin/env ruby

# == Synopsis
#
# This is the sendROP command line tool that deliver all transferable files
# belonging to a given ROP.
# 
#
# == Usage
# sendROP.rb   -R <numROP>
#              --help      shows this help
#              --usage     shows the usage
#              --Debug     shows Debug info during the execution
#              --Kill      it cancels a sendROP execution via sending signal SIGTERM
#              --env       it prints the execution environment variables
#              --version   shows version number
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2006 ESA - Deimos Space S.L.
#


#########################################################################
#
# Ruby script sendROP
# 
# Written by DEIMOS Space S.L.   (bolf)
#
# Data Exchange Component -> Mission Management & Planning Facility
# 
# Git:
#     sendROP.rb  $Author$
#                 $Date$ 
#                 $Committer$
#
#########################################################################

require 'getoptlong'

require 'ddc/DDC_FileSender'
require 'ddc/DDC_FileMailer'
require 'ctc/ReadInterfaceConfig'
require 'cuc/Logger.rb'
require 'cuc/DirUtils'
require 'cuc/CheckerProcessUniqueness'   

require 'rpf/ROPSender'

require 'dec/DEC_Environment'


@isDebugMode      = false                  
@entity           = ""

# MAIN script function
def main

   #=======================================================================

   def SIGTERMHandler
      puts "\n[#{File.basename($0)}] SIGTERM signal received ... sayonara, baby !\n"
      puts
      cmd = %Q{ddcDeliverFiles.rb -K}
      puts cmd
      bRet = system(cmd)
      @locker.release
      if @bUnblock == true
         sender.unlockFTActions
      end
      exit(0)
   end
   #=======================================================================

  

   include           DDC
   include           CUC::DirUtils
   include           DEC
   
   
   @isDebugMode         = false 
   @retries             = 1
   @loops               = 1
   @delay               = 60
   @nROP                = 0
   @bResult             = false
   sent                 = false
   bKill                = false

   @bNotify             = true
   @bUnblock            = true 
   @bUsage              = false
   @bShowVersion        = false
   @bShowEnv            = false
   
   
   opts = GetoptLong.new(
     ["--ROP", "-R",             GetoptLong::REQUIRED_ARGUMENT],
     ["--loops", "-l",           GetoptLong::REQUIRED_ARGUMENT],
     ["--delay", "-d",           GetoptLong::REQUIRED_ARGUMENT],
     ["--retries", "-r",         GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",           GetoptLong::NO_ARGUMENT],
     ["--env", "-e",             GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT],
     ["--Kill", "-K",            GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt      
            when "--Debug"    then @isDebugMode          = true
            when "--version"  then @bShowVersion         = true
            when "--env"      then @bShowEnv             = true
            when "--help"     then @bUsage               = true
            when "--usage"    then @bUsage               = true
            when "--ROP"      then @nROP                 = arg
            when "--retries"  then @retries              = arg.to_i
            when "--loops"    then @loops                = arg.to_i
            when "--delay"    then @delay                = arg.to_i
            when "--Kill"     then bKill                 = true
         end
      end
   rescue Exception
      exit(99)
   end   
 
   if @bShowVersion == true then
      print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " Version: [#{DEC.class_variable_get(:@@version)}]", "\n\n")
      hRecord = DEC.class_variable_get(:@@change_record)
      hRecord.each_pair{|key, value|
         puts "#{key} => #{value}"
      }      
      exit(0)
   end
   
   if @bUsage then
      usage
      exit(0)
   end

   if @bShowEnv == true then
      self.print_environment
      self.print_environmentRPF
      puts
      exit(0)
   end

   if self.checkEnvironmentEssential == false then
      puts
      self.printEnvironmentError
      puts
      puts
      self.print_environment
      puts
      exit(99)
   end

   if self.checkEnvironmentRPF == false then
      puts
      self.printEnvironmentError
      puts
      puts
      self.print_environmentRPF
      puts      
      exit(99)   
   end

   if bKill == true then
      killInProgressDelivery
   end

   if @nROP == 0 then
      usage
      exit(99)
   end

 
   # Register a handler for SIGTERM
   trap 15,proc{ self.SIGTERMHandler }   
   
   # Set sendROP running. This assures there is only one sendROP running  
   @locker = CUC::CheckerProcessUniqueness.new(File.basename($0), nil, true)
      
   if @locker.isRunning == true then
      puts "\n#{File.basename($0)} is already running !\n\n"
      exit(99)
   end
  
   # Register in lock file the process
   @locker.setRunning

   sender = RPF::ROPSender.instance
   ret    = sender.lockFTActions

   if ret == false then
      @bUnblock = false
   end   

   if @isDebugMode == true then
      sender.setDebugMode
      puts "Sending ROP #{@nROP} ..."
   end

   bRes = sender.sendROP(@nROP)
   
   @locker.release

   if @bUnblock == true
      sender.unlockFTActions
   end

   if bRes == true then
      puts
      puts "ROP #{@nROP} delivered successfully ! :-)"
      puts
      exit(0)
   else
      puts
      puts "ERROR, could not deliver ROP #{@nROP} ! :-("
      puts
      exit(99)   
   end
   
end

#---------------------------------------------------------------------

#==========================================================================

# It sends SIGTERM signal to the active in-progress sendROP process
def killInProgressDelivery
   
   # Try to see whether sendROP.rb process is running
   checker = CUC::CheckerProcessUniqueness.new(File.basename($0), nil, true)
   if @isDebugMode == true then
      checker.setDebugMode
   end
   if checker.getRunningPID == false then
      puts
      puts "#{File.basename($0)} / sendROPFiles.rb was not running !\n"
      puts
   else
      pid = checker.getRunningPID
      puts "Sending signal SIGTERM to Process #{pid} for killing #{File.basename($0)} / sendROPFiles.rb"
      Process.kill(15, pid.to_i)
      exit(0)
   end

#    # Try to see whether sendROPFiles.rb process is running
#    checker = CUC::CheckerProcessUniqueness.new("sendROPFiles.rb", nil, true)
#    if @isDebugMode == true then
#       checker.setDebugMode
#    end
#    if checker.getRunningPID == false then
#       puts
#       puts "sendROPFiles.rb was not running !\n"
#       puts
#    else
#       pid = checker.getRunningPID
#       puts "Sending signal SIGTERM to Process #{pid} for killing sendROPFiles.rb "
#       Process.kill(15, pid.to_i)
#       exit(0)
#    end
   exit(99)
end
#==========================================================================

#---------------------------------------------------------------------


#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = File.expand_path(__FILE__)   
   
   value = `#{"head -22 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
end
#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
