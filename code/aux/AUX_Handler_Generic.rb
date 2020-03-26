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

require 'cuc/DirUtils'
require 'cuc/Converters'
require 'cuc/FT_PackageUtils'

module AUX

class AUX_Handler_Generic

   include CUC::Converters
   include CUC::DirUtils

   attr_reader :input_file_pattern

   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, dir, isDebug = false)
   
      # puts "AUX_Handler_Generic::initialize"   
   
      if isDebug == true then
         setDebugMode
      end

      @full_path           = full_path
      @targetDir           = dir
      @filename            = File.basename(full_path)
      @workingDir          = File.dirname(full_path)
      @full_path_new       = nil
      @filename_new        = nil
      @input_file_pattern  = "*"
      
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
      
      if File.exist?(newName) == true then
         FileUtils.rm(newName)
      end
      
      if @targetDir != "" and @targetDir != nil then
         @full_path_new = "#{@targetDir}/#{newName}"
         FileUtils.move(@filename, @full_path_new, force:true)
         
      else
         FileUtils.move(@filename, newName, force:true)
         @full_path_new = "#{@workingDir}/#{newName}"
      end
      
      Dir.chdir(prevDir)
      
      @filename_new  = newName
   end
   ## -------------------------------------------------------------

private

   @listFiles = nil
   @mailer    = nil

   ## -----------------------------------------------------------
   
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      
      # puts "AUX_Handler_Generic::checkModuleIntegrity"  
      
      if @targetDir != "" and @targetDir != nil then
         checkDirectory(@targetDir)
      end
      
      if File.exist?(@full_path) == false then
         raise("#{@full_path} does not exist")
      end
      return
   end
   ## -----------------------------------------------------------

protected

   def getCreationDate
      return self.strDateMidnight
   end
   ## -----------------------------------------------------------

end # class

end # module

