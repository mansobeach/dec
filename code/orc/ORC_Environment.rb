#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #ORC_Environment class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Orchestrator (MinArc)
# 
# Git: $Id: ORC_Environment.rb $Date$
#
# module ORC
#
#########################################################################

require 'cuc/DirUtils'

require 'orc/ReadOrchestratorConfig'

module ORC
   
   include CUC::DirUtils
   
   @@version = "0.0.2"
   
   # -----------------------------------------------------------------
   
   @@change_record = { \
      "0.0.2"  =>    "Unused dependencies with DEC/ctc sources removed", \
      "0.0.1"  =>    "First cleaned-up version of the orchestrator" \
   }
   # -----------------------------------------------------------------
   
   
   def load_config_development
      ENV['ORC_DB_ADAPTER']               = "sqlite3"
      ENV['ORC_TMP']                      = "/tmp"
      ENV['ORC_DATABASE_NAME']            = "#{ENV['HOME']}/Sandbox/inventory/orc_inventory"
      ENV['ORC_DATABASE_USER']            = "root"
      ENV['ORC_DATABASE_PASSWORD']        = "1mysql"
      ENV['ORC_CONFIG']                   = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
   end
   
   # -----------------------------------------------------------------
   
   def unset_config
      ENV.delete('ORC_DB_ADAPTER')
      ENV.delete('ORC_DATABASE_NAME')
      ENV.delete('ORC_DATABASE_USER')
      ENV.delete('ORC_DATABASE_PASSWORD')
      ENV.delete('ORC_CONFIG')
      ENV.delete('ORC_TMP')
   end
   # -----------------------------------------------------------------
   
   def load_config_production
   end 
   # -----------------------------------------------------------------
   
   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
      puts "ORC_TMP                       => #{ENV['ORC_TMP']}"
      puts "ORC_DB_ADAPTER                => #{ENV['ORC_DB_ADAPTER']}"
      puts "ORC_DATABASE_NAME             => #{ENV['ORC_DATABASE_NAME']}"
      puts "ORC_DATABASE_USER             => #{ENV['ORC_DATABASE_USER']}"
      puts "ORC_DATABASE_PASSWORD         => #{ENV['ORC_DATABASE_PASSWORD']}"
      puts "ORC_CONFIG                    => #{ENV['ORC_CONFIG']}"
   end
   # -----------------------------------------------------------------

   def check_environment_dirs
      checkDirectory(ENV['ORC_TMP'])
      checkDirectory("#{ENV['HOME']}/Sandbox/inventory/")
   end
   
   # -----------------------------------------------------------------

   def createEnvironmentDirs
      checkDirectory(ENV['ORC_TMP'])
      checkDirectory("#{ENV['HOME']}/Sandbox/inventory/")
   end

   # -----------------------------------------------------------------

   def checkEnvironmentEssential
      bCheck = true
      if !ENV['ORC_CONFIG'] then
         bCheck = false
         puts "ORC_CONFIG environment variable is not defined !\n"
         puts
      end

      if !ENV['ORC_TMP'] then
         bCheck = false
         puts "ORC_TMP environment variable is not defined !\n"
         puts
      end

      if !ENV['ORC_DB_ADAPTER'] then
         bCheck = false
         puts "ORC_DB_ADAPTER environment variable is not defined !\n"
         puts
      end

#      ret = `which`
#
#      if $?.exitstatus != 1 then
#         puts "ORC_Environment::checkEnvironmentEssential"
#         puts "which command line tool is not installed !"
#         puts "it is needed to verify the presence of command line dependencies in $PATH"
#         puts
#         exit(99)
#      end

      isToolPresent = `which sqlite3`
      
      if isToolPresent[0,1] != '/' then
         puts "sqlite3 tool not present in PATH !  :-(\n"
         bCheckOK = false
      end

      isToolPresent = `which orcManageDB`
      
      if isToolPresent[0,1] != '/' then
         puts "orcManageDB tool not present in PATH !  :-(\n"
         bCheckOK = false
      end

      isToolPresent = `which orcQueueInput`
      
      if isToolPresent[0,1] != '/' then
         puts "orcQueueInput tool not present in PATH !  :-(\n"
         bCheckOK = false
      end

      isToolPresent = `which orcIngester`
      
      if isToolPresent[0,1] != '/' then
         puts "orcIngester tool not present in PATH !  :-(\n"
         bCheckOK = false
      end

      isToolPresent = `which orcScheduler`
      
      if isToolPresent[0,1] != '/' then
         puts "orcScheduler tool not present in PATH !  :-(\n"
         bCheckOK = false
      end
 
      orcConf = ORC::ReadOrchestratorConfig.instance
      orcConf.update

      resMan = orcConf.getResourceManager

      cmd = "which #{resMan}"

      isToolPresent = `#{cmd}`

      if isToolPresent[0,1] != '/' then
         puts "#{resMan} not present in PATH !  :-(\n"
         puts "check orchestratorConfigFile.xml => ResourceManager configuration"
         bCheckOK = false
      end

      triggers = orcConf.getAllTriggerTypeInputs
      
      triggers.each{|trigger|
         executable = orcConf.getExecutable(trigger)
         cmd = "which #{executable}"
         isToolPresent = `#{cmd}`
         if isToolPresent[0,1] != '/' then
            puts "#{executable} not in path / rule #{trigger}"
            bCheckOK = false
         end
      }
            
      checkDirectory(orcConf.getProcWorkingDir)
      checkDirectory(orcConf.getSuccessDir)
      checkDirectory(orcConf.getFailureDir)
      checkDirectory(orcConf.getBreakPointDir)
      checkDirectory(orcConf.getTmpDir)
      
      if bCheck == false then
         puts "ORC environment / configuration not complete"
         puts
         return false
      end
      return true
   end
   # -----------------------------------------------------------------

   def printEnvironmentError
      puts "Execution environment not suited for ORC"
   end
   # -----------------------------------------------------------------
   

   # -----------------------------------------------------------------
   
   
end # module

# ==============================================================================

# Wrapper to make use within unit tests since it is not possible inherit mixins

class ORC_Environment
   
   include ORC
   
   def wrapper_load_config_development
      load_config_development
   end

   def wrapper_print_environment
      print_environment
   end

   def wrapper_unset_config
      unset_config
   end
   
   def wrapper_setRemoteModeOnly
      setRemoteModeOnly
   end
   
   def wrapper_setLocalModeOnly
      setLocalModeOnly
   end
   
   def wrapper_createEnvironmentDirs
      check_environment_dirs
   end
   
end

# ==============================================================================
