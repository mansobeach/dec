#!/usr/bin/env ruby

# == Synopsis
#
# This is an NRTP Orchestrator command line tool used to update the statuses of NRTP jobs.
# 
# -f flag:
#
# Mandatory flag. This option is used to specify the name of the file to be updated.  
#
#
# -s flag:
#
# Mandatory flag. This flag is used to specify the new status to give to the NRTP job.
# Expected values are :
# FAILURE
# SUCCESS
# OBSOLETE
#
#
# == Usage
# updateOrcProduct.rb -f <file-name> -s <new-status>
#
#     --file <file-name>         specifies the name of the file to be updated
#     --set-to                   specifies the new status of the NRTP job
#     --delete                   deletes all
#     --help                     shows this help
#     --usage                    shows the usage
#     --Debug                    shows Debug info during the execution
#     --version                  shows version number
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
# CVS: $Id: updateOrcProduct.rb,v 1.6 2008/07/29 14:52:20 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require "orc/ORC_DataModel"
require "cuc/EE_ReadFileName"

# Global variables
@@dateLastModification = "$Date: 2008/07/29 14:52:20 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   #Hardcoded values
   @arrStatus = ["SUC", "FAI", "OBS"]

   # Data provided by the user
   @filename               = ""
   @newStatus              = ""
   @isDebugMode            = false
   @bDeleteAll             = false
   @bDeleteObsolete        = false
   @bDeleteFailed          = false
   @bDeleteSuccess         = false
   @bDeleteQueued          = false

