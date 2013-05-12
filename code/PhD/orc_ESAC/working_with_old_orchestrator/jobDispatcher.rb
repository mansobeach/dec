#!/usr/bin/env ruby

# == Synopsis
#
# This is a MINARC command line tool that registers production sensing time. 
# 
# 
# -f flag:
#
# Mandatory flag. This option is used to specify the file to be registered. 
#
#
# -L flag:
#
# Optional flag. This is the location of the processors working directory.
# From there <job-id> inputs / control / outputs / folders are created & used.
# Job-order file to be generated is placed in the control directory meanwhile
# all inputs referenced inside are pointed to <location>/inputs. Same procedure
# is applicable to the outputs that are placed in <location>/outputs 
#
#
# -F flag:
#
# Optional flag. Force flag. It creates the job-order even when timeline has
# already been processed.
#
#
# == Usage
# jobDispatcher.rb  -f <triggerFile>  --id <job-id> [-L <path>]
#     --file <triggerFile>       trigger file
#     --Location <procWorkDir>   This is the Örchestrator Processors Working Dir
#     --type <file-type>         specifies production file-type to be queried
#     --Force                    it forces job-order creation
#     --help                     shows this help
#     --usage                    shows the usage
#     --Debug                    shows Debug info during the execution
#     --version                  shows version number
#
# 
# == Author
# DEIMOS-Space S.L. (BOLF)
#
#
# == Copyright
# Copyright (c) 2009 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# === Ruby source for #jobDispatcher.rb module
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS -> ORC Component
# 
# CVS: $Id: jobDispatcher.rb,v 1.3 2009/02/16 18:26:21 decdev Exp $
#
# module ORC
#
#########################################################################


require 'getoptlong'
require 'rdoc/usage'

require 'cuc/DirUtils'
require 'cuc/EE_ReadFileName'

require 'orc/ORC_DataModel'
require 'orc/PriorityRulesSolver'
require 'orc/WriteJobOrderFile'


# MAIN script function
def main

   include CUC::DirUtils

   @full_path_filename     = ""
   @full_path_dir          = ""
   @jobId                  = ""
   @triggerName            = ""
   @isDebugMode            = false
   @bShowQueue             = false
   @bList                  = false
   @bShowVersion           = false
   @bForceCreation         = false
   
   opts = GetoptLong.new(
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
     ["--Location", "-L",        GetoptLong::REQUIRED_ARGUMENT],
     ["--id", "-i",              GetoptLong::REQUIRED_ARGUMENT],
     ["--Show", "-S",           GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",           GetoptLong::NO_ARGUMENT],
     ["--list", "-l",            GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"       then @isDebugMode  = true
            when "--Show"        then @bShowQueue   = true
            when "--list"        then @bList        = true
            when "--version"     then @bShowVersion = true
	         when "--file"        then @full_path_filename = arg.to_s
            when "--Location"    then @full_path_dir      = arg.to_s
	         when "--id"          then @jobId              = arg.to_s.to_i
	         when "--trigger"     then @triggerName        = arg.to_s
            when "--Force"       then @bForceCreation     = true
			   when "--help"        then RDoc::usage
	         when "--usage"       then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end
 
   solver = ORC::PriorityRulesSolver.new
 
   if @isDebugMode == true then
      solver.setDebugMode
   end
      
   if @bShowQueue == true then
      puts
      solver.showQueue
      puts
   end
      
   newTrigger = solver.getNextResolved
   
   if newTrigger != nil then
      print newTrigger.filename
   else
      print ""
   end   
   
   exit(0)

end

#-------------------------------------------------------------

#-------------------------------------------------------------

#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
