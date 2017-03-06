#!/usr/bin/env ruby

# == Synopsis
#
# This is a DCC command line tool that checks the coherency of the DCC configuration.
# DCC configuration is distributed among different XMl files. The information set up
# must be coherent. This tool ensures that all configuration critical elements are correct.
# (All DCC config files must be placed in the $DCC_CONFIG directory). 
# So, run this tool everytime a configuration change is performed.
#
# -e flag:
#
# With this option the Interfaces (Entities) configuration placed in interfaces.xml
# is checked. As well it is checked the coherency between the interfaces.xml
# configuration file and the DCC Inventory (DCC Database).
# (Note: if the network link to a given I/F is broken, the tool will not be able to connect and it
# will report a configuration error of this I/F).
#
#
# -i flag:
#
# With this option the Incoming file-types registered in the ft_incoming_files.xml are checked.
# Mainly what it is done is to check that the interfaces from a File is retrieved are configured in 
# the interfaces.xml file.
#
#
# -m flag:
#
# With this option the DCC Mail configuration placed in the ft_mail_config.xml is checked.
#
#
# -s flag:
#
# With this option the DCC Services configured in the dcc_services.xml file are checked.
# The check performed with this flag is that the executable set in the command of the service
# can be found in the $PATH environment variable.
#
#
# -t flag:
#
# With this option the (DIM)In-Trays configured in the files2InTrays.xml file are checked.
# Mainly it is checked the consistency of the files2InTrays.xml config file.
# As well it is checked the coherency between file2Dims.xml and ft_incoming_files.xml
# warning when an incoming file is not disseminated to any In-Tray.
#
#
# -a flag:
#
# This is the all flag, which performs all the checks described before.
#
#
# == Usage
# checkConfigDCC.rb [--nodb]
#     -a    checks all DCC configuration
#     -e    checks entities configuration in interfaces.xml
#    --nodb no Inventory checks
#     -i    checks incoming file-types configured in ft_incoming_files.xml
#     -m    checks the mail configuration placed in ft_mail_config.xml
#     -t    checks the In-Trays configuration placed in files2InTrays.xml
#     -l    checks the log configuration
#     -h    it shows the help of the tool
#     -u    it shows the usage of the tool
#     -v    it shows the version number
#     -V    it performs the execution in Verbose mode
#     -D    it performs the execution in Debug mode     
# 
# == Author
# DEIMOS-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2005 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# Data Collector Component
# 
# CVS: $Id: checkConfigDCC.rb,v 1.7 2007/12/18 18:21:36 decdev Exp $
#
#########################################################################

require 'rubygems'
require 'getoptlong'
require 'rdoc'

require 'cuc/Log4rLoggerFactory'
require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadFileSource'
require 'ctc/CheckerMailConfig'
require 'ctc/CheckerInterfaceConfig'
require 'ctc/CheckerIncomingFileConfig'
require 'dcc/ReadInTrayConfig'
require 'dcc/ReadConfigDCC'
require 'dcc/CheckerInTrayConfig'
require 'dcc/CheckerServiceConfig'

# Conditional require driven by --nodb flag
# require 'ctc/CheckerInventoryConfig'

# checkSent2Entity checks what it has been sent to a given entity.
# It checks in the UploadDir and UploadTemp directories 

# Global variables
@dateLastModification = "$Date: 2007/12/18 18:21:36 $" 
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
@isNoDB           = false
@bLog             = false

