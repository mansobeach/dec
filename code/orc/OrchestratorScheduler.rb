#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #OrchestratorScheduler class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS => ORC Component
# 
# CVS: $Id: OrchestratorScheduler.rb,v 1.2 2008/12/16 11:45: decdev Exp $
#
# module ORC
#
#########################################################################


require 'cuc/Log4rLoggerFactory'
require 'orc/ORC_DataModel'

module ORC


class OrchestratorScheduler

   #-------------------------------------------------------------
  
   # Class constructor

   def initialize(log)
      checkModuleIntegrity
      @logger           = log
      @orcTmpDir        = ENV['ORC_TMP']
      @isDebugMode      = false
      @arrQueuedFiles   = Array.new
   end
   #-------------------------------------------------------------

   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   #-------------------------------------------------------------   

   def start
   end
   #-------------------------------------------------------------

private

	#-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
   
      if !ENV['ORC_TMP'] then
         puts "ORC_TMP environment variable not defined !  :-(\n"
         bCheckOK = false
         bDefined = false
      end

      if bCheckOK == false then
         puts "OrchestratorScheduler::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end

   end
   #-------------------------------------------------------------

   # This method loads from database queued files
   def getQueuedFiles
      # Gather from database queued files
      return OrchestratorQueue.getQueuedFiles
   end
   #-------------------------------------------------------------

   def getFilesToBeQueued
      # Gather from database files to be queued
      # 
   end
   #-------------------------------------------------------------

   def queueFile(filename)
   end
   #-------------------------------------------------------------

end # class

end # module
