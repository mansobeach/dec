#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileArchiver class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: MINARC_Environment.rb,v 1.12 2008/09/24 16:09:19 decdev Exp $
#
# module MINARC
#
#########################################################################

module ARC
   
   @@version = "1.0.1"
   
   # -----------------------------------------------------------------
   
   @@change_record = { \
      "1.0.1"  =>    "Handler for m2ts files of Sony Camcorders", \
      "1.0.0"  =>    "First version of the minarc installer created" \
   }
   # -----------------------------------------------------------------
   
   def load_config_development
      ENV['MINARC_VERSION']               = "01.00.00"
      ENV['MINARC_DB_ADAPTER']            = "sqlite3"
      ENV['MINARC_BASE']                  = "#{ENV['HOME']}/Projects/dec"
      ENV['MINARC_SERVER']                = "http://localhost:4567"
      ENV['MINARC_ARCHIVE_ROOT']          = "#{ENV['HOME']}/Sandbox/minarc/archive_root"
      ENV['MINARC_ARCHIVE_ERROR']         = "#{ENV['HOME']}/Sandbox/minarc/error"
      ENV['MINARC_TMP']                   = "#{ENV['HOME']}/Sandbox/minarc/tmp"
      ENV['MINARC_DATABASE_NAME']         = "#{ENV['HOME']}/Sandbox/inventory/minarc_inventory"
      ENV['MINARC_DATABASE_USER']         = "root"
      ENV['MINARC_DATABASE_PASSWORD']     = "1mysql"
   end
   
   # -----------------------------------------------------------------
   
   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
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
