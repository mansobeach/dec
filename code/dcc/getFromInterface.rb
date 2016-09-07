#!/usr/bin/env ruby

# == Synopsis
#
# This is a DCC command line tool that polls the I/Fs for retrieving 
# files of registered filetypes. As well It retrieves the I/F 
# exchange directory file content linked to a time-stamp.
# 
# -l flag:
#
# With this option, only "List" of new availables files for Retrieving and Tracking is done.
# This flag overrides configuration flags RegisterContentFlag RetrieveContentFlag in interfaces.xml
# So Check ONLY of new Files is performed anyway.
#
# -R flag:
#
# With this option (Reporting), DCC Reports will be created (see dcc_config.xml). 
# Report files are initally placed in the Interface local inbox and
# if configured in files2InTrays.xml disseminated as nominal retrieved file.
#
#
# == Usage
# getFromInterface.rb -m <MNEMONIC>  [-l] [--nodb]
#     --mnemonic  <MNEMONIC> (mnemonic is case sensitive)
#     --list      list only (not downloading and no ingestion)
#     --nodb      no Inventory recording
#     --no-intray skip step of delivery to intrays
#     --del-unknown it deletes remote files not configured in ft_incoming_files.xmls
#     --receipt   create only receipt file-list with the content available
#     --Report    create a Report when new files have been retrieved
#     --Show      it shows all available I/Fs registered in the DCC Inventory
#     --help      shows this help
#     --usage     shows the usage
#     --Debug     shows Debug info during the execution
#     --Unknown   shows Unknown files
#     --Benchmark shows Benchmark info during the execution
#     --version   shows version number
# 
# == Author
# DEIMOS-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2006 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# === Data Collector Component
#
# CVS: $Id: getFromInterface.rb,v 1.15 2015/09/25 16:55:04 decdev Exp $
#
#########################################################################

require 'getoptlong'

require 'cuc/DirUtils'
require 'cuc/CheckerProcessUniqueness'
require 'cuc/Log4rLoggerFactory'
require 'ctc/ReadInterfaceConfig'
require 'ctc/DeliveryListWriter'
require 'ctc/EventManager'
require 'dcc/DCC_ReceiverFromInterface'
require 'dcc/FileDeliverer2InTrays'
require 'dcc/ReadConfigDCC'

# Global variables
@dateLastModification = "$Date: 2008/11/25 16:55:04 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info
@entity          = ""

