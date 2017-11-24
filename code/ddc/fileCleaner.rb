#!/usr/bin/env ruby

# == Synopsis
#
# This is a DDC command line tool that performs file cleaning on files previosly delivered to the configured I/Fs.
# Normally Clean-up configuration should be enabled for files delivered "locally" in "PULL" mode.
#
# Clean-Up configuration is based on:
# - Clean-Up tasks frequency
# - Files Age to be cleaned
# 
# Clean-Up frequency is setup within interfaces.xml configuration file.
# For each Interface it is specified its Clean-up frequency.
# This is done via CleanUpFreq configuration element. 
# e.g. <CleanUpFreq Unit="s">3600</CleanUpFreq> 
#
# Files Age is specified within ft_outgoing_files.xml configuration file. 
# For each File-type and Interface it is specified age limit of files exposed.
# This is done via the CleanUpAge configuration Attribute. File Age is expressed in seconds. 
# E.g.: 
# <Interface Name="FOS" (..) CleanUpAge="999"/>
#
#
# -m flag:
#
# This option receives the I/F mnemonic argument. It performs specific files clean-up 
# on such Interface. When using this flag, the tool checks up that there is no other instance
# of it running for the specified Interface.
#
#
# -a flag:
#
# This is the all flag, which performs clean-up on all DDC configured Interfaces.
# This flag is exclusive with -m flag.
#
#
# == Usage
# fileCleaner.rb -a | -m <mnemonic>
#     -a    performs clean-up on all DDC configured Interfaces
#
#     -m  <I/F MNEMONIC>
#           it performs clean-up on the specified I/F.
#
#     -h    it shows the help of the tool
#     -u    it shows the usage of the tool
#     -v    it shows the version number
#     -V    it performs the execution in Verbose mode
#     -D    it performs the execution in Debug mode     
#
#
# == Author
# Deimos-Space S.L. (bolf)
#
#
# == Copyright
# Copyright (c) 2007 ESA - Deimos Space S.L.
#

#########################################################################
#
# === Data Distributor Component
# 
# CVS: $Id: fileCleaner.rb,v 1.4 2008/07/03 11:38:26 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rubygems'
require 'net/ssh'
require 'net/sftp'

require 'cuc/Log4rLoggerFactory'
require 'cuc/EE_ReadFileName'
require 'cuc/CheckerProcessUniqueness'
require 'dbm/DatabaseModel'
require 'ctc/CheckerInterfaceConfig'
require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadFileDestination'


# checkSent2Entity checks what it has been sent to a given entity.
# It checks in the UploadDir and UploadTemp directories 

# Global variables
@@dateLastModification = "$Date: 2008/07/03 11:38:26 $" 
                                    # to keep control of the last modification
                                    # of this script
@isDebugMode      = false               # execution showing Debug Info
@isVerboseMode    = false
@isSecure         = false
@checkUploadTmp   = false
@bIncoming        = false
@bOutgoing        = false
@bEntities        = false
@bMail            = false
@bClients         = false
@bAll             = false
@bServices        = false
@bTrays           = false
@entity           = ""
@locker           = nil

