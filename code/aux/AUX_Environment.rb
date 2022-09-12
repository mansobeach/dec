#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for AUX_Environment class
#
# === Written by DEIMOS Space S.L.
#
# === Data Exchange Component (DEC)
# 
# Git: AUX_Environment,v $Id$ $Date$
#
# module AUX
#
#########################################################################

require 'rubygems'
require 'fileutils'

require 'cuc/DirUtils'

module AUX
   
   include CUC::DirUtils
   
   @@version = "0.0.5j"
   
   ## -----------------------------------------------------------------
   
   @@change_record = { \
      "0.0.5"  =>    "Celestrak CssiSpaceWeather Daily Prediction has been integrated\n\
         Celestrak TCA (TLE catalogue)  has been integrated\n\
         Celestrak TLE (TLE prediction) has been integrated\n\
         NASA MSFC Solar Flux (F10.7) / Geomagnetic disturbance (Ap) has been integrated\n\
         NASA CDDIS Bulletin A / Earth Orientation Parameters has been integrated\n\
         NASA CDDIS Bulletin C / TAI-UTC has been integrated",
      "0.0.4"  =>    "NOAA Report Solar Geophysical Activity has been integrated", \
      "0.0.3"  =>    "IERS Bulletin A / Earth Orientation Parameters has been integrated", \
      "0.0.2"  =>    "IGS Broadcast Ephemeris Daily has been integrated", \
      "0.0.1"  =>    "IERS Bulletin C / TAI-UTC has been integrated", \
      "0.0.0"  =>    "first version of the aux installer created" \
   }
   ## -----------------------------------------------------------------
   
   ## -----------------------------------------------------------------
   
   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
      puts "HOSTNAME                      => #{ENV['HOSTNAME']}"
   end
   ## -----------------------------------------------------------------

   ## -----------------------------------------------------------------

   def printEnvironmentError
      puts "Execution environment not suited for AUX"
   end
   ## -----------------------------------------------------------------
   
end # module

## ==============================================================================

## Wrapper to make use within unit tests since it is not possible inherit mixins

class AUX_Environment
   
   include AUX
   
   def wrapper_load_config_development
      load_config_development
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
