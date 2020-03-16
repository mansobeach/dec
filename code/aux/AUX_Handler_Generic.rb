#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #AUX_Parser_IGS_Broadcast_Ephemeris class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component
# 
# Git: $Id: AUX_Parser_Generic.rb,v 1.21 2013/03/14 13:40:57 bolf Exp $
#
# Module AUX management
# 
#
#########################################################################

require 'cuc/Converters'

module AUX

class AUX_Handler_Generic

   include CUC::Converters

   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, isDebug = false)
      if isDebug == true then
         setDebugMode
      end

      @full_path     = full_path
      @filename      = File.basename(full_path)
      @workingDir    = File.dirname(full_path)
      @full_path_new = nil
      @filename_new  = nil
      checkModuleIntegrity
   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   ## -------------------------------------------------------------
   
   ## rename the file
   def rename(newName)
      prevDir = Dir.pwd
      Dir.chdir(@workingDir)
      FileUtils.move(@filename, newName)
      Dir.chdir(prevDir)
      @full_path_new = "#{@workingDir}/#{newName}"
      @filename_new  = newName
   end
   ## -------------------------------------------------------------

private

   @listFiles = nil
   @mailer    = nil

   ## -----------------------------------------------------------
   
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      puts @full_path
      puts @filename
      
      if File.exist?(@full_path) == false then
         raise("#{@full_path} does not exist")
      end
      return
   end
   ## -----------------------------------------------------------

protected

   def getCreationDate
      puts self.strDateMidnight
   end
   ## -----------------------------------------------------------

end # class

end # module

