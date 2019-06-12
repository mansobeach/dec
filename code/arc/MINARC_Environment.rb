#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileArchiver class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# Git: $Id: MINARC_Environment.rb $Date$
#
# module MINARC
#
#########################################################################

require 'cuc/DirUtils'

module ARC
   
   include CUC::DirUtils
   
   @@version = "1.0.31dev"
   
   # -----------------------------------------------------------------
   
   @@change_record = { \
      "1.0.31" =>    "Check of tool dependencies done in the unit tests", \
      "1.0.30" =>    "Integration version with DEC / generic Orchestrator", \
      "1.0.29" =>    "minArcFile new tool to decode filename is included supported by Handler_S2PDGS\n", \
      "1.0.28" =>    "Handler_VIDEO updated to handle mkv (matrioska) files\n", \
      "1.0.27" =>    "Handler_VIDEO replaces M2TS & updated to handle wmv files\n", \
      "1.0.26" =>    "minArcStore --delete fix in remote mode\n          Fix to minArcRetrieve list with wildcards in remote mode", \
      "1.0.25" =>    "Server invokes minArcStore with --move flag to avoid copy", \
      "1.0.24" =>    "curl time-outs tailored to send big files in remote mode", \
      "1.0.23" =>    "Database model updated to replace Integer types by BigInt", \
      "1.0.22" =>    "Connection pool limit with ActiveRecord/thin fixed\n          new API function API_URL_STAT_FILENAME implemented", \
      "1.0.21" =>    "Handler_M2TS updated to handle mp4 files too\n          minArcStore supports deletion of local file upon remote archive", \
      "1.0.20" =>    "inventory updated to keep filename without extension\n          time-out updated when posting files", \
      "1.0.19" =>    "minArcDB creates an index by filename", \
      "1.0.18" =>    "minArcStore remote -L (location directory) used by m2ts/mp4", \
      "1.0.17" =>    "minArcRetrieve remote mode supports -t <filetype> retrieval", \
      "1.0.16" =>    "minArcRetrieve local mode supports to filter --New files by archive date", \
      "1.0.15" =>    "Server mode restarts the connection to avoid pool limit :-( | ConnectionPool pending", \
      "1.0.14" =>    "minArcStatus supports server mode for global and filetype", \
      "1.0.13" =>    "minArcStore supports bulk mode with wildcards in local mode", \
      "1.0.12" =>    "minArcStore supports -d (delete source file) with plug-in S2PDGS", \
      "1.0.11" =>    "minArcRetrieve support for wildcards and multiple files retrieval from server", \
      "1.0.10" =>    "Listing files from server fixed when more than one is found", \
      "1.0.9"  =>    "Handler_S2PDGS updated to support S2 REP_ARC__A index of auxiliary files", \
      "1.0.8"  =>    "minArcSmokeTestRemote working successfully with MINARC_SERVER variable only", \
      "1.0.7"  =>    "Client mode to retrieve files using obsolete curl older than 7.21.2", \
      "1.0.6"  =>    "minArcServer activation at execution time of selected environment", \
      "1.0.5"  =>    "minArcRetrieve -T now supports remote mode using server", \
      "1.0.4"  =>    "minArcStatus bundled with -V to retrieve version from server", \
      "1.0.3"  =>    "minArcRetrieve remote requests to replace * wildcards with http compliant %2A character", \
      "1.0.2"  =>    "minArcServer management of production and development environments", \
      "1.0.1"  =>    "Handler for m2ts files of Sony Camcorders", \
      "1.0.0"  =>    "First version of the minarc installer created" \
   }
   # -----------------------------------------------------------------
   
   @@arrENV = [ \
                  "MINARC_TMP", \
                  "MINARC_ARCHIVE_ROOT", \
                  "MINARC_DB_ADAPTER", \
                  "MINARC_ARCHIVE_ERROR", \
                  "MINARC_DATABASE_NAME", \
                  "MINARC_DATABASE_USER", \
                  "MINARC_DATABASE_PASSWORD" \
                  ]

   # -----------------------------------------------------------------

   @@arrTools = [ \
                  "curl", \
                  "7z", \
                  "gzip", \
                  "tar", \
                  "zip", \
                  "unzip" \
                  ]

   # -----------------------------------------------------------------
   
   def load_config_development
      ENV['MINARC_DB_ADAPTER']            = "sqlite3"
      ENV['MINARC_SERVER']                = "http://localhost:4567"
      ENV['MINARC_ARCHIVE_ROOT']          = "#{ENV['HOME']}/Sandbox/minarc/archive_root"
      ENV['MINARC_ARCHIVE_ERROR']         = "#{ENV['HOME']}/Sandbox/minarc/error"
      ENV['MINARC_TMP']                   = "#{ENV['HOME']}/Sandbox/minarc/tmp"
      ENV['TMPDIR']                       = "#{ENV['HOME']}/Sandbox/minarc/tmp"
      ENV['MINARC_DATABASE_NAME']         = "#{ENV['HOME']}/Sandbox/inventory/minarc_inventory"
      ENV['MINARC_DATABASE_USER']         = "root"
      ENV['MINARC_DATABASE_PASSWORD']     = "1mysql"
      ENV['RACK_ENV']                     = "development"
   end
   
   # -----------------------------------------------------------------
   
   def unset_config
      ENV.delete('MINARC_DB_ADAPTER')
      ENV.delete('MINARC_SERVER')
      ENV.delete('MINARC_ARCHIVE_ROOT')
      ENV.delete('MINARC_ARCHIVE_ERROR')
      ENV.delete('MINARC_DATABASE_NAME')
      ENV.delete('MINARC_DATABASE_USER')
      ENV.delete('MINARC_DATABASE_PASSWORD')
      ENV.delete('MINARC_TMP')
   end
   # -----------------------------------------------------------------
   
   def load_config_production
      ENV['RACK_ENV']                     = "production"
   end 
   # -----------------------------------------------------------------
   
   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
      puts "RACK_ENV                      => #{ENV['RACK_ENV']}"
      puts "TMPDIR                        => #{ENV['TMPDIR']}"
      puts "MINARC_DB_ADAPTER             => #{ENV['MINARC_DB_ADAPTER']}"
      puts "MINARC_SERVER                 => #{ENV['MINARC_SERVER']}"
      puts "MINARC_TMP                    => #{ENV['MINARC_TMP']}"
      puts "MINARC_DATABASE_NAME          => #{ENV['MINARC_DATABASE_NAME']}"
      puts "MINARC_DATABASE_USER          => #{ENV['MINARC_DATABASE_USER']}"
      puts "MINARC_DATABASE_PASSWORD      => #{ENV['MINARC_DATABASE_PASSWORD']}"
      puts "MINARC_ARCHIVE_ROOT           => #{ENV['MINARC_ARCHIVE_ROOT']}"
      puts "MINARC_ARCHIVE_ERROR          => #{ENV['MINARC_ARCHIVE_ERROR']}"
   end
   # -----------------------------------------------------------------

   def check_environment_dirs
      checkDirectory(ENV['TMPDIR'])
      checkDirectory(ENV['MINARC_TMP'])
      checkDirectory(ENV['MINARC_ARCHIVE_ROOT'])
      checkDirectory(ENV['MINARC_ARCHIVE_ERROR'])
      checkDirectory("#{ENV['HOME']}/Sandbox/inventory/")
   end
   # -----------------------------------------------------------------

   def setRemoteModeOnly
      ENV.delete('MINARC_TMP')
      ENV.delete('MINARC_DB_ADAPTER')
      ENV.delete('MINARC_ARCHIVE_ROOT')
      ENV.delete('MINARC_ARCHIVE_ERROR')
      ENV.delete('MINARC_DATABASE_NAME')
      ENV.delete('MINARC_DATABASE_USER')
      ENV.delete('MINARC_DATABASE_PASSWORD')
   end
   # -----------------------------------------------------------------
   
   def setLocalModeOnly
      ENV.delete('MINARC_SERVER')
   end
   # -----------------------------------------------------------------
   
   def load_environment_test
      env_file = File.join(File.dirname(File.expand_path(__FILE__)), '../../install', 'minarc_test.env')
      Dotenv.overload(env_file)
   end
   
   # -----------------------------------------------------------------
   
   def check_environment
      check_environment_dirs
      retVal = checkEnvironmentEssential
      if retVal == true then
         return checkToolDependencies
      else
         return false
      end
   end
   # -----------------------------------------------------------------
   
   def checkEnvironmentEssential
      bCheck = true
      
      @@arrENV.each{|vble|
         if !ENV.include?(vble) then
            bCheck = false
            puts "MINARC environment variable #{vble} is not defined !\n"
            puts
         end
      }
      
      if bCheck == false then
         puts "MINARC environment / configuration not complete"
         puts
         return false
      end
      return true
      
      
   end
   # -----------------------------------------------------------------
   
   def checkToolDependencies
      
      bCheck = true
      bCheckOK = true
      
      @@arrTools.each{|tool|
         isToolPresent = `which #{tool}`
               
         if isToolPresent[0,1] != '/' then
            puts "\n\nMINARC_Environment::checkToolDependencies\n"
            puts "Fatal Error: #{tool} not present in PATH !!   :-(\n\n\n"
            bCheckOK = false
         end

      }

      if bCheckOK == false then
         puts "minArc environment configuration is not complete"
         puts
         return false
      end

      return true
      
   end
   
   # -----------------------------------------------------------------

   
end # module

# ==============================================================================

# Wrapper to make use within unit tests since it is not possible inherit mixins

class MINARC_Environment
   
   include ARC

   def wrapper_load_environment_test
      load_environment_test
   end
   
   def wrapper_load_config_development
      load_config_development
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

# ==============================================================================
