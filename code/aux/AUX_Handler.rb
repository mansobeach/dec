#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #AUX_Handler class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component
# 
# Git: $Id: AUX_Handler.rb,v 
#
# Module AUX management
# 
#
#########################################################################

require 'cuc/Converters'

require 'aux/AUX_Handler_CCSDS_OEM'
require 'aux/AUX_Handler_Celestrak_SFS'
require 'aux/AUX_Handler_Celestrak_TCA'
require 'aux/AUX_Handler_Celestrak_TLE'
require 'aux/AUX_Handler_IERS_BULA_ASCII'
require 'aux/AUX_Handler_IERS_BULA_XML'
require 'aux/AUX_Handler_IERS_EOP_Daily'
require 'aux/AUX_Handler_IERS_Leap_Second'
require 'aux/AUX_Handler_IFREMER_WAVEWATCH_III'
require 'aux/AUX_Handler_IGS_Broadcast_Ephemeris'
require 'aux/AUX_Handler_NASA_CDDIS_BULA'
require 'aux/AUX_Handler_NASA_CDDIS_BULC'
require 'aux/AUX_Handler_NASA_CDDIS_IONEX'
require 'aux/AUX_Handler_NASA_EOSDIS_ASTGTM'
require 'aux/AUX_Handler_NASA_EOSDIS_MOD09A1'
require 'aux/AUX_Handler_NASA_EOSDIS_SRTMGL1_Tile'
require 'aux/AUX_Handler_USGS_EROS_SRTMGL1_Tile'
require 'aux/AUX_Handler_NASA_MSFC_ForecastSolarFlux'
require 'aux/AUX_Handler_NOAA_RSGA_Daily'

module AUX

class AUX_Handler

   include CUC::Converters

   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target = "S3", targetDir = "", logger = nil, isDebug = false)
      @full_path  = full_path
      @filename   = File.basename(full_path)
      @path       = File.dirname(full_path)
      @targetDir  = targetDir
      @target     = target
      @logger     = logger
      @handler    = nil

      if isDebug == true then
         setDebugMode
      end
      
      checkModuleIntegrity
      
      # DO NOT DO IT
      # uncompress
      
      loadHandler
      
   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("AUX_Handler debug mode is on")
   end
   ## -------------------------------------------------------------
   
   ## rename the file
   def convert
      newName = @handler.convert
      return newName
   end
   ## -------------------------------------------------------------

private

   ## -----------------------------------------------------------
   
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      
      # puts "AUX_Handler::checkModuleIntegrity"
            
      if File.exist?(@full_path) == false and Dir.exist?(@full_path) == false then
         raise("#{@full_path} does not exist")
      end
      
      return
   end
   ## -----------------------------------------------------------

   def loadHandler
      
      filename = File.basename(@full_path)

      if File.fnmatch(AUX_Pattern_IFREMER_WAVEWATCH_III, filename) == true then
         @handler = AUX_Handler_IFREMER_WAVEWATCH_III.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end      

      if File.fnmatch(AUX_Pattern_NASA_CDDIS_IONEX, filename) == true then
         @handler = AUX_Handler_NASA_CDDIS_IONEX.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_CCSDS_OEM, filename) == true then
         @handler = AUX_Handler_CCSDS_OEM.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_NASA_MSFC_ForecastSolarFlux, filename) == true then
         @handler = AUX_Handler_NASA_MSFC_ForecastSolarFlux.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_Celestrak_SFS, filename) == true then
         @handler = AUX_Handler_Celestrak_SFS.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_Celestrak_TCA, filename) == true then
         @handler = AUX_Handler_Celestrak_TCA.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end   

      if File.fnmatch(AUX_Pattern_Celestrak_TLE, filename) == true then
         @handler = AUX_Handler_Celestrak_TLE.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_IERS_BULA_ASCII, filename) == true then
         @handler = AUX_Handler_IERS_BULA_ASCII.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_IERS_BULA_XML, filename) == true then
         @handler = AUX_Handler_IERS_BULA_XML.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_NASA_CDDIS_BULA, filename) == true then
         @handler = AUX_Handler_NASA_CDDIS_BULA.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_NASA_CDDIS_BULC, filename) == true then
         @handler = AUX_Handler_NASA_CDDIS_BULC.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_IERS_Leap_Second, filename.downcase) == true then
         @handler = AUX_Handler_IERS_Leap_Second.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_IERS_EOP_Daily, filename) == true then
         @handler = AUX_Handler_IERS_EOP_Daily.new(@full_path, @target, @targetDir)
         return
      end

      if File.fnmatch(AUX_Pattern_IGS_Broadcast_Ephemeris, filename.downcase) == true then
         @handler = AUX_Handler_IGS_Broadcast_Ephemeris.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end
      
      if File.fnmatch(AUX_Pattern_NOAA_RSGA_Daily, filename) == true then
         @handler = AUX_Handler_NOAA_RSGA_Daily.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end
      
      if File.fnmatch(AUX_Pattern_NASA_EOSDIS_ASTGTM, filename) == true then
         @handler = AUX_Handler_NASA_EOSDIS_ASTGTM.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_NASA_EOSDIS_SRTMGL1_Tile, filename) == true then
         @handler = AUX_Handler_NASA_EOSDIS_SRTMGL1_Tile.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_USGS_EROS_SRTMGL1_Tile, filename) == true then
         @handler = AUX_Handler_USGS_EROS_SRTMGL1_Tile.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      if File.fnmatch(AUX_Pattern_NASA_EOSDIS_MOD09A1, filename) == true then
         @handler = AUX_Handler_NASA_EOSDIS_MOD09A1.new(@full_path, @target, @targetDir, @logger, @isDebugMode)
         return
      end

      raise "no pattern found for #{filename}"
   end
   ## -----------------------------------------------------------

   def uncompress
      @logger.debug("AUX_Handler::uncompress start")
      # --------------------------------
      # compress tool .Z
      
      if File.extname(@filename) == ".Z" then
         @logger.debug("AUX_Handler::uncompress #{@filename}")
         cmd = "uncompress -f #{@full_path}"
         retVal = system(cmd)         
         if retVal == false then
            raise "Failed #{cmd}"
         end
         @full_path = @full_path.slice(0, @full_path.length-2)            
      end
      
      # --------------------------------
      @logger.debug("AUX_Handler::uncompress end")
   end
   ## -----------------------------------------------------------

end # class

end # module