# MAIN script function
def main

   opts = GetoptLong.new(     
     ["--all", "-a",            GetoptLong::NO_ARGUMENT],
	  ["--log", "-l",            GetoptLong::NO_ARGUMENT],
     ["--incoming", "-i",       GetoptLong::NO_ARGUMENT],
     ["--tray", "-t",           GetoptLong::NO_ARGUMENT],
     ["--entities", "-e",       GetoptLong::NO_ARGUMENT],
     ["--mail", "-m",           GetoptLong::NO_ARGUMENT],
     ["--services", "-s",       GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--Verbose", "-V",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--nodb", "-n",           GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt
            when "--Debug"   then @isDebugMode   = true
            when "--Verbose" then @isVerboseMode = true
            when "--version" then
               print("\nESA - DEIMOS-Space S.L.  Data Collector Component ", File.basename($0), " $Revision: 1.7 $  [", @dateLastModification, "]\n\n\n")
               exit(0)
            when "--help"     then usage
            when "--nodb"     then @isNoDB    = true
            when "--incoming" then @bIncoming = true
            when "--entities" then @bEntities = true
            when "--services" then @bServices = true
	         when "--mail"     then @bMail     = true
            when "--all"      then @bAll      = true
            when "--tray"     then @bTrays    = true
				when "--log"      then @bLog      = true
            when "--usage"    then usage
         end
      end
   rescue Exception
     exit(99)
   end
 
   if @bIncoming == false and @bOutgoing == false and @bClients == false and
      @bEntities == false and @bAll == false and @bMail == false and 
      @bServices == false and @bTrays == false and @bLog == false then
      usage
   end
   
   # Check Module Integrity
   checkModuleIntegrity

   @projectName = DCC::ReadConfigDCC.instance.getProjectName
   @projectID   = DCC::ReadConfigDCC.instance.getProjectID
   
   ftConfig = CTC::ReadInterfaceConfig.instance
   arrEnts  = ftConfig.getAllMnemonics

   puts "\nChecking #{@projectName} Data Collector Component \n\n"

   # Check of the Entities Configuration
   
   if @bEntities == true or @bAll == true then
      puts "================================================"
      puts "Checking interfaces.xml Configuration ..."
      arrEnts.each{|x|
         bEnabled4Send = ftConfig.isEnabled4Sending?(x)
         bEnabled4Recv = ftConfig.isEnabled4Receiving?(x)

         if ftConfig.isEnabled4Receiving?(x) == false then
            puts
            puts "#{x} is disabled for receive ... :-|"
            next
         end


		   checker = CTC::CheckerInterfaceConfig.new(x, bEnabled4Recv, false)
                 if @isDebugMode == true or @isVerboseMode then
                   checker.setDebugMode
                 end
                 retVal     = checker.check

                 if retVal == true then
                    puts "\n#{x} I/F is configured correctly ! :-) \n"
                 else
                    puts "\n#{x} I/F is not configured correctly ! :-( \n"
                 end
      }      
      puts "================================================"

      if @isNoDB == false then
         require 'ctc/CheckerInventoryConfig'
      
         # Perform the check against the Inventory
         puts "Checking DCC/Inventory entries ..."
         checkerInventory = CTC::CheckerInventoryConfig.new
         ret = checkerInventory.check
         puts "================================================"
         if ret == false then
            puts "\ntry registering them with addInterfaces2Database.rb tool !  ;-) \n\n"
         end
      end
      
   end

   # Check that all Incoming File Types have associated Entities registered
   # in interfaces.xml
   
   if @bIncoming == true or @bAll == true then
      ftReadIncoming   = CTC::ReadFileSource.instance   
      arrIncomingFiles = ftReadIncoming.getAllIncomingFiles  
      puts
      puts "================================================"
      puts "Checking ft_incoming_files.xml Configuration ..."
      puts
      ret = true
      arrIncomingFiles.each{|x|
         puts "Check incoming filetype #{x} \n"

	      checker = CTC::CheckerIncomingFileConfig.new(x)
	 
         retVal  = checker.check
         
         if retVal == false then ret = false end
         
         if retVal == true and @isVerboseMode == true then
            puts "#{x} - OK"
            puts
         end
      }
   
      arrIncomingFiles = ftReadIncoming.getAllIncomingFileNames  

      arrIncomingFiles.each{|x|
         puts "Check incoming files like #{x} \n"

	      checker = CTC::CheckerIncomingFileConfig.new(x)
	 
         retVal  = checker.check
         
         if retVal == false then ret = false end
         
         if retVal == true and @isVerboseMode == true then
            puts "#{x} - OK"
            puts
         end
      }


      if ret == true then
         puts "\nft_incoming_files.xml is configured correctly ! :-) \n"
      else
         puts "\nft_incoming_files.xml is not configured correctly ! :-( \n"
      end     
      puts "================================================"
   end

#==============================================================================

#==============================================================================

   if @bAll == true or @bTrays == true then
      puts "================================================"
      puts "Checking files2InTrays.xml Configuration ..."
      puts
      
      checker = DCC::CheckerInTrayConfig.new
	   
      if @isDebugMode == true then
         checker.setDebugMode
      end
      
      retVal  = checker.check
      
      if retVal == true then
         puts "\nfiles2InTrays.xml is configured correctly ! :-) \n"
      else
         puts "\nfiles2InTrays.xml is not configured correctly ! :-( \n"         
      end      
      
      puts "================================================"            
   end

#==============================================================================

   if @bAll == true or @bMail == true then
      puts "================================================"
      puts "Checking ft_mail_config.xml Configuration ..."
      puts
 
      mailChecker = CTC::CheckerMailConfig.new
      
      if @isDebugMode == true or @isVerboseMode then
         mailChecker.setDebugMode
      end
      
      retVal = mailChecker.check(false, true)
      
      if retVal == true then
         puts "\nft_mail_config.xml is configured correctly ! :-) \n"
      else
         puts "\nft_mail_config.xml is not configured correctly ! :-( \n"
      end
      puts "================================================"         
   end
	
	
	if @bAll == true or @bLog == true then
		begin
	   # initialize logger
   	loggerFactory = CUC::Log4rLoggerFactory.new("getFromInterface", "#{ENV['DCC_CONFIG']}/dec_log_config.xml")
		rescue Exception => e
		   puts
      	puts e.to_s
			puts
   	end
	end
   
#    # Check that dcc_services.xml is correctly configured
# 
#    if @bAll == true or @bServices == true then
# #      puts
#       puts "================================================"
#       puts "Checking dcc_services.xml Configuration ..."
#       puts
#  
#       checker = DCC::CheckerServiceConfig.new
#       
#       if @isDebugMode == true or @isVerboseMode then
#          checker.setDebugMode
#       end
#       
#       retVal = checker.check
#       
#       if retVal == true then
#          puts "\ndcc_services.xml is configured correctly ! :-) \n"
#       else
#          puts "\ndcc_services.xml is not configured correctly ! :-( \n"
#       end
#       puts "================================================"         
#    end
   
   
end

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -72 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
   exit   
end
#-------------------------------------------------------------

#-------------------------------------------------------------
   
# Check that everything needed by the class is present.
def checkModuleIntegrity
   return
end 
#-------------------------------------------------------------

#==========================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