#    # Data generated or extracted from filename
#    # (for the generated product)
#    @sensing_start          = nil
#    @sensing_stop           = nil

   # Other required Data
   @generationDate         = nil
   @trigger_prod_id        = nil

   # Variables
   @triggerProd            = nil
   @queuedProd             = nil
   
   opts = GetoptLong.new(
     ["--file",       "-f",       GetoptLong::REQUIRED_ARGUMENT],
     ["--set-to",     "-s",       GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug",      "-D",       GetoptLong::NO_ARGUMENT],
     ["--delete",     "-d",       GetoptLong::NO_ARGUMENT],
     ["--usage",      "-u",       GetoptLong::NO_ARGUMENT],
     ["--version",    "-v",       GetoptLong::NO_ARGUMENT],
     ["--FAILED",     "-F",       GetoptLong::NO_ARGUMENT],
     ["--SUCCESS",    "-S",       GetoptLong::NO_ARGUMENT],
     ["--QUEUED",     "-Q",       GetoptLong::NO_ARGUMENT],
     ["--OBSOLETE",   "-O",       GetoptLong::NO_ARGUMENT],
     ["--help",       "-h",       GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"     then @isDebugMode = true
            when "--version" then	    
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.6 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
            when "--FAILED"        then @bDeleteFailed       = true
            when "--SUCCESS"       then @bDeleteSuccess      = true
            when "--QUEUED"        then @bDeleteQueued       = true
            when "--OBSOLETE"      then @bDeleteObsolete     = true
	         when "--delete"        then @bDeleteAll          = true
            when "--file"          then @filename            =  arg.to_s
            when "--set-to"        then @newStatus           = (arg.to_s).upcase[0..2]
			   when "--help"          then RDoc::usage
	         when "--usage"         then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end

   ######################## Coherency Checks & Data Extraction ########################
   if @bDeleteAll == true then
      deleteAll
      exit
   end   


   if @filename == "" or @filename.length > 100 then
      puts
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   #check that the file is registered as a trigger product
   @triggerProd = TriggerProduct.find_by_filename(@filename)
   if @triggerProd == nil then
      puts
      puts "The filename provided is not registered as a trigger product :-("
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   else
      @trigger_prod_id = @triggerProd.id
   end

   #check that the file is in the orchestrator queue
   @queuedProd = OrchestratorQueue.find_by_trigger_product_id(@trigger_prod_id)
   if @queuedProd == nil then
      puts
      puts "The trigger product is registered but not present in the orchestrator queue :-("
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   if @arrStatus.include?(@newStatus) == false then
      puts
      puts "Status \"#{@newStatus}\" is not a valid status :-("
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

#    if @newStatus == "SUC" then
# 
#       # check if it is EE.
#       nameDecoder = CUC::EE_ReadFileName.new(@genFileName)
# 
#       if nameDecoder.isEarthExplorerFile? then
#          @genFileType    = nameDecoder.fileType.upcase
#          @sensing_start  = nameDecoder.start_as_dateTime
#          @sensing_stop   = nameDecoder.stop_as_dateTime
#          @generationDate = Time.now
#       else
#          # Fail if the file-type was not provided
#          if @genFileType == nil or @genFileType == "" then
#             puts
#             puts "Please specify generated file-type as it is not an Earth-Explorer file :-("
#             puts
#             RDoc::usage("usage")
#             puts
#             exit(99)
#          end
# 
#          # look for handler plugins...
#          handler = ""
#          rubylibs = ENV['RUBYLIB'].split(':')
#          rubylibs.each {|path|
#             if File.exists?("#{path}/orc/plugins/#{@genFileType}_Handler.rb") then
#                handler = "#{@genFileType}_Handler"
#                break
#             end
#          }
# 
#          # Fail if we don't have the right plugin
#          if handler == "" then
#             puts
#             puts "Could not find handler-file for file-type #{@genFileType} :-("
#             puts
#             RDoc::usage("usage")
#             puts
#             exit(99)
#          else
#             # try to extract data
#             require "orc/plugins/#{handler}"
#             nameDecoderKlass = eval(handler)
#             nameDecoder = nameDecoderKlass.new(@genFileName)
#             
#             if nameDecoder != nil and nameDecoder.isValid then
#                @fileType       = nameDecoder.fileType.upcase
#                @sensing_start  = nameDecoder.start_as_dateTime
#                @sensing_stop   = nameDecoder.stop_as_dateTime
#                @generationDate = nameDecoder.generationDate
#             else
#                puts
#                puts "The file #{@genFileName} could not be identified as a valid #{@genFileType} file..."
#                puts "Unable to proceed :-("
#                puts
#                RDoc::usage("usage")
#                puts
#                exit(99)
#             end 
#          end
#       end
# 
#       # check extracted data here !
# 
#       if @isDebugMode then
#          puts
#          puts "The generated product is as follow :"
#          puts "File-name   : #{@genFileName}"
#          puts "File-type   : #{@genFileType}"
#          puts "Start date  : #{@sensing_start}"
#          puts "Stop date   : #{@sensing_stop}"
#          puts "Gene date   : #{@generationDate}"
#          puts "Trigger id  : #{@trigger_prod_id}"
#          puts
#       end
# 
#    end

   ######################## Request Processing ########################

   if @newStatus == "SUC" then
      set_product_to_success
      exit(0)
   end

   if @newStatus == "FAI" then
      set_product_to_failure
      exit(0)
   end   

   if @newStatus == "OBS" then
      set_product_to_obsolete
      exit(0)
   end

end

#-------------------------------------------------------------------------------
def set_product_to_success
   
   #check that the file is not allready present in the successful products list
   tmpProd = SuccessfulTriggerProduct.find_by_trigger_product_id(@trigger_prod_id)
   if tmpProd != nil then
      puts
      puts "The trigger product is registered in both 'orchestrator queue' and 'successful trigger products' :-("
      puts "Incoherent orchestrator status !"
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

#    # ==> add new generated product
#    genProd = GeneratedProduct.new(:filename => @genFileName,
#                          :filetype => @genFileType, 
#                          :generation_date => @generationDate,
#                          :sensing_start => @sensing_start,
#                          :sensing_stop => @sensing_stop,
#                          :trigger_product_id => @trigger_prod_id)
# 
#    begin
#       genProd.save!
#    rescue
#       puts
#       puts "Unable to register #{@genFileName} as a generated product :-("
#       puts "This file might be allready registered..."
#       puts
#       exit(99)
#    end

   OrchestratorQueue.transaction do
      # ==> add trigger product to success
      tmpProd = SuccessfulTriggerProduct.new
      tmpProd.trigger_products = @triggerProd
      tmpProd.success_date = Time.now

      begin
         tmpProd.save!
      rescue
         puts
         puts "Unable to register #{@filename} as a successful trigger product :-("
         puts "Unknown error !"
         puts
         exit(99)
      end

      # ==> remove trigger product from queue
      OrchestratorQueue.delete_all(:trigger_product_id => @trigger_prod_id)
   end

end

#-------------------------------------------------------------------------------
def set_product_to_failure

   #check that the file is not allready present in the failing products list
   tmpProd = FailingTriggerProduct.find_by_trigger_product_id(@trigger_prod_id)
   if tmpProd != nil then
      puts
      puts "The trigger product is registered in both 'orchestrator queue' and 'failing trigger products' :-("
      puts "Incoherent orchestrator status !"
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   OrchestratorQueue.transaction do

      tmpProd = FailingTriggerProduct.new
      tmpProd.trigger_products = @triggerProd
      tmpProd.failure_date = Time.now
      
      begin
        tmpProd.save!
      rescue Exception => e
         puts e.to_s
         puts
         puts "Unable to register #{@filename} as a failing trigger product :-("
         puts
         puts
         exit(99)
      end

      OrchestratorQueue.delete_all(:trigger_product_id => @trigger_prod_id)

   end

   if @isDebugMode then
      puts
      puts "updateOrcProduct => update status to 'failing trigger product'..."
      puts "Product name : #{@filename}"
      puts "Product id   : #{@trigger_prod_id}"
      puts "update completed :-)"
      puts
   end
 
end

#-------------------------------------------------------------------------------

def set_product_to_obsolete

   #check that the file is not allready present in the obsolete products list
   tmpProd = ObsoleteTriggerProduct.find_by_trigger_product_id(@trigger_prod_id)
   if tmpProd != nil then
      puts
      puts "The trigger product is registered in both 'orchestrator queue' and 'obsolete trigger products' :-("
      puts "Incoherent orchestrator status !"
      puts
      RDoc::usage("usage")
      puts
      exit(99)
   end

   OrchestratorQueue.transaction do

      obsTime = Time.now
      tmpProd = ObsoleteTriggerProduct.new
      tmpProd.trigger_products = @triggerProd
      tmpProd.obsolete_date      = obsTime

      begin
         tmpProd.save!
      rescue
         puts
         puts "Unable to register #{@filename} as an obsolete trigger product :-("
         puts "Unknown error !"
         puts
         exit(99)
      end

      OrchestratorQueue.delete_all(:trigger_product_id => @trigger_prod_id)

   end

   if @isDebugMode then
      puts
      puts "updateOrcProduct => update status to 'obsolete trigger product'..."
      puts "Product name   : #{@filename}"
      puts "Product id     : #{@trigger_prod_id}"
      puts "Obsolete since : #{obsTime}"
      puts "update completed :-)"
      puts
   end
 
end

#-------------------------------------------------------------------------------

def deleteAll
   if @bDeleteQueued == true then
      OrchestratorQueue.delete_all
      puts "orchestrator queued files deleted"
   end

   if @bDeleteObsolete == true then
      ObsoleteTriggerProduct.delete_all
      puts "orchestrator obsolete files deleted"
   end

   if @bDeleteSuccess == true then
      SuccessfulTriggerProduct.delete_all
      puts "orchestrator success trigger files deleted"
   end
   
   if @bDeleteFailed == true then
      FailingTriggerProduct.delete_all
      puts "orchestrator failed trigger files deleted"
   end
   
   if @bDeleteQueued == true and @bDeleteFailed == true and @bDeleteSuccess == true and @bDeleteObsolete == true then
      TriggerProduct.delete_all
   end
end
#-------------------------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
