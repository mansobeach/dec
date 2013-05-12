#!/usr/bin/env ruby

# == Synopsis
#
# This is a MINARC command line tool that creates the job-order file
# for a given trigger-product. 
# 
# 
# -f flag:
#
# Mandatory flag. This option is used to specify the trigger file. 
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
# -O flag:
#
# Optional flag. Operational flag. This option is used to specify 
# that createJobOrderFile works in Operational mode, which means that if required, PhD persistent queues are
# updated.
#
#
# -F flag:
#
# Optional flag. Force flag. It creates the job-order even when timeline has
# already been processed.
#
#
# == Usage
# createJobOrderFile.rb  -f <triggerFile>  --id <job-id> [-L <path>]
#     --file <triggerFile>       trigger file
#     --id <id>                  id of the triggerFile on the data base
#     --Location <procWorkDir>   This is the Orchestrator Processors Working Dir
#     --Oper                     This is the Operational mode flag.   
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
# === Ruby source for #createJobOrderFile.rb module
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS -> ORC Component
# 
# CVS: $Id: createJobOrderFile.rb,v 1.8 2009/03/12 13:35:11 algs Exp $
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
   @jobId                  = 0
   @triggerName            = ""
   @isDebugMode            = false
   @bList                  = false
   @bShowVersion           = false
   @bForceCreation         = false
   @bOperational           = false
   @bProcAlready           = false
   
   opts = GetoptLong.new(
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
     ["--Location", "-L",        GetoptLong::REQUIRED_ARGUMENT],
     ["--id", "-i",              GetoptLong::REQUIRED_ARGUMENT],
     ["--Oper", "-O",            GetoptLong::NO_ARGUMENT],
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
            when "--list"        then @bList        = true
            when "--version"     then @bShowVersion = true
	         when "--file"        then @full_path_filename = arg.to_s
            when "--Location"    then @full_path_dir      = arg.to_s
	         when "--id"          then @jobId              = arg.to_s.to_i
	         when "--trigger"     then @triggerName        = arg.to_s
            when "--Force"       then @bForceCreation     = true
            when "--Oper"        then @bOperational       = true
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

   @strTriggerFile = File.basename(@full_path_filename)


   if @jobId != 0 then
      #check if it was already triggered (-F option)
      unionSqlSentence = "SELECT trigger_product_id FROM successful_trigger_products UNION SELECT trigger_product_id FROM failing_trigger_products"
      sqlSentence = "SELECT * FROM trigger_products t, (#{unionSqlSentence}) u WHERE t.id = u.trigger_product_id AND t.filename = '#{@strTriggerFile}' AND t.id = #{@jobId};"
      if @isDebugMode == true then
         puts sqlSentence
      end
      arrTrigger = TriggerProduct.find_by_sql(sqlSentence)
      @trigger = arrTrigger.pop
 
      #the file is already processed
      if @trigger !=nil then

         if @isDebugMode == true then
            puts "Trigger match"
            puts @trigger.filename
            puts @trigger.sensing_start
            puts @trigger.sensing_stop
            puts @trigger.id
         end
      
         #if the file was already processed and -F not raised, then exit
         if @bForceCreation == false then
         #   puts "soy repe, voy a tener q salir"
            exit(0) 
         end     
         @bProcAlready = true

      else # the trigger is not in success or failure tables
         #check if there is a match with filename and id
         @trigger = TriggerProduct.find_by_filename_and_id(@strTriggerFile, @jobId)
         if @trigger == nil then         
            puts "trigger dosnt exist or filename and id dosnt match :: createJobOrder"
            exit(99)
         end      
      end  #end of a repeated trigger
      depSolver = ORC::DependenciesSolver.new(@strTriggerFile, @jobId, @bOperational)
   else
      depSolver = ORC::DependenciesSolver.new(@strTriggerFile, "0", @bOperational)
   end
   
   #--------------------------------     
   
   if @isDebugMode == true then
      depSolver.setDebugMode
   end

   ret = depSolver.init

   if ret == false then
      puts "Trigger requested sensing shall not be processed ! :-|"
      puts
      if @bForceCreation == false then
         exit(99)
      end
   end
 
   ret = depSolver.resolve

   if ret == false then
      puts
      puts "Trigger requested cannot be processed yet ! :-("
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


   #if there was a given path with the -L flag, create job order
   if @full_path_dir != "" and @jobId != 0 then

      #if its was processed already then get his sensing times, else calculate them
      if @bProcAlready == true then
         strStart = @trigger.sensing_start.strftime("%Y%m%dT%H%M%S")
         strStop  = @trigger.sensing_stop.strftime("%Y%m%dT%H%M%S")       
      else       
         strStart = depSolver.getStartWindow
         strStop  = depSolver.getStopWindow
      end

      # Append to the processor working directory the job-order-id
      @full_path_dir = "#{@full_path_dir}/#{@jobId}"   

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

      depSolver.commit(true)
   end # -L flag
end
#---------------------------------------



#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