# MAIN script function
def main

   opts = GetoptLong.new(     
     ["--all", "-a",            GetoptLong::NO_ARGUMENT],
#     ["--incoming", "-i",       GetoptLong::NO_ARGUMENT],
#     ["--tray", "-t",           GetoptLong::NO_ARGUMENT],
     ["--outgoing", "-o",       GetoptLong::NO_ARGUMENT],
     ["--entities", "-e",       GetoptLong::NO_ARGUMENT],
     ["--mnemonic", "-m",       GetoptLong::REQUIRED_ARGUMENT],
     ["--services", "-s",       GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--Verbose", "-V",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
   
         case opt
      
            when "--Debug"   then @isDebugMode   = true
            when "--Verbose" then @isVerboseMode = true
            when "--version" then
               print("\nESA - Deimos-Space S.L.  Data Collector Component ", File.basename($0), " $Revision: 1.4 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
            when "--help"     then usage
#            when "--incoming" then @bIncoming = true
            when "--outgoing" then @bOutgoing = true
            when "--entities" then @bEntities = true
            when "--services" then @bServices = true
            when "--mnemonic" then @entity = arg.to_s
            when "--all"      then @bAll      = true
#            when "--tray"     then @bTrays    = true
            when "--usage"    then usage

         end

      end
   rescue Exception
     exit(99)
   end
   
   if @bAll == false and @entity == "" then
      usage
   end

   if @bAll == true and @entity != "" then
      usage
   end
 
   # Check Module Integrity
   checkModuleIntegrity
   
   # Set fileCleaner <I/F> running.
   # This assures there is only one fileCleaner running for a given I/F.
   
   if @entity != "" then  
      @locker = CUC::CheckerProcessUniqueness.new(File.basename($0), @entity, true)
   
      if @locker.isRunning == true then
         puts "\n#{File.basename($0)} for #{@entity} I/F is already running !\n\n"
         exit(99)
      end
   end

   @ftReadOutgoing   = CTC::ReadFileDestination.instance   
   @ftConfig         = CTC::ReadInterfaceConfig.instance
   arrEnts           = @ftConfig.getAllExternalMnemonics

   # initialize logger
   loggerFactory = CUC::Log4rLoggerFactory.new("fileCleaner", "#{ENV['DCC_CONFIG']}/dec_log_config.xml")
   if @isDebugMode then
      loggerFactory.setDebugMode
   end
   @logger = loggerFactory.getLogger
   if @logger == nil then
      puts
		puts "Error in fileCleaner::main"
		puts "Could not set up logging system !  :-("
      puts "Check DEC logs configuration under \"#{ENV['DCC_CONFIG']}/dec_log_config.xml\"" 
		puts
		puts
		exit(99)
   end

   msg = ""
   if @entity != "" then
      msg = "Performing clean-up on Files delivered to #{@entity} I/F"
   else
      msg = "Performing clean-up on Files delivered to ALL I/F"
   end

   puts
   puts msg
   @logger.info(msg)

   arrEnts.each{|x|

      if @bAll == false and @entity != x then
         next
      end
       
      if @ftConfig.isEnabled4Sending?(x) == false then
         puts
         puts "#{x} is disabled for sending => no clean-up"
         next
      end
      
      freq = @ftConfig.getCleanUpFreq(x)

      if freq == 0 then
         puts "\nDisseminated Files Clean-Up for #{x} I/F is disabled\n"
         next
      end
   
      puts "\nCleaning-Up  Files Disseminated to #{x} I/F\n"

		checker    = CTC::CheckerInterfaceConfig.new(x, false, true)
      
      if @isDebugMode == true then
         checker.setDebugMode
      end
         
      # In DDC we must check only for Send
      retVal     = checker.check4Send

      if retVal == false then
         puts "\n#{x} I/F is not configured correctly ! :-( \n"
         puts "#{x} - No Clean-up could be performed on UploadDir"
         @logger.error("#{x} - is NOT configured correctly")
         @logger.error("#{x} - No Clean-up could be performed on UploadDir")
         next
      end

      arrFiles = Array.new

      if @ftConfig.isSecure?(x) == true then
         arrFiles = getSecureFileList(x)
      else
         arrFiles = getNonSecureFileList(x)
      end

      arrFiles.each{|aFile|
         arrFiles = SentFile.find_all_by_filename(aFile) 
         
         if arrFiles == nil then
            next
         end

         arrFiles.each{|file|
            if file.interface.name == x then
               afileName = file.filename
               # Nowadays Clean-Up is only implemented for Earth Explorer Files
               # But we force to retrieve the file-type
#                if CUC::EE_ReadFileName.new(afileName).isEarthExplorerFile? == false then
#                   next
#                end

               fileType = CUC::EE_ReadFileName.new(afileName).fileType

               cleanAge = @ftReadOutgoing.getCleanUpAge(x, fileType)

               # No cleanning is performed for such file-type and interface
               if cleanAge == 0 then
                  if @isVerboseMode == true or @isDebugMode == true then
                     print "No clean-up is configured for #{x} I/F and #{fileType} "
                     puts
                     puts
                  end
                  next
               end

               sentDate = file.delivery_date

               now      = Time.now

               now.utc
               secsNow     = now.to_i
               secsBefore  = sentDate.to_i
               delta       = secsNow - secsBefore
         
               if @isDebugMode == true or @isVerboseMode then
                  print "#{afileName} sent #{sentDate} #{now}  || #{delta} - #{cleanAge}"
                  puts
               end

               # Perform Clean Up
               if delta >= cleanAge then
                  cleanUp(x, afileName)
               else
                  if @isVerboseMode or @isDebugMode == true then
                     print "#{afileName} is still young ;-) "
                     puts
                     puts
                  end
               end
            end
         }


      }

   }      
   
   # Release Process lock
   if @entity != "" then  
      @locker.release
   end

   
end
#-------------------------------------------------------------

# Retrieve UploadDir file content with Secure FTP

def getSecureFileList(entity)

   ftpserver   = @ftConfig.getFTPServer4Send(entity)

   if ftpserver == nil then
      puts
      puts "Error in fileCleaner::getSecureFileList #{entity} !"
      puts
   end

   @newArrFile = Array.new
   @ftp        = nil
   host        = ftpserver[:hostname]
   port        = ftpserver[:port].to_i
   user        = ftpserver[:user]
   
   begin
      @ftp     = Net::SFTP.start(host, port, user)
      @session = @ftp.connect
   rescue Exception => e
      puts
      puts e.to_s
      puts "Unable to connect to #{host}"
      @logger.error("#{entity}: #{e.to_s}")
      @logger.error("#{entity}: Unable to connect to #{host}")
      @logger.error("Could not poll #{entity} I/F")
      puts
      return Array.new
      exit(99)
   end

   remotePath = ftpserver[:uploadDir]

   begin
      handle = @session.opendir(remotePath)
      
      @ftp.readdir( handle ).each{|item|
         if item.filename == "." or item.filename == ".." then
            next
         end
         @newArrFile << item.filename
      }
   rescue Exception => e
      puts e.to_s
   end
      
   @ftp.close
   return @newArrFile
end
#-------------------------------------------------------------

# Retrieve UploadDir file content with standard FTP

def getNonSecureFileList(entity)

   ftpserver   = @ftConfig.getFTPServer4Send(entity)

   if ftpserver == nil then
      puts
      puts "Error in fileCleaner::getSecureFileList #{entity} !"
      puts
   end

   @newArrFile    = Array.new
   @ftp           = nil
   host           = ftpserver[:hostname]      
   port           = ftpserver[:port].to_i
   user           = ftpserver[:user]
   pass           = ftpserver[:password]

   begin
      @ftp = Net::FTP.new(host)
      @ftp.login(user, pass)
      @ftp.passive = true
   rescue Exception => e
      puts
      puts e.to_s
      puts "Unable to connect to #{host}"
      @logger.error("#{entity}: #{e.to_s}")
      @logger.error("#{entity}: Unable to connect to #{host}")
      @logger.error("Could not poll #{entity} I/F")
      puts
      return Array.new
      exit(99)
   end

   remotePath = ftpserver[:uploadDir]
         
   begin
      @ftp.chdir(remotePath)
   rescue Exception => e
      @ftp.chdir("/")
      puts
      puts "Error trying to reach #{remotePath}"
      puts e.to_s
      puts
      return Array.new
      next
   end

   @pwd = @ftp.pwd
   @newArrFile = @ftp.nlst   
   @ftp.chdir("/")     
   @ftp.close
   return @newArrFile
end
#-------------------------------------------------------------

# Performs the file clean-up using interfaces.xml configuration
def cleanUp(interface, filename)

   puts "#{interface} I/F - Cleaning #{filename}"

   ftpserver   = @ftConfig.getFTPServer4Send(interface)

   if ftpserver == nil then
      puts
      puts "Error in fileCleaner::getSecureFileList #{interface} !"
      puts
   end

   @newArrFile = Array.new

   @ftp        = nil
   host        = ftpserver[:hostname]
   port        = ftpserver[:port].to_i
   user        = ftpserver[:user]
   pass        = ftpserver[:password]
   remotePath  = ftpserver[:uploadDir]
   
   if @ftConfig.isSecure?(interface) == true then
      begin
         @ftp     = Net::SFTP.start(host, port, user)
         @ftp.connect
         @ftp.remove("#{remotePath}/#{filename}")
         @ftp.close
         @logger.info("#{interface} I/F - #{filename} cleaned")
      rescue Exception => e
         puts
         puts e.message
         puts "#{interface} I/F - Unable to clean-up to #{filename}"
         puts
         @logger.error("#{interface}: #{e.to_s}")
         @logger.error("#{interface} I/F - Could not clean-up #{filename}")
      end
   else
      begin
         @ftp = Net::FTP.new(host)
         @ftp.login(user, pass)
         @ftp.passive = true
         @ftp.chdir(remotePath)
         @ftp.delete(filename)
         @ftp.close
         @logger.info("#{interface} I/F - #{filename} cleaned")
      rescue Exception => e
         puts
         puts e.to_s
         puts "#{interface} I/F - Unable to clean-up to #{filename}"
         puts
         @logger.error("#{interface}: #{e.to_s}")
         @logger.error("#{interface} I/F - Could not clean-up #{filename}")
      end
   end
end
#-------------------------------------------------------------
   
# Check that everything needed by the class is present.
def checkModuleIntegrity
   return
end 
#-------------------------------------------------------------

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -25 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
   exit   
end
#-------------------------------------------------------------


#==========================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
