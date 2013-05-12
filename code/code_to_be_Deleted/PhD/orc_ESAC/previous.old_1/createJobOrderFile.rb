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
# Optional flag. This is the location of the processor working directory.
# From there inputs / control / outputs / folders are used.
# Job-order file to be generated is placed in the control directory meanwhile
# all inputs referenced inside are pointed to <location>/inputs. Same procedure
# is applicable to the outputs that are placed in <location>/outputs 
#
#
# -T flag:
#
# Optional flag.
#
#
# == Usage
# createJobOrderFile.rb  -f <triggerFile>  --id <job-id> [-L <path>]
#     --file <triggerFile>       trigger file
#     --list                     it lists production timeline
#     --type <file-type>         specifies production file-type to be queried
#     --Types                    it shows production file-types
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
# === Ruby source for #createJobOrderFile.rb module
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS -> ORC Component
# 
# CVS: $Id: createJobOrderFile.rb,v 1.2 2009/02/16 12:13:13 decdev Exp $
#
# module ORC
#
#########################################################################


require 'getoptlong'
require 'rdoc/usage'

require 'cuc/DirUtils'
require 'cuc/EE_ReadFileName'

require 'orc/ORC_DataModel'
require 'orc/DependenciesSolver'
require 'orc/WriteJobOrderFile'


# MAIN script function
def main

   include CUC::DirUtils

   @full_path_filename     = ""
   @full_path_dir          = ""
   @jobId                  = ""
   @triggerName            = ""
   @isDebugMode            = false
   @bList                  = false
   @bShowVersion           = false
   @bShowFileTypes         = false
   
   opts = GetoptLong.new(
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
     ["--Location", "-L",        GetoptLong::REQUIRED_ARGUMENT],
     ["--id", "-i",              GetoptLong::REQUIRED_ARGUMENT],
     ["--Types", "-T",           GetoptLong::NO_ARGUMENT],
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
            when "--list"        then @bList        = true
            when "--version"     then @bShowVersion = true
	         when "--file"        then @full_path_filename = arg.to_s
            when "--Location"    then @full_path_dir      = arg.to_s
	         when "--id"          then @jobId              = arg.to_s.to_i
	         when "--trigger"     then @triggerName        = arg.to_s
            when "--Types"       then @bShowFileTypes     = true
			   when "--help"        then RDoc::usage
	         when "--usage"       then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end
 
   if @full_path_filename == "" or @jobId == "" then
      RDoc::usage("usage")
   end

   @triggerFile = File.basename(@full_path_filename)

   depSolver = ORC::DependenciesSolver.new(@triggerFile)

   if @isDebugMode == true then
      depSolver.setDebugMode
   end

   ret = depSolver.init

   if ret == false then
      puts "Trigger requested sensing shall not be processed ! :-|"
      puts
      exit(99)
   end
   
   ret = depSolver.resolve

   if ret == false then
      puts
      puts "Trigger requested cannot be processed yet ! :-|"
      puts
      exit(99)
   end

   arrInputs = depSolver.getJobInputs

   if arrInputs.empty? == true then
      puts
      puts "No Applicable Inputs found for Trigger ! :-|"
      puts
      exit(99)
   end

   
   arrOutputTypes = depSolver.getOutputTypes


   if @isDebugMode == true then
      puts "=========================( INPUTS )========================="
   end
   
   arrInputs.each{|input|
      if @isDebugMode == true then
         puts input[:filename]
      end
   }   

   if @isDebugMode == true then
      puts "=========================( OUTPUTS )========================"
      arrOutputTypes.each{|output|
         puts output
      }   
   end


   if @isDebugMode == true then
      puts "============================================================"
   end


   if @full_path_dir == "" then
      exit(0)
   end

   strStart = depSolver.getStartWindow
   strStop  = depSolver.getStopWindow

   sequence = "001"
   counter  = "001"
   site_id  = ENV['NRTP_SITE_ID']

   dirControl = "#{@full_path_dir}/control"
   dirInputs  = "#{@full_path_dir}/inputs"
   dirOutputs = "#{@full_path_dir}/outputs"

   checkDirectory(dirControl)
   checkDirectory(dirInputs)
   checkDirectory(dirOutputs)

   writer   = ORC::WriteJobOrderFile.new(dirControl, strStart, strStop, @jobId, counter, sequence, site_id)

   if @isDebugMode == true then
      writer.setDebugMode
   end

   writer.writejob(arrInputs, arrOutputTypes, @full_path_dir)

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
