#!/usr/bin/env ruby

# == Synopsis
#
# This is a DCC command line tool that polls for mails notifications sent 
# to the DCC email account (see $DCC_CONFIG/ft_mail_config.xml). 
# 
# == Usage
# getMailNotification.rb
#   --NOT       special flag for not deleting retrieved mails
#               (will be retrieved again in a next execution)
#   --help      shows this help
#   --usage     shows the usage
#   --Debug     shows Debug info during the execution
#   --version   shows version number
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
# CVS:
#   $Id: getMailNotification.rb,v 1.3 2008/07/03 11:38:07 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'cuc/Log4rLoggerFactory'
require 'cuc/CheckerProcessUniqueness'
require 'dcc/DCC_MailProcessor'
require 'dcc/ReadConfigDCC'

# Global variables
@@dateLastModification = "$Date: 2008/07/03 11:38:07 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info
@mnemonic          = ""

# MAIN script function
def main
   
   @isDebugMode   = false
   @listOnly      = false
   @delete        = true
   
   opts = GetoptLong.new(
     ["--mnemonic", "-m",       GetoptLong::REQUIRED_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
	  ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--NOT", "-N",            GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--list", "-l",           GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"   then @isDebugMode = true
            when "--NOT"     then @delete = false
            when "--version" then	    
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.3 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
	         when "--mnemonic" then
               @mnemonic = arg
            when "--list" then
                @listOnly = true
			   when "--help"          then RDoc::usage
	         when "--usage"         then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end
 
   init
   body  
   @locker.release
   exit(0)
end

#-------------------------------------------------------------

# It sets up the process.
# The process is registered and checked with #CheckerProcessUniqueness
# class.
def init

   # initialize logger
   loggerFactory = CUC::Log4rLoggerFactory.new("getMailNotification", "#{ENV['DCC_CONFIG']}/dec_log_config.xml")
   if @isDebugMode then
      loggerFactory.setDebugMode
   end
   @logger = loggerFactory.getLogger
   if @logger == nil then
      puts
		puts "Error in getMailNotification::init"
		puts "Could not set up logging system !  :-("
      puts "Check DEC logs configuration under \"#{ENV['DCC_CONFIG']}/dec_log_config.xml\"" 
		puts
		puts
		exit(99)
   end

   @locker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true) 
   if @locker.isRunning == true then
      puts "\n#{File.basename($0)} is already running !\n\n"
      exit(99)
   end  

   # Register in lock file the daemon
   @locker.setRunning

   @projectName = DCC::ReadConfigDCC.instance.getProjectName
   @projectID   = DCC::ReadConfigDCC.instance.getProjectID
end
#-------------------------------------------------------------

def body
   puts "Polling #{@projectName} DCC Mail"
	@logger.info("Polling #{@projectName} DCC Mail ...")
   @mailer = DCC::DCC_MailProcessor.new   
   if @isDebugMode == true then
      @mailer.setDebugMode
   end
   @mailer.processAll(@delete)
end
#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
