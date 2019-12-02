#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #ORC_Environment class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Orchestrator (generic orchestrator)
# 
# Git: $Id: ORC_Environment.rb $Date$
#
# module ORC
#
#########################################################################

require 'dotenv'

require 'cuc/DirUtils'

require 'orc/ReadOrchestratorConfig'

module ORC
   
   include CUC::DirUtils
   
   @@version = "0.0.9dev"
   
   ## ----------------------------------------------------------------
   
   @@change_record = { \
      "0.0.9"  =>    "unit tests execution environment can be parametrised with env file", \
      "0.0.8"  =>    "fixed S2MPASUP-292 / migration to ActiveRecord 6", \
      "0.0.7"  =>    "fixed S2MPASUP-277 regarding race conditions when triggering jobs", \
      "0.0.6"  =>    "ingestion parallelised (new configuration ParallelIngestions)", \
      "0.0.5"  =>    "orcQueueUpdate fixed to fit with the new data-model", \
      "0.0.4"  =>    "orcQueueInput bulk mode support of pending triggers\n\
         OrchestratorScheduler now uses such bulk mode", \
      "0.0.3"  =>    "Check of tool dependencies done in the unit tests\n\
         Dotenv gem has been added to the Gemfile", \
      "0.0.2"  =>    "Unused dependencies with DEC/ctc sources removed", \
      "0.0.1"  =>    "First cleaned-up version of the orchestrator" \
   }
   ## ----------------------------------------------------------------
   
   @@arrEnv = [ \
               "ORC_TMP", \
               "ORC_CONFIG", \
               "ORC_DB_ADAPTER", \
               "ORC_DATABASE_NAME", \
               "ORC_DATABASE_USER", \
               "ORC_DATABASE_PASSWORD" \
              ]
   
   ## ----------------------------------------------------------------
   
   @@arrTools = [ \
                 "sqlite3", \
                 "orcManageDB", \
                 "orcQueueInput", \
                 "orcIngester", \
                 "orcScheduler", \
                 "orcBolg" \
                ]
   
   ## ----------------------------------------------------------------
   
   def load_environment_test
      env_file = File.join(File.dirname(File.expand_path(__FILE__)), '../../install', 'orc_test.env')
      Dotenv.overload(env_file)
      ENV['ORC_CONFIG']                   = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
   end
   
   ## -----------------------------------------------------------------
   
   def load_config_development
      ENV['ORC_DB_ADAPTER']               = "sqlite3"
      ENV['ORC_TMP']                      = "/tmp"
      ENV['ORC_DATABASE_NAME']            = "#{ENV['HOME']}/Sandbox/inventory/orc_inventory"
      ENV['ORC_DATABASE_USER']            = "root"
      ENV['ORC_DATABASE_PASSWORD']        = "1mysql"
      ENV['ORC_CONFIG']                   = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
   end
   
   ## -----------------------------------------------------------------
   
   def unset_config
      @@arrEnv.each{|vble|
         ENV.delete(vble)
      }
   end
   ## -----------------------------------------------------------------
   
   def load_environment(filename)
      env_file = File.join(File.dirname(File.expand_path(__FILE__)), '../../config', filename)
      
      if File.exist?(env_file) == false then
         puts "environment file #{env_file} not found"
         return false
      end
      
      Dotenv.overload(env_file)
      ENV['ORC_CONFIG'] = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
   end 
   ## ----------------------------------------------------------------
   
   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
      puts "ORC_TMP                       => #{ENV['ORC_TMP']}"
      puts "ORC_DB_ADAPTER                => #{ENV['ORC_DB_ADAPTER']}"
      puts "ORC_DATABASE_NAME             => #{ENV['ORC_DATABASE_NAME']}"
      puts "ORC_DATABASE_USER             => #{ENV['ORC_DATABASE_USER']}"
      puts "ORC_DATABASE_PASSWORD         => #{ENV['ORC_DATABASE_PASSWORD']}"
      puts "ORC_CONFIG                    => #{ENV['ORC_CONFIG']}"
   end
   ## ----------------------------------------------------------------
  
   def check_environment
      check_environment_dirs
      retVal = checkEnvironmentEssential
      if retVal == true then
         return checkToolDependencies
      else
         return false
      end
   end
   ## ----------------------------------------------------------------

   def check_environment_dirs
      
      checkDirectory(ENV['ORC_TMP'])
      checkDirectory("#{ENV['HOME']}/Sandbox/inventory/")
      
      orcConf = ORC::ReadOrchestratorConfig.instance
      
      checkDirectory(orcConf.getPollingDir)
      checkDirectory(orcConf.getProcWorkingDir)
      checkDirectory(orcConf.getSuccessDir)
      checkDirectory(orcConf.getFailureDir)
      checkDirectory(orcConf.getBreakPointDir)
      checkDirectory(orcConf.getTmpDir)    
   end
   
   ## ----------------------------------------------------------------

   def createEnvironmentDirs
      checkDirectory(ENV['ORC_TMP'])
      checkDirectory("#{ENV['HOME']}/Sandbox/inventory/")
   end

   ## ----------------------------------------------------------------

   def checkEnvironmentEssential
      bCheck = true
      bCheck = true
            
      @@arrEnv.each{|vble|
         if !ENV.include?(vble) then
            bCheck = false
            puts "orchestrator environment variable #{vble} is not defined !\n"
            puts
         end
      }
      
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
         executable = orcConf.getExecutable(trigger).split(" ")[0]
         cmd = "which #{executable}"
         isToolPresent = `#{cmd}`
         if isToolPresent[0,1] != '/' then
            puts "#{executable} not in path / rule #{trigger}"
            bCheck = false
         end
      }
                  
      if bCheck == false then
         puts "ORC environment / configuration not complete"
         puts
         return false
      end
      return true
   end
   ## ----------------------------------------------------------------

   def printEnvironmentError
      puts "Execution environment not suited for ORC"
   end
   ## ----------------------------------------------------------------

   ## ----------------------------------------------------------------
   
   def checkToolDependencies
      
      bCheck = true
      bCheckOK = true
      
      @@arrTools.each{|tool|
         isToolPresent = `which #{tool}`
               
         if isToolPresent[0,1] != '/' then
            puts "\n\nORC_Environment::checkToolDependencies\n"
            puts "Fatal Error: #{tool} not present in PATH !!   :-(\n\n\n"
            bCheckOK = false
         end

      }

      if bCheckOK == false then
         puts "orchestrator environment configuration is not complete"
         puts
         return false
      end
      return true      
   end
   
   ## ----------------------------------------------------------------
      
   
end # module

## =============================================================================

## Wrapper to make use within unit tests since it is not possible inherit mixins

class ORC_Environment
   
   include ORC

   def wrapper_load_environment_test
      load_environment_test
   end
   
   def wrapper_load_environment(envFile)
      return load_environment(envFile)
   end

   def wrapper_print_environment
      print_environment
   end

   def wrapper_check_environment
      return check_environment
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

## =============================================================================
