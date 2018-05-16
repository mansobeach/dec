#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DEC_ConfigDevelopment class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component (DEC)
# 
# CVS: $Id: DEC_ConfigDevelopment,v 1.12 2008/09/24 16:09:19 decdev Exp $
#
# module DEC
#
#########################################################################

# 1.0.0     is the first installer created
# 1.0.1     decStats -H <hours> has been integrated

require 'rubygems'

module DEC
   
   @@version = "1.0.1"
   
   # -----------------------------------------------------------------
   
   def load_config_development      
      ENV['DEC_VERSION']                  = DEC.class_variable_get(:@@version)
      ENV['DEC_DB_ADAPTER']               = "sqlite3"
      ENV['DEC_DATABASE_NAME']            = "#{ENV['HOME']}/Sandbox/dec/dec_inventory"
      ENV['DEC_DATABASE_USER']            = "root"
      ENV['DEC_DATABASE_PASSWORD']        = "1mysql"
      ENV['DEC_TMP']                      = "#{ENV['HOME']}/Sandbox/dec/tmp"
      ENV['DEC_DELIVERY_ROOT']            = "#{ENV['HOME']}/Sandbox/dec/delivery_root"
      # ENV['DEC_CONFIG']                   = "#{ENV['HOME']}/Projects/dec/config"
      ENV['DEC_CONFIG']                   = File.join( File.dirname(File.expand_path(__FILE__)), "../../config" )
   end
   
   # -----------------------------------------------------------------
   
   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
      puts "DEC_DB_ADAPTER                => #{ENV['DEC_DB_ADAPTER']}"
      puts "DEC_TMP                       => #{ENV['DEC_TMP']}"
      puts "DEC_DATABASE_NAME             => #{ENV['DEC_DATABASE_NAME']}"
      puts "DEC_DATABASE_USER             => #{ENV['DEC_DATABASE_USER']}"
      puts "DEC_DATABASE_PASSWORD         => #{ENV['DEC_DATABASE_PASSWORD']}"
      puts "DEC_CONFIG                    => #{ENV['DEC_CONFIG']}"
   end
   # -----------------------------------------------------------------

   def checkEnvironmentEssential
      bCheck = true
      if !ENV['DEC_CONFIG'] then
         bCheck = false
         puts
         puts "DEC_CONFIG environment variable is not defined !\n"
         puts
      end

      if !ENV['DEC_TMP'] then
         bCheck = false
         puts
         puts "DEC_TMP environment variable is not defined !\n"
         puts
      end
      
      if bCheck == false then
         puts "DEC environment variables configuration not complete"
         puts
         return false
      end
      return true
   end
   # -----------------------------------------------------------------

   # -----------------------------------------------------------------

   def checkEnvironmentDB
      bCheck = true
      if !ENV['DEC_DB_ADAPTER'] then
         bCheck = false
         puts
         puts "DEC_DB_ADAPTER environment variable is not defined !\n"
         puts
      end

      if !ENV['DEC_DATABASE_NAME'] then
         bCheck = false
         puts
         puts "DEC_DATABASE_NAME environment variable is not defined !\n"
         puts
      end

      if bCheck == false then
         puts "DEC environment variables configuration not complete"
         puts
         return false
      end
      return true
   end
   # -----------------------------------------------------------------

   
end # module

# ==============================================================================

# Wrapper to make use within unit tests since it is not possible inherit mixins

class DEC_Environment
   
   include DEC
   
   def wrapper_load_config_development
      load_config_development
   end

   def wrapper_print_environment
      print_environment
   end
   
end

# ==============================================================================
