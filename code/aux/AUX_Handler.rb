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

require 'aux/AUX_Handler_IERS_Leap_Second'

module AUX

class AUX_Handler

   include CUC::Converters

   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target = "S3", isDebug = false)
      @full_path  = full_path
      @target     = "S3"
      @handler    = nil
      
      if isDebug == true then
         setDebugMode
      end
      
      checkModuleIntegrity
      
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
      
      if File.exist?(@full_path) == false then
         raise("#{@full_path} does not exist")
      end
      return
   end
   ## -----------------------------------------------------------

   def loadHandler
      filename = File.basename(@full_path, ".*")
      
      if filename.downcase.include?("leap_second") then
         @handler = AUX_Handler_IERS_Leap_Second.new(@full_path, @target)
         return
      end
            
      raise "no pattern found for #{filename}"
   end
   ## -----------------------------------------------------------

end # class

end # module