# MAIN script function
def main

   include CUC::DirUtils
   
   @isBenchMark   = false
   @isDebugMode   = false
   @listOnly      = false
   @listUnknown   = false
   @createReceipt = false
   @createReport  = false
   @bShowMnemonics = false
   @isNoDB        = false
   @isNoIntray    = false
   @isDelUnknown  = false
   
   # initialize logger
   loggerFactory = CUC::Log4rLoggerFactory.new("getFromInterface", "#{ENV['DCC_CONFIG']}/dec_log_config.xml")
   if @isDebugMode then
      loggerFactory.setDebugMode
   end
   @logger = loggerFactory.getLogger
   if @logger == nil then
      puts
	   puts "Error in getFromInterface::main"
		puts "Could not set up logging system !  :-("
      puts "Check DEC logs configuration under \"#{ENV['DCC_CONFIG']}/dec_log_config.xml\"" 
		puts
		puts
		exit(99)
   end
   
   opts = GetoptLong.new(
     ["--mnemonic", "-m",       GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
	  ["--Benchmark", "-B",      GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--Report", "-R",         GetoptLong::NO_ARGUMENT],
	  ["--receipt", "-r",        GetoptLong::NO_ARGUMENT],
     ["--Show", "-S",           GetoptLong::NO_ARGUMENT],
     ["--Unknown", "-U",        GetoptLong::NO_ARGUMENT],
     ["--list", "-l",           GetoptLong::NO_ARGUMENT],
     ["--del-unknown", "-d",    GetoptLong::NO_ARGUMENT],
     ["--no-intray", "-N",      GetoptLong::NO_ARGUMENT],
     ["--nodb", "-n",           GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"     then @isDebugMode = true
            when "--Benchmark" then @isBenchMark = true
            when "--version" then	    
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.15 $  [", @dateLastModification, "]\n\n\n")
               exit(0)
	         when "--mnemonic" then
               @entity = arg
            when "--list" then
                @listOnly = true
            when "--nodb"          then @isNoDB          = true
            when "--no-intray"     then @isNoIntray      = true
            when "--del-unknown"   then @isDelUnknown    = true
			   when "--help"          then usage
	         when "--usage"         then usage
				when "--receipt"       then @createReceipt   = true
            when "--Report"        then @createReport    = true
            when "--Unknown"       then @listUnknown     = true
            when "--Show"          then @bShowMnemonics  = true
         end
      end
   rescue Exception
      exit(99)
   end
 
   if @listOnly == true and  @createReceipt == true then
      puts "--list and --receipt are incompatible flags"
      puts
      exit(99)
   end

   if @listUnknown == true and @listOnly == false then
      puts "--Unknown flag requires to specify --list flag"
      puts
      exit(99)
   end

   if @entity == "" and @bShowMnemonics == false then
      usage
   end

   if @isNoDB == false then
      require 'dbm/DatabaseModel'

      begin
         @dbEntity   = Interface.new
      rescue Exception => e

         if @isDebugMode == true then
            puts
            puts e.to_s
            puts
            puts e.backtrace
         end

         puts
         puts "db inventory is not configured"
         puts
         puts "you may try with \"--nodb\" flag"
         puts
         
         exit(99)
      end


      interface = Interface.find_by_name(@entity)
      
      if interface == nil then
         puts "\n#{@entity} is not a registered I/F ! :-("
         puts "\ntry registering them with addInterfaces2Database.rb tool !  ;-) \n\n"
         exit(99)
      end
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
            puts "=== Data Collector Component Registered I/Fs ==="
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

   cnf = CTC::ReadInterfaceConfig.instance

   if cnf.exists?(@entity) == false
      puts "\n#{@entity} is not a configured I/F ! :-("
      puts "\nConfigure it in interfaces.xml config file !  ;-) \n\n"
      exit(99)      
   end 
      
   init
   
   begin
   	@receiver = DCC::DCC_ReceiverFromInterface.new(@entity, true, @isNoDB, @isNoIntray, @isDelUnknown)
   rescue Exception => e
      puts "ERROR in DCC::DCC_ReceiverFromInterface.new(#{@entity})"
      puts
   	puts e.to_s
      puts
      puts e.backtrace
      puts
   	exit(99)
   end
      
   if @isDebugMode == true then
      @receiver.setDebugMode
   end

   if @isBenchMark == true then
      @receiver.isBenchmarkMode = true
   end   

   body
   
   @locker.release
   exit(0)
end

#-------------------------------------------------------------

# It sets up the process.
# The process is registered and checked with #CheckerProcessUniqueness
# class.
def init  
   @locker = CUC::CheckerProcessUniqueness.new(File.basename($0), @entity, true) 
   if @locker.isRunning == true then
      puts "\n#{File.basename($0)} to #{@entity} is already running !\n\n"
      exit(99)
   end  
   # Register in lock file the daemon
   @locker.setRunning
   @incomingDir = CTC::ReadInterfaceConfig.instance.getIncomingDir(@entity)
end
#-------------------------------------------------------------

def body
   puts "Polling #{@entity} Interface"
   
   @entityConfig  = CTC::ReadInterfaceConfig.instance
   bRegisterDir   = @entityConfig.registerDirContent?(@entity)
   
   # GOCEPMF-SPR-008 DCC must be able to track file availability without
   # download them
   bRetrieveFiles = @entityConfig.retrieveDirContent?(@entity)
   
   #----------------------------------------------
   if bRegisterDir == false or @listOnly == true and @isNoDB == false then
      puts
      puts "File Tracking  is disabled"
   end
   #----------------------------------------------   

   if bRetrieveFiles == false or @listOnly == true then
      puts
      puts "File Retrieval is disabled"
   end
    

   if @listUnknown == true then
      puts
      puts "List of Unknown files:" 
      bNewFiles   = @receiver.check4NewFiles
      listOfFiles = @receiver.getUnknownFiles
      listOfFiles.each{|fullpath|
         puts File.basename(fullpath)
      }
      puts
      exit(0)
   end


   # Track new files
	if (@createReceipt == true) or (bRegisterDir == true) or (@listOnly == true) then
      bNewFiles = @receiver.check4NewFiles(true)

      if bNewFiles == false then
		   if @isNoDB == false then   
            puts "\nNo file(s) available from #{@entity} I/F for tracking\n"
            @logger.info("No file(s) available from #{@entity} I/F for tracking")
         end
      else
         
         listOfFiles = @receiver.getAvailablesFiles
         
         if @isNoDB == false then
            puts "\nNew file(s) available from #{@entity} I/F for tracking\n"
            @logger.info("New file(s) available from #{@entity} I/F for tracking")            
         
            listOfFiles.each{|fullpath|
               puts File.basename(fullpath)
            }
            puts
         end

         if @listUnknown == true then
            exit(0)
         end
#          if bRegisterDir == true then
#             @receiver.createListFile(ENV['DCC_TMP'])         
#          else
#             @receiver.createListFile(Dir.pwd, false)
#          end
         if @createReceipt == true then
            @receiver.createListFile(Dir.pwd, false)
         else
            if bRegisterDir == true and @listOnly == false then
               @receiver.createListFile(ENV['DCC_TMP'])
            end
         end
      end
	end

   #----------------------------------------------
   # Retrieve new files   
   event  = CTC::EventManager.new
   if @isDebugMode == true then
      event.setDebugMode
   end

   bNewFiles = false

   if bRetrieveFiles == true or @listOnly == true then
      bNewFiles     = @receiver.check4NewFiles
      if bNewFiles == false then
         puts "\nNo file(s) available from #{@entity} I/F for retrieving\n"
         @logger.info("No file(s) available from #{@entity} I/F for retrieving")
         event.trigger(@entity, "ONRECEIVEOK")
      else
         puts "\nNew file(s) available from #{@entity} I/F for retrieving\n"
         @logger.info("New file(s) available from #{@entity} I/F for retrieving")
         listOfFiles = @receiver.getAvailablesFiles
         listOfFiles.each{|fullpath|
            puts File.basename(fullpath)
         }
         puts
         if @listOnly == false and @createReceipt == false then
            ret = @receiver.receiveAllFiles
            
#             # Create Report File
#             @receiver.createReportFile(@incomingDir, true, @createReport)

            if ret == true then
               event.trigger(@entity, "ONRECEIVENEWFILESOK")
            else
               event.trigger(@entity, "ONRECEIVEERROR")
            end

         end

      end

      # Creating Reports if configured
      if @listOnly == false then
         @receiver.createReportFile(@incomingDir, true, @createReport)
      end

      # Now, "nominal" dissemination is performed in DCC_ReceiverFromInterface
      # for each file received. But we want the possibility to try again the inbox
      # in case some files are placed there from previous polling

      # 20160907 - dissemination is only activated if new files have been downloaded
      # Disseminate files retrieved to In-Trays
#      if bNewFiles == true and @listOnly == false then
      if @listOnly == false and @isNoIntray == false and bNewFiles == true then
         deliverer = DCC::FileDeliverer2InTrays.new
# 	      if @isDebugMode == true then
# 	         deliverer.setDebugMode
# 	      end
	      deliverer.deliver(@entity)
      end	
   end
   #----------------------------------------------
   
   
end
#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -45 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
   exit   
end
#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
