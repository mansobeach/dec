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


module AUX
   
   VERSION   = "0.0.8.4"
   
   ## -----------------------------------------------------------------
   
   CHANGE_RECORD = { \
      "0.0.8"  =>    "NASA ASTER Global DEM: ASTGTM\n\
         NASA SRTMGL1 is supported\n\
         USGS SRTMGL1 (geotiff) is supported / requires GDAL\n\
         NASA MODIS products: MOD09A1",
      "0.0.7"  =>    "IERS Bulletin C conversion for NAOS mission", \
      "0.0.6"  =>    "IERS Bulletin A XML is supported\n\
         IERS Bulletin A ASCII updated for NAOS",
      "0.0.5"  =>    "Celestrak CssiSpaceWeather Daily Prediction is supported\n\
         Celestrak TCA (TLE catalogue) is supported\n\
         Celestrak TLE (TLE mission)   is supported\n\
         NASA MSFC Solar Flux (F10.7) / Geomagnetic disturbance (Ap) is supported\n\
         NASA CDDIS Bulletin A / Earth Orientation Parameters is supported\n\
         NASA CDDIS Bulletin C / TAI-UTC is supported",
      "0.0.4"  =>    "NOAA Report Solar Geophysical Activity is supported", \
      "0.0.3"  =>    "IERS Bulletin A / Earth Orientation Parameters is supported", \
      "0.0.2"  =>    "IGS Broadcast Ephemeris Daily is supported", \
      "0.0.1"  =>    "IERS Bulletin C / TAI-UTC is supported", \
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
