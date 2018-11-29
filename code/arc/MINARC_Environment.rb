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
   
   @@version = "1.0.19"
   
   # -----------------------------------------------------------------
   
   @@change_record = { \
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
   
   def load_config_development
      ENV['MINARC_VERSION']               = "DEPRECATED_ENVIRONMENT_VARIABLE_01.00.00"
      ENV['MINARC_DB_ADAPTER']            = "sqlite3"
      ENV['MINARC_BASE']                  = "#{ENV['HOME']}/Projects/dec"
      ENV['MINARC_SERVER']                = "http://localhost:4567"
      ENV['MINARC_ARCHIVE_ROOT']          = "#{ENV['HOME']}/Sandbox/minarc/archive_root"
      ENV['MINARC_ARCHIVE_ERROR']         = "#{ENV['HOME']}/Sandbox/minarc/error"
      ENV['MINARC_TMP']                   = "#{ENV['HOME']}/Sandbox/minarc/tmp"
      ENV['MINARC_DATABASE_NAME']         = "#{ENV['HOME']}/Sandbox/inventory/minarc_inventory"
      ENV['MINARC_DATABASE_USER']         = "root"
      ENV['MINARC_DATABASE_PASSWORD']     = "1mysql"
      ENV['RACK_ENV']                     = "development"
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
      puts "MINARC_BASE                   => #{ENV['MINARC_BASE']}"
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
   end
   # -----------------------------------------------------------------

   def setRemoteModeOnly
      ENV.delete('MINARC_ARCHIVE_ROOT')
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
   
end # module

# ==============================================================================

# Wrapper to make use within unit tests since it is not possible inherit mixins

class ARC_Manage_Config_Development
   
   include ARC
   
   def wrapper_load_config_development
      load_config_development
   end

   def wrapper_print_environment
      print_environment
   end
   
   def wrapper_setRemoteModeOnly
      setRemoteModeOnly
   end
   
   def wrapper_setLocalModeOnly
      setLocalModeOnly
   end
end

# ==============================================================================
