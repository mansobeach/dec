#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #AUX_Parser_IGS_Broadcast_Ephemeris class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component
# 
# Git: $Id: AUX_Hander_IGS_Broadcast_Ephemeris.rb,v 1.21 2013/03/14 13:40:57 bolf Exp $
#
# Module AUX management
# 
#
#########################################################################

### IERS Bulletin-C

### S3__GN_1_LSC_AX_20000101T000000_20130101T000000_20120901T030000___________________USN_O_NR_POD.SEN3

require 'Aux_Handler_Generic'

module AUX


class AUX_Handler_IERS_Leap_Second < AUX_Handler_Generic
   
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, isDebug = false)
      @target = target
      super(full_path, isDebug)
      checkModuleIntegrity
      puts @filename
   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   ## -------------------------------------------------------------
   
   def rename
   
      self.getCreationDate
   
      newName = "PEDOREERO"
      super(newName)
      return @full_path_new
   end
   ## -------------------------------------------------------------

   def convert
      self.getCreationDate
      
      puts
      
      puts
      
      parse
      
      puts
   end
   ## -------------------------------------------------------------

private

   @listFiles = nil
   @mailer    = nil

   ## -----------------------------------------------------------
   
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      
      if @target != "POD" and @target != "S3" then
         raise "target #{@target} different than POD and S3"
      end

      return
   end
   ## -----------------------------------------------------------

   def convert_S3
   end
   ## -------------------------------------------------------------

   def convert_POD
      raise "Not Implemented yet"
   end
   ## -------------------------------------------------------------

   def parse
      File.readlines(@full_path).each do |line|
         if line.include?("File expires on") == true then
            puts line
         end
      end
   end
   ## -------------------------------------------------------------
      
end # class

end # module

