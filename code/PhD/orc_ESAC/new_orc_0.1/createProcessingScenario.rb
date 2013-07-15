#!/usr/bin/env ruby

# == Synopsis
#
# This is an Orchestrator command line tool that gathers input files
# referenced in a job-order file. 
# 
# 
# -f flag:
#
# Mandatory flag. This option is used to specify the job-order file to be processed. 
#
#
#
# -H flag:
#
# Optional flag. This flag activates MINARC Hard-Link retrieval feature.
#
#
# == Usage
# createProcessingScenario.rb  -f <full_path_job_order> [-H]
#     --file <job_order>         job-order file full path name
#     --H                        activates MINARC Hard-Link retrieval
#     --list                     list mode on
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
# === Ruby source for #createProcessingScenario.rb module
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS -> ORC Component
# 
# CVS: $Id: createProcessingScenario.rb,v 1.3 2009/02/17 18:57:47 decdev Exp $
#
# module ORC
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'cuc/DirUtils'
require 'cuc/EE_ReadFileName'

require 'orc/ORC_DataModel'
require 'orc/ReadJobOrderFile'


# MAIN script function
def main

   include CUC::DirUtils

   @full_path_filename     = ""
   @full_path_dir          = ""
   @jobOrderName           = ""
   @isDebugMode            = false
   @isHardLinked           = false
   @bList                  = false
   @bShowVersion           = false
   @bShowFileTypes         = false
   
   opts = GetoptLong.new(
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
     ["--id", "-i",              GetoptLong::REQUIRED_ARGUMENT],
     ["--Hard", "-H",            GetoptLong::NO_ARGUMENT],
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
            when "--Hard"        then @isHardLinked = true
            when "--list"        then @bList        = true
            when "--version"     then @bShowVersion = true
	         when "--file"        then @full_path_filename = arg.to_s
			   when "--help"        then RDoc::usage
	         when "--usage"       then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end
 
   if @full_path_filename == "" then
      RDoc::usage("usage")
   end

   @jobFile = @full_path_filename

   parser = ORC::ReadJobOrderFile.new(@jobFile)

   arrInputs   = parser.getInputsList
   arrOutputs  = parser.getOutputsList

   retVal = true

   directory = parser.getControlFolder

   if @bList == false then
      checkDirectory(directory)
      cmd = "\\cp -f #{@jobFile} #{directory}"
      if @isDebugMode == true then
         puts cmd
      end
      system(cmd)
   end

   arrInputs.each{|input|
   
      fileName    = input[:fileName]
      directory   = input[:directory]

      if @bList == false then
         checkDirectory(directory)
      end

      cmd = "minArcRetrieve.rb -f #{fileName} -L #{directory}"

      if @isHardLinked == true then
         cmd = "#{cmd} -H"
      end

      if @isDebugMode == true then
         # cmd = "#{cmd} -D"
         puts cmd
      end

      if @bList == false then
         ret = system(cmd)         
         if ret == false then
            retVal = false
         end
      end
   }

   arrOutputs.each{|anOutput|
      dir = anOutput[:directory]
      if @bList == false then
         checkDirectory(dir)
      end
   }

   if retVal == true then
      exit(0)
   else
      exit(99)
   end

end

#-------------------------------------------------------------

#-------------------------------------------------------------

#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
