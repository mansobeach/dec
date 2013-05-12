#!/usr/bin/env ruby


# == Synopsis
#
# This is a Data Distributor Ccmponent command line tool that deliver files to a given I/F.
# It delivers files via (s)ftp and email. Files sent are registered in the Inventory 
# and the delivery date is set to the latest one.
#
# This command can be used in order to send a given file just once 
# (for each delivery method: ftp, email) for a given Interface. 
# Use "-O" flag to enable this behaviour.
#
# -R flag:
#
# With this option (Report), a Report "List" with the new files sent is created. 
# This Report file is initally placed in the Interface local inbox.
#
#
# == Usage
# send2Interface.rb -m <MNEMONIC> [-O]
#        --mnemonic  <MNEMONIC> (mnemonic is case sensitive)
#        --ONCE      The file is just sent once for that I/F
#        --AUTO      local outbox Automatic management 
#        --loops <n> n is the number of Loop retries to achieve the Delivery
#        --delay <s> s seconds of delay between each Loop Retry
#                      [60 secs by default if it is not specified]
#        --retries <r>  r is the number of retries on each Loop for each file
#        --Report    create a Report with the list of files delivered to the Interface
#        --list      list only (not downloading and no ingestion)
#        --Nomail    avoids mail notification to the I/F after successfully delivery
#        --Show      it shows all available I/Fs registered in the Inventory
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
# Ruby script send2Interface for sending all files to an Entity
# 
# Written by DEIMOS Space S.L.   (bolf)
#
# Data Exchange Component -> Data Distributor Component
# 
# CVS:
#   $Id: send2Interface.rb,v 1.23 2008/07/03 11:38:26 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'cuc/CheckerProcessUniqueness'
require 'ctc/ReadInterfaceConfig'
require 'ctc/EventManager'
require 'ddc/DDC_FileSender'
require 'ddc/DDC_FileMailer'
require 'ddc/DDC_BodyMailer'
require 'ddc/ReadConfigDDC'

# Global variables
@@dateLastModification = "$Date: 2008/07/03 11:38:26 $"     # to keep control of the last modification
                                                            # of this script
                                                            # execution showing Debug Info
@isDebugMode      = false                  
@entity           = ""

