#!/usr/bin/env ruby

# == Synopsis
#
# This is a ORC command line tool that checks the coherency of the ORC configuration.
# This tool ensures that all configuration critical elements are correct.
#
#
# == Usage
#
# checkConfigOrchestrator.rb 
#
#     --all               checks everything
#     --dataProvider      checks only the dataProviders
#     --priorityRules     checks only the priority rules
#     --ProcessingRules   checks only the processing rules
#     --miscelanea        checks only the miscelanea            
#     --Debug             shows Debug info during the execution
#     --help              shows this help
#     --version           shows version number      
#
#
# == Author
# DEIMOS-Space S.L. (algk)
#
#
# == Copyright
# Copyright (c) 2005 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# Orchestrator Component
#
# CVS: $Id: checkConfigOrchestrator.rb,v 1.2 2009/03/17 08:28:52 algs Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'
require 'orc/CheckerOrchestratorConfig'



def main

   @command             = ""
   @isDebugMode         = false
   checkModuleIntegrity
   @orcConfigDir        = ENV['ORC_CONFIG']
   bFlag                = false
   checker = ORC::CheckerOrchestratorConfig.new

   puts   

   opts = GetoptLong.new(

      ["--all", "-a",             GetoptLong::NO_ARGUMENT],
      ["--dataProvider", "-d",    GetoptLong::NO_ARGUMENT],
      ["--priorityRules", "-p",   GetoptLong::NO_ARGUMENT],
      ["--processingRules", "-P", GetoptLong::NO_ARGUMENT],
      ["--miscelanea", "-m",      GetoptLong::NO_ARGUMENT],
      ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
      ["--help", "-h",            GetoptLong::NO_ARGUMENT],
      ["--version", "-v",         GetoptLong::NO_ARGUMENT]
      )

   begin
      opts.each do |opt, arg|
         case opt
            when "--all"  then              
               checker.check
               exit(0)
            when "--dataProvider"  then
               checker.checkDataProvider
               bFlag = true
            when "--priorityRules"  then             
               checker.checkPriorityRules
               bFlag = true
            when "--processingRules"  then              
               checker.checkProcessingRules
               bFlag = true
            when "--miscelanea"  then
               checker.checkMiscelanea
               bFlag = true
            when "--Debug"    then
               @isDebugMode = true
            when "--help"     then
               RDoc::usage("usage")
            when "--usage"    then
               RDoc::usage("usage")
            when "--version"  then
               print("\nESA - DEIMOS-Space S.L.  ORC ", File.basename($0))
               print("    $Revision: 1.2 $\n  [", @@dateLastModification, "]\n\n\n")
               exit(0)
         end
      end
   rescue Exception => e
      exit(99)
   end

   if bFlag == false then
      RDoc::usage("usage")
   end

end
#-------------------------------------------------------------


# Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      if !ENV['ORC_CONFIG'] then
         puts "\nORC_CONFIG environment variable not defined !\n"
         bDefined = false
      end
      if bDefined == false then
         puts "\nError in schedulerComponent.rb::checkModuleIntegrity :-(\n\n"
         exit(99)
      end
   end
#-------------------------------------------------------------

#==========================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
