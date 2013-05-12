#!/usr/bin/env ruby

# == Synopsis
#
# This is a MINARC command line tool that sorts orchestrator queue.
# It provides next trigger product to be executed if possible. 
# 
#
# -l flag:
#
# Optional flag. List flag. It shows the Queue SORTED.
#
#
# -S flag:
#
# Optional flag. Show flag. It shows the Queue UNSORTED.
#
#
# == Usage
# jobDispatcher.rb  [-l | -S]
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
# CVS: $Id: jobDispatcher.rb,v 1.2 2009/03/18 11:49:08 decdev Exp $
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
      
   # ---------------------------------------------
   # Get sorted Queue

   if @bList == true then
      puts
      # solver.showQueue
      arrFiles = solver.getSortedQueue
      arrFiles.each{|aFile|
         print aFile.id.to_s.ljust(4), " - ", aFile.filename, "\n"
      }
      puts
      puts "#{arrFiles.length} triggers are currently queued" 
      exit(0)
   end
   # ---------------------------------------------   
   
   # Get unsort queue
   if @bShowQueue == true then
      arrFiles = solver.getQueue
      puts
      arrFiles.each{|aFile|
         print aFile.id.to_s.ljust(4), " - ", aFile.filename, "\n"
      }
      puts
      puts "#{arrFiles.length} triggers are currently queued" 
      exit(0)
   end
   # ---------------------------------------------   

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
