#!/usr/bin/env ruby

require 'rubygems'
require 'fileutils'

require 'dotenv'

module AUX
   
   VERSION   = "0.0.9.5"
      
   ## -----------------------------------------------------------------
   
   CHANGE_RECORD = { \
      "0.0.9"  =>    "ESA Sentinels SAFE format support\n\
         Dynamic configuration parameters from env files\n\
         Independent installation removing dependencies",
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
   
   # load config

   def load_config
      # --------------------------------
      if !ENV['AUX_CONFIG'] then
         ENV['AUX_CONFIG'] = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      end
   end

   ## -----------------------------------------------------------------

   def checkEnvironmentEssential

      load_config

      bCheck = true

      # --------------------------------
      if !ENV['AUX_CONFIG'] then
         ENV['AUX_CONFIG'] = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      end
      # --------------------------------
      if bCheck == false then
         puts "AUX Essential environment variables configuration not complete"
         puts
         return false
      end
      return true
   end
   ## -----------------------------------------------------------------

   def load_logger(label = "aux_converter")

      require 'cuc/Log4rLoggerFactory'

      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new(label, "#{ENV['AUX_CONFIG']}/aux_log_config.xml")

      @logger = loggerFactory.getLogger

      if @logger == nil then
         puts "Could not set up logging system !  :-("
         puts "Check AUX logs configuration under \"#{ENV['AUX_CONFIG']}/aux_log_config.xml\""
         puts
         puts
         exit(99)
      end

      return @logger
   end
   ## -----------------------------------------------------------------

   def load_environment(target)
      environment = "env/#{target}.env"
      begin
         Dotenv.load(environment)
      rescue Exception
      end
   end

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
   
   def wrapper_load_config
      load_config
   end

   def wrapper_load_logger(label)
      load_logger(label)
   end

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
