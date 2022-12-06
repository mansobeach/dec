#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #EOCFI_Environment class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component (EOCFI)
### 
### Git: EOCFI_Environment,v $Id$ $Date$
###
### module EOCFI
###
#########################################################################

require 'rubygems'
require 'fileutils'

require 'cuc/DirUtils'


module EOCFI
   
   include CUC::DirUtils
   
   @@version = "0.0.1s"
   
   ## -----------------------------------------------------------------
   
   @@change_record = { \
      "0.0.1"  =>    "list of functions:\n\
         xd_read_station\n\
         xd_read_station_id\n\
         xd_read_station_file\n\
         xo_check_library_version\n\
         xo_position_on_orbit_to_time\n\
         xo_time_to_orbit\n\
         xv_stationvistime_compute",
      "0.0.0"  =>    "first version of the mptools installer created" \
   }
   ## -----------------------------------------------------------------
      
   ## -----------------------------------------------------------------

   ## extract MPL configuration from installation directory 
   def copy_installed_config(destination, nodename = "")
      
      checkDirectory(destination)
      ## -----------------------------
      ## EOCFI Config files
   
      arrConfigFiles = [\
         "eocfi_log_config.xml" #,\
      ]
      ## -----------------------------

      path = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      
      arrConfigFiles.each{|config|
      
         if File.exist?("#{destination}/#{config}") == true then
            puts "File #{destination}/#{config} exists already / please backup first #{'1F47A'.hex.chr('UTF-8')}"
            next
         end
      
         if File.exist?("#{path}/#{config}") == true then
            FileUtils.cp("#{path}/#{config}", "#{destination}/#{nodename}##{config}")
            FileUtils.ln_s("#{destination}/#{nodename}##{config}","#{destination}/#{config}")
         end
      }
      
   end
   
   ## -----------------------------------------------------------------

   def load_config
   
      # --------------------------------
      if !ENV['MPL_CONFIG'] then
         ENV['MPL_CONFIG'] = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      end
      # --------------------------------

      unset_config

      # --------------------------------
      if !ENV['HOSTNAME'] then
         ENV['HOSTNAME'] = `hostname`
      end
      # --------------------------------
      
   end
   ## -----------------------------------------------------------------

   def unset_config
   end

   ## -----------------------------------------------------------------
   
   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
      puts "MPL_CONFIG                    => #{ENV['MPL_CONFIG']}"
      puts "HOSTNAME                      => #{ENV['HOSTNAME']}"
   end
   ## -----------------------------------------------------------------
      
   ## -----------------------------------------------------------------

   def check_environment
      retVal = checkEnvironmentEssential
      if retVal == true then
         return checkToolDependencies
      else
         return false
      end
   end
   ## -----------------------------------------------------------------

   def checkEnvironmentEssential
   
      load_config
   
      bCheck = true
      
      # --------------------------------
      # MPL_CONFIG can be defined by the customer to override 
      # the configuration shipped with the gem
      if !ENV['MPL_CONFIG'] then
         ENV['MPL_CONFIG'] = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      end
      # --------------------------------
            
      if bCheck == false then
         puts "EOCFI Essential environment variables configuration not complete"
         puts
         return false
      end
      return true
   end
   ## -----------------------------------------------------------------

 
   ## -----------------------------------------------------------------

   def printEnvironmentError
      puts "Execution environment not suited for eocfi"
   end
   ## -----------------------------------------------------------------
      
   
   ## -----------------------------------------------------------------   
   ##
   ## check command line tool dependencies
   ##
   def checkToolDependencies(logger = nil)

      bDefined = true
      bCheckOK = true
      
      arrTools = [ \
                  "xmllint"#, \
                  ]
      
      arrTools.each{|tool|
         isToolPresent = `which #{tool}`
               
         if isToolPresent[0,1] != '/' then
            if logger != nil then
               logger.error("[MPL_799] Fatal Error:  #{tool} not present in $PATH")
            else
               puts "Fatal Error: #{tool} not present in PATH   :-(\n\n\n"
            end
            bCheckOK = false
         end

      }
                         
#      if bCheckOK == false then
#         puts "\nMPL_Environment::checkToolDependencies FAILED !\n\n"
#      end      
   
      return bCheckOK
   end
   ## -----------------------------------------------------------------
   
   ## -----------------------------------------------------------------
   
end # module

## ==============================================================================

## Wrapper to make use within unit tests since it is not possible inherit mixins

class EOCFI_Environment
   
   include EOCFI
   
   def wrapper_load_config
      load_config
   end
      
   def wrapper_checkEnvironmentEssential
      return checkEnvironmentEssential
   end

   def wrapper_check_environment
      return check_environment
   end

   def wrapper_unset_config
      unset_config
   end

   def wrapper_print_environment
      print_environment
   end
   
end

## ==============================================================================
