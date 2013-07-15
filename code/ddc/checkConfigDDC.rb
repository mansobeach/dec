#!/usr/bin/env ruby

# == Synopsis
#
# This is a DDC command line tool that checks the coherency of the DDC configuration.
# DDC configuration is distributed among different XMl files. The information set up
# must be coherent. This tool ensures that all configuration critical elements are correct.
# (All DDC config files must be placed in the $DCC_CONFIG directory). 
# So, run this tool everytime a configuration change is performed.
#
# -e flag:
#
# With this option the Interfaces (Entities) configuration placed in interfaces.xml
# is checked. As well it is checked the coherency between the interfaces.xml
# configuration file and the DDC Inventory (DDC Database).
# (Note: if the network link to a given I/F is broken, the tool will not be able to connect and it
# will report a configuration error of this I/F).
#
#
# -m flag:
#
# With this option the DCC Mail configuration placed in the ft_mail_config.xml is checked.
#
#
# -o flag:
#
# With this option the File types configured in the ft_outgoing_files.xml file are checked.
# It is done a cross-checking with the interfaces.xml to determine that the interfaces
# receiving a given file-type are configured.
#
#
# -a flag:
#
# This is the all flag, which performs all the checks described before.
#
#
# == Usage
# checkConfigDCC.rb
#     -a    checks all DDC configuration
#     -e    checks entities configuration in interfaces.xml
#     -o    checks the outgoing file types in ft_outgoing_files.xml
#     -m    checks the mail configuration placed in ft_mail_config.xml
#     -h    it shows the help of the tool
#     -u    it shows the usage of the tool
#     -v    it shows the version number
#     -V    it performs the execution in Verbose mode
#     -D    it performs the execution in Debug mode     
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2006 ESA - Deimos Space S.L.
#

#########################################################################
#
# === Data Distributor Component
# 
# CVS: $Id: checkConfigDDC.rb,v 1.5 2007/12/19 05:34:15 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'ctc/CheckerMailConfig'
require 'ctc/CheckerInterfaceConfig'
require 'ctc/CheckerOutgoingFileConfig'
require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadFileDestination'
require 'ctc/CheckerInventoryConfig'


# checkSent2Entity checks what it has been sent to a given entity.
# It checks in the UploadDir and UploadTemp directories 

# Global variables
@@dateLastModification = "$Date: 2007/12/19 05:34:15 $" 
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

# MAIN script function
def main

   opts = GetoptLong.new(     
     ["--all", "-a",            GetoptLong::NO_ARGUMENT],
#     ["--incoming", "-i",       GetoptLong::NO_ARGUMENT],
#     ["--tray", "-t",           GetoptLong::NO_ARGUMENT],
     ["--outgoing", "-o",       GetoptLong::NO_ARGUMENT],
     ["--entities", "-e",       GetoptLong::NO_ARGUMENT],
     ["--mail", "-m",           GetoptLong::NO_ARGUMENT],
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
               print("\nESA - Deimos-Space S.L.  Data Collector Component ", File.basename($0), " $Revision: 1.5 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
            when "--help"     then RDoc::usage
#            when "--incoming" then @bIncoming = true
            when "--outgoing" then @bOutgoing = true
            when "--entities" then @bEntities = true
            when "--services" then @bServices = true
	         when "--mail"     then @bMail     = true
            when "--all"      then @bAll      = true
#            when "--tray"     then @bTrays    = true
            when "--usage"    then RDoc::usage("usage")

         end

      end
   rescue Exception
     exit(99)
   end
 
   if @bIncoming == false and @bOutgoing == false and @bClients == false and
      @bEntities == false and @bAll == false and @bMail == false and 
      @bServices == false and @bTrays == false then
      RDoc::usage("usage")
   end
   
   # Check Module Integrity
   checkModuleIntegrity
   
   ftConfig = CTC::ReadInterfaceConfig.instance
   arrEnts  = ftConfig.getAllExternalMnemonics

   puts "\nChecking Data Distributor Component Configuration \n\n"

   # Check of the Entities Configuration
   
   if @bEntities == true or @bAll == true then
#      puts
      puts "================================================"
      puts "Checking interfaces.xml Configuration ..."
#      puts
      arrEnts.each{|x|
       
         if ftConfig.isEnabled4Sending?(x) == false then
            puts
            puts "#{x} is disabled for sending ... :-|"
            next
         end
            
		 checker    = CTC::CheckerInterfaceConfig.new(x, false, true)
                 if @isDebugMode == true or @isVerboseMode then
                   checker.setDebugMode
                 end
                 # In DDC we must check only for Send
                 retVal     = checker.check

                 if retVal == true then
                    puts "\n#{x} I/F is configured correctly ! :-) \n"
                 else
                    puts "\n#{x} I/F is not configured correctly ! :-( \n"
                 end
      }      
      puts "================================================"
      
      # Perform the check against the Inventory
      puts "Checking DDC/Inventory entries ..."
      checkerInventory = CTC::CheckerInventoryConfig.new
      ret = checkerInventory.check
      puts "================================================"
      if ret == false then
         puts "\ntry registering it with addInterfaces2Database.rb tool !  ;-) \n\n"
      end
      
   end

   # Check that all Outgoing File Types have associated Entities registered
   # in interfaces.xml
   
   if @bOutgoing == true or @bAll == true then
      ftReadOutgoing   = CTC::ReadFileDestination.instance   
      arrOutgoingFiles = ftReadOutgoing.getAllOutgoingFiles  
      puts
      puts "================================================"
      puts "Checking ft_outgoing_files.xml Configuration ..."
      puts
      ret = true
      arrOutgoingFiles.each{|x|
         puts "Check outgoing filetype #{x} \n"
	 
	      checker = CTC::CheckerOutgoingFileConfig.new(x)
	 
         retVal  = checker.check
         
         if retVal == false then ret = false end
         
         if retVal == true and @isVerboseMode == true then
            puts "#{x} - OK"
            puts
         end
      }
   
      if ret == true then
         puts "\nft_outgoing_files.xml is configured correctly ! :-) \n"
      else
         puts "\nft_outgoing_files.xml is not configured correctly ! :-( \n"
      end     
      puts "================================================"
   end


#==============================================================================

   if @bAll == true or @bMail == true then
#      puts
      puts "================================================"
      puts "Checking ft_mail_config.xml Configuration ..."
      puts
 
      mailChecker = CTC::CheckerMailConfig.new
      
      if @isDebugMode == true or @isVerboseMode then
         mailChecker.setDebugMode
      end
      
      retVal = mailChecker.check(true, false)
      
      if retVal == true then
         puts "\nft_mail_config.xml is configured correctly ! :-) \n"
      else
         puts "\nft_mail_config.xml is not configured correctly ! :-( \n"
      end
      puts "================================================"         
   end
   
   # Check that dcc_services.xml is correctly configured


   
   
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
