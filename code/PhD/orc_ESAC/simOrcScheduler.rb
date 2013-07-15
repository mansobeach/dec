#!/usr/bin/env ruby

# == Synopsis
#
# This is a Data Exchange Component command line tool that synchronizes the Entities configuration file
# with DEC Inventory. It extracts all the I/Fs from the interfaces.xml file and 
# inserts them in the DEC Inventory.
#
# As well it allows to specify a new I/F mnemonic to be loaded into the DEC Inventory with 
# the "--add" command line option.
#
# == Usage
# simHMI.rb
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2007 ESA - Deimos Space S.L.
#

#########################################################################
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: simOrcScheduler.rb,v 1.1 2009/03/12 10:05:25 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'cuc/Listener'
require 'cuc/EE_ReadFileName'

require 'orc/ORC_DataModel'
require 'orc/ReadOrchestratorConfig'

require 'ProcessHandler'

# Global variables
@@dateLastModification = "$Date: 2009/03/12 10:05:25 $"   # to keep control of the last modification
                                     # of this script
@@verboseMode     = 0                # execution in verbose mode
@@mnemonic        = ""
@@bShowMnemonics  = false
@@numProcesses    = 0
@@numScenes       = 0

# MAIN script function
def main
   @isDebugMode = false
   @commandNRTP = ""
   @sleepAgain  = true
   
   opts = GetoptLong.new(
     ["--command", "-c",        GetoptLong::REQUIRED_ARGUMENT],
     ["--Show", "-S",           GetoptLong::NO_ARGUMENT],
     ["--Verbose", "-V",        GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--scenes", "-s",         GetoptLong::REQUIRED_ARGUMENT],
     ["--processes", "-p",      GetoptLong::REQUIRED_ARGUMENT],
     ["--PID", "-P",            GetoptLong::REQUIRED_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Verbose"       then @@verboseMode = 1
            when "--Debug"         then @isDebugMode = true
            when "--version" then
               print("\nESA - Deimos-Space S.L.  DEC ", File.basename($0), " $Revision: 1.1 $  [", @@dateLastModification, "]\n\n\n")
               exit (0)
            when "--command" then
               @commandNRTP = arg.to_s        
            when "--processes" then
               @@numProcesses = arg.to_i
            when "--scenes"    then 
               @@numScenes    = arg.to_i
            when "--help"          then RDoc::usage
            when "--usage"         then RDoc::usage("usage")
            when "--Show"          then @@bShowMnemonics = true
         end
      end
   rescue Exception
      exit(99)
   end

   @ftReadConf = ORC::ReadOrchestratorConfig.instance


   trap("USR1")   {  
                     puts "========================================"
                     puts "New Files have arrived:"
                     arrPendingFiles = Pending2QueueFile.find(:all)
                     
                     if arrPendingFiles.length == 0 then
                        puts "None of them were trigger"
                     else
                        puts "Queueing trigger files"
                     end
                     
                     arrPendingFiles.each{|aFile|
                        puts aFile.filename
                     }
                     
                     arrPendingFiles.each{|pendingFile|
                        fileName       = pendingFile.filename
                        nameDecoder    = CUC::EE_ReadFileName.new(fileName)      
                        triggerType    = nameDecoder.getFileType
                        dataType       = @ftReadConf.getDataType(triggerType)
                        coverMode      = @ftReadConf.getTriggerCoverageByInputDataType(dataType)
                        if coverMode == "NRT" then
                        end
                        cmd            = "queueOrcProduct.rb -f #{fileName} -s NRT"
                        puts cmd
                        system(cmd)
                     }
                     
                     Pending2QueueFile.delete_all
                    
                  }

   puts
   puts "----------------------------------------------"
   puts "I am ORC SCHEDULER running with pid #{Process.pid}"
   puts "----------------------------------------------"
   puts
   
   while true
      sleep
   end
   
   puts
   puts "ORC SCHEDULER Bye"
       
   
end


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
