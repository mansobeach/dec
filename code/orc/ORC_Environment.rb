#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileArchiver class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# Git: $Id: ORC_Environment.rb $Date$
#
# module ORC
#
#########################################################################

require 'cuc/DirUtils'

module ORC
   
   include CUC::DirUtils
   
   @@version = "0.0.1dev"
   
   # -----------------------------------------------------------------
   
   @@change_record = { \
      "0.0.1"  =>    "First version of the orchestrator" \
   }
   # -----------------------------------------------------------------
   
   def load_config_development
      ENV['ORC_DB_ADAPTER']               = "sqlite3"
      ENV['TMPDIR']                       = "#{ENV['HOME']}/Sandbox/minarc/tmp"
      ENV['ORC_DATABASE_NAME']            = "#{ENV['HOME']}/Sandbox/inventory/minarc_inventory"
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
   end
   # -----------------------------------------------------------------
   
   def load_config_production
   end 
   # -----------------------------------------------------------------
   
   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
      puts "TMPDIR                        => #{ENV['TMPDIR']}"
      puts "ORC_DB_ADAPTER                => #{ENV['ORC_DB_ADAPTER']}"
      puts "ORC_DATABASE_NAME             => #{ENV['ORC_DATABASE_NAME']}"
      puts "ORC_DATABASE_USER             => #{ENV['ORC_DATABASE_USER']}"
      puts "ORC_DATABASE_PASSWORD         => #{ENV['ORC_DATABASE_PASSWORD']}"
      puts "ORC_CONFIG                    => #{ENV['ORC_CONFIG']}"
   end
   # -----------------------------------------------------------------

   def check_environment_dirs
      checkDirectory(ENV['TMPDIR'])
   end
   
   # -----------------------------------------------------------------

   def createEnvironmentDirs
      checkDirectory(ENV['TMPDIR'])
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
     
      if bCheck == false then
         puts "ORC environment variables configuration not complete"
         puts
         return false
      end
      return true
   end
   # -----------------------------------------------------------------
   

   # -----------------------------------------------------------------
   
   def checkToolsRemoteMode
      isToolPresent = `which curl`
   
      if isToolPresent[0,1] != '/' or $? != 0 then
         puts "\nMINARC_Environment::checkToolsRemoteMode\n"
         puts "Fatal Error: curl not present in PATH   :-(\n"
         return false
      end
      return true
   end
   
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
end

# ==============================================================================