# MAIN script function
def main

   #=======================================================================

   def SIGTERMHandler
      puts
      puts "\n[#{File.basename($0)} #{@entity}] SIGTERM signal received ... sayonara, baby !\n"
      killInProgressNotify2Entity
      @locker.release
      exit(0)
   end
   #=======================================================================

   # If it is running, it kills its notify2Interface associated
   def killInProgressNotify2Entity
      checker = CUC::CheckerProcessUniqueness.new("notify2Interface.rb", @entity, true)
      if @isDebugMode == 1 then
         checker.setDebugMode
      end
      pid = checker.getRunningPID
      if pid == false then
         if @isDebugMode == 1 then
            puts "notify2Interface for #{@entity} I/F was not running \n"
         end
      else
         if @isDebugMode == 1 then
            puts "Sending signal SIGTERM to Process #{pid} for killing notify2Interface.rb #{@entity}"
         end
         Process.kill(15, pid.to_i)
      end               
   end
   #=======================================================================   

   include           DDC
   include           CUC::DirUtils

   @isAutoManagement = true
   @createReport     = false    
   @isDebugMode      = false 
   @isDeliveredOnce  = false
   @@retries         = 1
   @@loops           = 1
   @@delay           = 60
   @@nROP            = 0
   @@bResult         = false
   sent              = false
   @bShowMnemonics   = false           
   @bNotify          = true
   @strParams        = ""
   @hParams          = nil
   
   
   opts = GetoptLong.new(
     ["--mnemonic", "-m",       GetoptLong::REQUIRED_ARGUMENT],
     ["--loops", "-l",          GetoptLong::REQUIRED_ARGUMENT],
     ["--delay", "-d",          GetoptLong::REQUIRED_ARGUMENT],
     ["--retries", "-r",        GetoptLong::REQUIRED_ARGUMENT],
     ["--params", "-p",         GetoptLong::REQUIRED_ARGUMENT],
     ["--ONCE", "-O",           GetoptLong::NO_ARGUMENT],
     ["--AUTO", "-A",           GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--Report", "-R",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--Show", "-S",           GetoptLong::NO_ARGUMENT],
     ["--Nomail", "-N",         GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt
            when "--ONCE"    then @isDeliveredOnce = true
            when "--AUTO"    then @isAutoManagement = true
            when "--Debug"   then @isDebugMode = true
            when "--version" then print("\nESA - Deimos-Space S.L.  DEC ", File.basename($0), " $Revision: 1.23 $  [", @@dateLastModification, "]\n\n\n")
                                  exit(0)
            when "--mnemonic" then
               @entity = arg         
            when "--help"    then RDoc::usage
            when "--usage"   then RDoc::usage("usage")
            when "--retries" then 
               @@retries = arg.to_i
            when "--loops" then
               @@loops   = arg.to_i
            when "--delay" then
               @@delay   = arg.to_i
            when "--params"  then @strParams = arg.to_s
            when "--Nomail" then
               @bNotify  = false
            when "--Show" then @bShowMnemonics = true
            when "--Report" then @createReport = true                     
         end
      end
   rescue Exception
      exit(99)
   end   
    
   if @bShowMnemonics == true then
      arrInterfaces = Interface.find(:all)
      if arrInterfaces == nil then
         puts
         puts "Sorry, there are no configured I/Fs :-|"
         puts
      else
         if arrInterfaces.length == 0 then
            puts
            puts "Sorry, there are no configured I/Fs :-|"
            puts
         else
            puts "=== Data Distributor Component Registered I/Fs ==="
            arrInterfaces.each{|interface|
               print interface.name
               1.upto(25 - interface.name.length) do
                  print " "
               end
               print interface.description
               puts
            }         
         end
      end
      exit(0)
   end

   if @entity == "" then
      RDoc::usage("usage")
   end
   
   if @strParams != "" then
      decodeParams
   end

   @incomingDir = CTC::ReadInterfaceConfig.instance.getIncomingDir(@entity)
   
   # Set send2Interface <I/F> running.
   # This assures there is only one send2Interface running for a given I/F. 
   @locker = CUC::CheckerProcessUniqueness.new(File.basename($0), @entity, true)
   
#    if @isDebugMode == 1 then
#       @locker.setDebugMode
#    end
   
   if @locker.isRunning == true then
      puts "\n#{File.basename($0)} for #{@entity} I/F is already running !\n\n"
      exit(99)
   end

   # Register a handler for SIGTERM
   trap 15,proc{ self.SIGTERMHandler }

   # initialize logger
   loggerFactory = CUC::Log4rLoggerFactory.new("send2Interface", "#{ENV['DCC_CONFIG']}/dec_log_config.xml")
   if @isDebugMode then
      loggerFactory.setDebugMode
   end
   @logger = loggerFactory.getLogger
   if @logger == nil then
      puts
		puts "Error in send2Interface::main"
		puts "Could not set up logging system !  :-("
      puts "Check DEC logs configuration under \"#{ENV['DCC_CONFIG']}/dec_log_config.xml\"" 
		puts
		puts
		exit(99)
   end
  
   # Register in lock file the process
   @locker.setRunning

   # Check that the given mnemonic is present in the config file   
   @ftReadConf = CTC::ReadInterfaceConfig.instance
   arrEntities = @ftReadConf.getAllExternalMnemonics
   bFound      = false
   arrEntities.each{|entity|
      if @entity == entity then
         bFound = true
      end
   }
      
   if bFound == false then
      print("\nInterface ", @entity, " does not exist !!   :-(\n\n")
      exit(99)
   end   
         
   #------------------------------------------------------------------
   # AUTOMATION FileSender Management
   @bNewLoop = true
   
   while @bNewLoop
      @bNewLoop = false

      bSent = deliverByFTP

      # Deliverying files via mailbody
      if bSent == true then
         bSent = deliverByBodyMail
      else
         deliverByBodyMail
      end

      # Deliverying files via email
      if bSent == true then
         bSent = deliverByMail
      else
         deliverByMail
      end   

      # Try again for FTP deliveries
      if bSent == true then
         bSent = deliverByFTP
      else
         deliverByFTP
      end   
   end
   #------------------------------------------------------------------

   # Release the Locker
   @locker.release
   
   if bSent == true then
      puts "\nSuccess delivering files to #{@entity} ! :-)\n\n"
      exit(0)
   else
      puts "\nFailed to deliver files to #{@entity} ! :-(\n\n"
      exit(99)   
   end
end

#---------------------------------------------------------------------

# Generate and deliver Notification Mail to the given I/F
# If for this I/F no file is sent, no mail is sent as well. 
def notifySuccess2Entity
   cmd           = nil
   # Create a File which contains all the files sent
   fileListFiles = ""
   tmpDir    = ENV['DCC_TMP']
   time      = Time.new
   fileListFiles = %Q{#{tmpDir}/.#{time.to_f.to_s}_sent2#{@entity}}
   aFile = File.new(fileListFiles, File::CREAT|File::WRONLY)
   @listFiles.each{|x| aFile.puts(x)}     
   aFile.flush
   aFile.close
   
   cmd = %Q{notify2Interface.rb -m #{@entity} -O -f #{fileListFiles}}
      
   if @isDebugMode == true then
      cmd = %Q{#{cmd} -D}
      puts cmd
   end      
      
   retVal = system(cmd)
   if retVal == false then
      puts "\nWarning: Failed to send mail notification ! :-(\n"
      @logger.error("Failed to send mail notification-success to #{@entity}")
   end
   if FileTest.exist?(fileListFiles)==true then
      File.delete(fileListFiles)
   end
end
#---------------------------------------------------------------------
#---------------------------------------------------------------------

# Generate and deliver Notification Mail to the given 
def notifyFailure2Entity

   cmd           = nil
   # Create a File which contains all the files failed to be sent
   fileListFilesErrors = ""
   tmpDir    = ENV['DCC_TMP']
   time      = Time.new
   fileListFilesErrors = %Q{#{tmpDir}/.#{time.to_f.to_s}_failed2#{@entity}}
   aFile = File.new(fileListFilesErrors, File::CREAT|File::WRONLY)
   @listFilesError.each{|x| aFile.puts(x)}     
   aFile.flush
   aFile.close

   cmd = %Q{notify2Interface.rb -m #{@entity} -K -f #{fileListFilesErrors}}   
   if @isDebugMode == true then
     cmd = %Q{#{cmd} -D}
     puts cmd
   end   
   retVal = system(cmd)   
   if retVal == false then
      puts "\n\nWarning: Failed to send mail notification ! :-(\n"
      @logger.error("Failed to send mail notification-error to #{@entity}")
   end   
   if FileTest.exist?(fileListFilesErrors)==true then
      File.delete(fileListFilesErrors)
   end
end
#---------------------------------------------------------------------

# Decode parameters to be updated in the database
def decodeParams
   @hParams = Hash.new
   pairs = @strParams.split(" ")
   pairs.each{|aPair|
      arrTmp = aPair.split(":")
      @hParams[arrTmp[0]] = arrTmp[1]
   }
end
#---------------------------------------------------------------------

def deliverByBodyMail
   bNewFiles   = true
   bNewFiles   = true
   bSent       = true
   bFirst      = true
   
   while bNewFiles
      ddcMailer = DDC::DDC_BodyMailer.new(@entity, false)
      if @isDebugMode == true then
         ddcMailer.setDebugMode
      end
      numFiles  = ddcMailer.listFileToBeSent.length
      
      if numFiles == 0 then
         bNewFiles = false
         if bFirst == true then
            puts "No files to be delivered via mailbody to #{@entity}"
            puts
         end
      else
         bSent = ddcMailer.deliver(@isDeliveredOnce, @hParams)
         # If there was an error in the delivery, 
         # do not mind whether there are new files to be sent
         if bSent == false then
            bNewFiles = false
         else
            @bNewLoop = true
         end
      end
      bFirst = false
   end
   return bSent
end
#---------------------------------------------------------------------

def deliverByMail
   bNewFiles   = true
   bNewFiles   = true
   bSent       = true
   bFirst      = true
   
   while bNewFiles
      ddcMailer = DDC::DDC_FileMailer.new(@entity, false)
      if @isDebugMode == true then
         ddcMailer.setDebugMode
      end
      numFiles  = ddcMailer.listFileToBeSent.length
      
      if numFiles == 0 then
         bNewFiles = false
         if bFirst == true then
            puts "No files to be delivered via email to #{@entity}"
         end
      else
         bSent = ddcMailer.deliver(@isDeliveredOnce, @hParams)
         # If there was an error in the delivery, 
         # do not mind whether there are new files to be sent
         if bSent == false then
            bNewFiles = false
         else
            @bNewLoop = true
         end
      end
      bFirst = false
   end
   return bSent
end
#---------------------------------------------------------------------

def deliverByFTP
   bNewFiles   = true
   bSent       = true
   bFirst      = true
   
   event  = CTC::EventManager.new

   if @isDebugMode == true then
      event.setDebugMode
   end


   while bNewFiles
      sender = DDC_FileSender.new(@entity, @isDebugMode)
      if @isDebugMode == true then
         sender.setDebugMode
      end
      numFiles = sender.listFileToBeSent.length

      if numFiles == 0 then
         bNewFiles = false
         if bFirst == true then
            puts
            puts "No files to be delivered via ftp to #{@entity}"
            puts
         end
      else
         bSent = sender.deliver(@isDeliveredOnce, @hParams)

         # Configure Mail Notification
         mailParams  = @ftReadConf.getMailParams(@entity)
         ddcConfig   = DDC::ReadConfigDDC.instance
         reportDir   = ddcConfig.getReportDir
         checkDirectory(reportDir)   
         @listFiles  = Array.new
	      @listFilesError = Array.new
         # -------------------------------------------------
         # Notify via Mail the new files delivered
         if bSent == true then
            # Create the Report if applicable   
            sender.createReportFile(reportDir, true, @createReport, @isDeliveredOnce)
            # if it is enabled notification
            if @bNotify == true and (mailParams[:sendNotification].to_s == "true") then
               @listFiles = sender.listFileSent
               notifySuccess2Entity
            end
         else
            bNewFiles = false
            if @bNotify == true and (mailParams[:sendNotification].to_s == "true") then
	            @listFilesError = sender.listFileError
               notifyFailure2Entity
            end
         end
         # -------------------------------------------------
         # Trigger and EVENT
         if bSent == true then
            if @listFiles.length > 0
               event.trigger(@entity, "ONSENDNEWFILESOK")
            end
         else
            event.trigger(@entity, "ONSENDERROR")
         end
         # -------------------------------------------------
      end
      bFirst = false
   end
   # End of AUTOMATION FileSender Management
   #------------------------------------------------------------------

   if bSent == true then
      event.trigger(@entity, "ONSENDOK")
   end
   return bSent
end
#---------------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
