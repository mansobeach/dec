#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #AUX_Handler class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component
# 
# Git: $Id: AUX_Handler.rb,v 1.21 2013/03/14 13:40:57 bolf Exp $
#
# Module AUX management
# 
#
#########################################################################

require 'cuc/Converters'

require 'aux/AUX_Handler_IERS_EOP_Daily'
require 'aux/AUX_Handler_IERS_Leap_Second'
require 'aux/AUX_Handler_IGS_Broadcast_Ephemeris'
require 'aux/AUX_Handler_NOAA_RSGA_Daily'

module AUX

class AUX_Handler

   include CUC::Converters

   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target = "S3", targetDir = "", isDebug = false)
      @full_path  = full_path
      @filename   = File.basename(full_path)
      @path       = File.dirname(full_path)
      @targetDir  = targetDir
      @target     = "S3"
      @handler    = nil

      if isDebug == true then
         setDebugMode
      end
      
      checkModuleIntegrity
      
      uncompress
      
      loadHandler
      
   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
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
            
      if File.exist?(@full_path) == false then
         raise("#{@full_path} does not exist")
      end
      
      return
   end
   ## -----------------------------------------------------------

   def loadHandler
      
      filename = File.basename(@full_path)
            
      if File.fnmatch(AUX_Pattern_IERS_Leap_Second, filename.downcase) == true then
         @handler = AUX_Handler_IERS_Leap_Second.new(@full_path, @target, @targetDir)
         return
      end

      if File.fnmatch(AUX_Pattern_IERS_EOP_Daily, filename) == true then
         @handler = AUX_Handler_IERS_EOP_Daily.new(@full_path, @target, @targetDir)
         return
      end

      if File.fnmatch(AUX_Pattern_IGS_Broadcast_Ephemeris, filename.downcase) == true then
         @handler = AUX_Handler_IGS_Broadcast_Ephemeris.new(@full_path, @target, @targetDir)
         return
      end
      
      if File.fnmatch(AUX_Pattern_NOAA_RSGA_Daily, filename) == true then
         @handler = AUX_Handler_NOAA_RSGA_Daily.new(@full_path, @target, @targetDir)
         return
      end      
      
      raise "no pattern found for #{filename}"
   end
   ## -----------------------------------------------------------

   def uncompress
      
      # --------------------------------
      # compress tool .Z
      
      if File.extname(@filename) == ".Z" then
         cmd = "uncompress -f #{@full_path}"
         retVal = system(cmd)         
         if retVal == false then
            raise "Failed #{cmd}"
         end
         @full_path = @full_path.slice(0, @full_path.length-2)            
      end
      
      # --------------------------------
      
   end
   ## -----------------------------------------------------------

end # class

end # module

