#!/usr/bin/env ruby

# == Synopsis
# This is a command line tool that *** DELETES *** ALL NRTP working directories content.
#
#
#
# == Usage
# nrtp_dirs_cleanup.rb   [-Y]
#   --YES                confirmation flag
#   --Verbose            execution in verbose mode
#   --version            shows version number
#   --help               shows this help
#   --usage              shows the usage
#
#
# == Author
# Deimos-Space S.L. (bolf)
#
#
# == Copyright
# Copyright (c) 2009 ESA - Deimos Space S.L.
#

#########################################################################
#
# === SMOS Near Real-Time Processor
# 
# CVS: $Id: nrtp_dirs_cleanup.rb,v 1.1 2009/03/12 10:06:20 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'orc/ReadOrchestratorConfig'


# Global variables
@@dateLastModification = "$Date: 2009/03/12 10:06:20 $"   # to keep control of the last modification
                                     # of this script
@@verboseMode     = 0                # execution in verbose mode
@@hostfilepath    = ""
@@jobOrderName    = ""
@@processorPath   = ""
@@targetPID       = 0

# MAIN script function
def main
   @isDebugMode = false
   @isConfirmed = false
  
   
   opts = GetoptLong.new(
     ["--YES", "-Y",            GetoptLong::NO_ARGUMENT],
     ["--Verbose", "-V",        GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Verbose"       then @@verboseMode = 1
            when "--Debug"         then @isDebugMode = true
            when "--version" then
               print("\nESA - Deimos-Space S.L.  NRTP ", File.basename($0), " $Revision: 1.1 $  [", @@dateLastModification, "]\n\n\n")
               exit (0)
            when "--YES" then
               @isConfirmed = true    
            when "--help"          then RDoc::usage
            when "--usage"         then RDoc::usage("usage")
            when "--Show"          then @@bShowMnemonics = true
         end
      end
   rescue Exception
      exit(99)
   end


   if (@isConfirmed == false) then RDoc::usage end
   
   cleanDirs

   deleteLogs

   exit(0)
end
#===============================================================================

def cleanDirs

   puts
   puts "*** Orchestrator dirs clean-up ***"
   puts

   @orcConfig  = ORC::ReadOrchestratorConfig.instance

   @successDir = @orcConfig.getSuccessDir
   @failureDir = @orcConfig.getFailureDir
   @workingDir = @orcConfig.getProcWorkingDir
   @pollingDir = @orcConfig.getPollingDir
   @statusDir  = ENV['NRTP_HMI_TMP']

   cmd = "\\rm -rf #{@statusDir}/*"
   puts cmd
   puts
   system(cmd)

   cmd = "\\rm -rf #{@successDir}/*"
   puts cmd
   puts
   system(cmd)

   cmd = "\\rm -rf #{@failureDir}/*"
   puts cmd
   puts
   system(cmd)

   cmd = "\\rm -rf #{@pollingDir}/*"
   puts cmd
   puts
   system(cmd)

   cmd = %Q{mkdir -p #{@pollingDir}/_TEMP_}
   puts cmd
   puts
   system(cmd)

   cmd = "\\rm -rf #{@workingDir}/*"
   puts cmd
   puts
   system(cmd)

end

#===============================================================================

def deleteLogs
   puts
   puts "*** Deleting Logs ***"
   puts
   cmd = "\\rm -f #{ENV['LOGTOOL_LOG_DIR']}/*"
   puts cmd
   puts
   system(cmd)
end

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
