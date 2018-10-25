#!/usr/bin/env ruby

# == Synopsis
#
# This is a DDC command line tool that sends an email notification
# with the files sent to a given I/F.
# 
#
# == Usage
# notify2Interface.rb -m <MNEMONIC> --OK | --KO
#   --mnemonic  <MNEMONIC> (mnemonic is case sensitive)
#   --OK        notify success in the delivery to the I/F -f full_path_filelist list of files send
#   --KO        notify failure in the delivery to the I/F -f full_path_filelist list of files failed to be sent
#   --help      shows this help
#   --usage     shows the usage
#   --Debug     shows Debug info during the execution
#   --version   shows version number
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2006 ESA - Deimos Space S.L.
#

#########################################################################
#
# Ruby script notify2Interface for sending all files to an Entity
# 
# Written by DEIMOS Space S.L.   (bolf)
#
# Data Exchange Component -> Data Distributor Component
# 
# CVS:
#   $Id: notify2Interface.rb,v 1.6 2007/11/06 16:33:54 decdev Exp $
#
#########################################################################

require 'getoptlong'

require 'cuc/DirUtils'
require 'cuc/CheckerProcessUniqueness'
require 'ctc/ReadInterfaceConfig'
require 'ddc/DDC_Notifier2Interface'

require 'dec/DEC_Environment'



# MAIN script function
def main

   include DEC
   
   #=======================================================================

   def SIGTERMHandler
      puts "\n[#{File.basename($0)} #{@mnemonic}] SIGTERM signal received ... sayonara, baby !\n"
      @locker.release
      exit(0)
   end
   #=======================================================================

   include           CUC::DirUtils

   @mnemonic         = ""   
   @debugMode        = 0 
   option            = false
   @bResult          = false
   @fullPathFile     = ""
   @bNotify          = true
   @bShowVersion     = false
   @bShowUsage       = false
   
   
   opts = GetoptLong.new(
     ["--mnemonic", "-m",       GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--OK", "-O",             GetoptLong::NO_ARGUMENT],
     ["--KO", "-K",             GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--file", "-f",           GetoptLong::REQUIRED_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt     
            when "--Debug"   then @debugMode = 1
            when "--version" then
               print("\nESA - Deimos-Space S.L. ", File.basename($0), " $Revision: 1.6 $  [", @dateLastModification, "]\n\n\n")
               exit (0)
            when "--mnemonic" then
               @mnemonic = arg
            when "--usage"   then usage
            when "--help"    then usage
            when "--rop" then
               @nROP    = arg.to_i
            when "--OK"   then @isOK = true
                               option = true
                            
            when "--KO"   then @isOK = false
                               option = true         
            when "--file" then
                @fullPathFile = arg                                   
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
    
   if @bShowUsage == true then
      usage
      exit(0)
   end
   
   if self.checkEnvironmentEssential == false then
      puts
      self.printEnvironmentError
      puts
      exit(99)
   end 

   if @mnemonic == "" or option == false then
      usage
      exit(99)
   end
 
   if @isOK == true and option == true and @fullPathFile == "" then
      usage
      exit(99)
   end
   
   if @isOK == false and option == true and @fullPathFile == "" then
      usage
      exit(99)
   end

   # Set notify2Interface <I/F> running.
   # This assures there is only one send2Interface running for a given I/F. 
   @locker = CUC::CheckerProcessUniqueness.new(File.basename($0), @mnemonic, true)
   
#    if @debugMode == 1 then
#       @locker.setDebugMode
#    end
   
   if @locker.isRunning == true then
      puts "\n#{File.basename($0)} for #{@mnemonic} I/F is already running !\n\n"
      exit(99)
   end
  
   # Register in lock file the process
   @locker.setRunning
   
   # Register a handler for SIGTERM
   trap 15,proc{ self.SIGTERMHandler } 
 
   
   # Check that the given mnemonic is present in the config file   
   ftReadConf  = CTC::ReadInterfaceConfig.instance
   arrEntities = ftReadConf.getAllExternalMnemonics
   numEntities = arrEntities.length
   arrSenders  = Array.new
   
   bFound = false
   0.upto(numEntities-1) do |i|
     if @mnemonic == arrEntities[i] then
        bFound = true
     end
   end
   
   if bFound == false then
      print("\nThe Entity ", @mnemonic, "does not exist !!   :-(\n\n")
      @locker.release
      exit(99)
   end

   # Check Whether SendNotification is enabled
   # MMPF:
   # SR-2352-TRN-FUN - MP-FU-50b
   # SR-2354-TRN-FUN - MP-FU-59a
   
   @bNotify  = ftReadConf.isNotificationSent?(@mnemonic)

   if @bNotify == false then
      puts
      puts "E-mail Delivery Notification is disabled for #{@mnemonic}"
      puts
      @locker.release
      exit(0)
   end

   if @isOK == true then
      # if it is enabled notification
      if @bNotify == true then
         notifySuccess2Entity
      end
   else
      if @bNotify == true then
         notifyFailure2Entity
      end
   end
   @locker.release   
end

#---------------------------------------------------------------------


#---------------------------------------------------------------------

# Generate and deliver Notification Mail to the given I/F
# If for this I/F no file is sent, no mail is sent as well. 
def notifySuccess2Entity
   notifier = DDC::DDC_Notifier2Interface.new(@mnemonic)
   if @debugMode == 1 then
      notifier.setDebugMode
   end

   aFile      = File.open(@fullPathFile)
   list       = aFile.readlines
   @listFiles = Array.new
   list.each{|x| @listFiles << x.chop}
   notifier.setListFilesSent(@listFiles)
      
   notifier.notifyFilesSent
end
#---------------------------------------------------------------------

# Generate and deliver Notification Mail to the given 
def notifyFailure2Entity
   notifier = DDC::DDC_Notifier2Interface.new(@mnemonic)
   if @debugMode == 1 then
      notifier.setDebugMode
   end
   
   aFile         = File.open(@fullPathFile)
   listErr       = aFile.readlines
   @listFilesErr = Array.new
   listErr.each{|x| @listFilesErr << x.chop}
   notifier.setListFilesErrors(@listFilesErr)
   notifier.notifyDeliveryError
end
#---------------------------------------------------------------------

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = File.expand_path(__FILE__)
   
   value = `#{"head -24 #{fullpathFile}"}`
      
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
