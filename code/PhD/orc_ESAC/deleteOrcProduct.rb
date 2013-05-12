#!/usr/bin/env ruby

# == Synopsis
#
# This is an NRTP Orchestrator command line tool used to delete a trigger product from Orchestrator queues.
#
# 
# -f flag:
#
# Mandatory flag. This option is used to specify the name of the file to be deleted.  
#
#  
#
# == Usage
# deleteOrcProduct.rb -f <file-name>
#     --file <file-name>         it specifies the name of the file to be deleted from Orchestrator
#     --help                     shows this help
#     --usage                    shows the usage
#     --Debug                    shows Debug info during the execution
#     --version                  shows version number
# 
#
# == Author
# DEIMOS-Space S.L.
#
# == Copyright
# Copyright (c) 2008 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# === SMOS NRTP Orchestrator
#
# CVS: $Id: deleteOrcProduct.rb,v 1.1 2008/11/10 11:20:45 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require "cuc/EE_ReadFileName"
require "orc/ORC_DataModel"
require "orc/ReportQueuedFiles"

# Global variables
@@dateLastModification = "$Date: 2008/11/10 11:20:45 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   @bList                  = false

   #Hardcoded values
   @arrStatus = ["NRT", "MIX", "OLD", "OBS"]

   # Data provided by the user
   @filename               = ""
   @reportfilename         = ""
   @initialStatus          = "UKN"
   @bDelete                = false
   @isDebugMode            = false
   @bObsolete              = false
   @bQueued                = false
   @bSuccess               = false
   @bFailed                = false
   @bTrigger               = false

   # Data generated or extracted from filename
   @filetype               = ""
   @sensing_start          = nil
   @sensing_stop           = nil

   # Other required Data
   @detectionDate          = nil
   @runtime_satus          = "UKN"
   
   opts = GetoptLong.new(
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
     ["--Queued", "-Q",          GetoptLong::NO_ARGUMENT],
     ["--Success", "-S",         GetoptLong::NO_ARGUMENT],
     ["--Failed",  "-F",         GetoptLong::NO_ARGUMENT],
     ["--Obsolete", "-O",        GetoptLong::NO_ARGUMENT],
     ["--Trigger", "-T",         GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--list", "-l",            GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"     then @isDebugMode = true
            when "--version" then	    
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.1 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
	         when "--file"          then @filename            =  File.basename(arg.to_s)
                                        @bIngest             = true
            when "--delete"        then @filename            =  File.basename(arg.to_s)
                                        @bDelete             = true
            when "--Report"        then @reportfilename      =  arg.to_s
            when "--list"          then @bList               =  true
            when "--Obsolete"      then @bObsolete           =  true
            when "--Queued"        then @bQueued             =  true
            when "--Trigger"       then @bTrigger            =  true
            when "--Success"       then @bSuccess            =  true
            when "--Failed"        then @bFailed             =  true
            when "--status"        then @initialStatus       = (arg.to_s).upcase[0..2]
			   when "--help"          then RDoc::usage
	         when "--usage"         then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end

   ######################## Coherency Checks & Data Extraction ########################

   if @filename == ""  then
      puts
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   #----------------------------------------------

   queuedFile = TriggerProduct.find(:first, :conditions => "filename = '#{@filename}'")

   if queuedFile == nil then
      exit(0)
   end

   ObsoleteTriggerProduct.delete(queuedFile.id)
   FailingTriggerProduct.delete(queuedFile.id)
   SuccessfulTriggerProduct.delete(queuedFile.id)
   OrchestratorQueue.delete(queuedFile.id)
   TriggerProduct.delete(queuedFile.id)

   exit(0)

end

#-------------------------------------------------------------

#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
