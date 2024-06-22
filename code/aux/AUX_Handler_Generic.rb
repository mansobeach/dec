#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #AUX_Handler_Generic class
#
# Module AUX management
# 
#
#########################################################################

require 'cuc/DirUtils'
require 'cuc/Converters'
require 'cuc/FT_PackageUtils'

require 'aux/AUX_Environment'


module AUX

class AUX_Handler_Generic

   include AUX
   include CUC::Converters
   include CUC::DirUtils

   attr_reader :input_file_pattern

   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, dir, logger = nil, isDebug = false)
      @logger = logger
      
      if isDebug == true then
         setDebugMode
      end

      # This needs to become a configuration item
      @fileClass           = "OPER"
      @fileVersion         = "0001"
      @full_path           = full_path
      @targetDir           = dir
      @filename            = File.basename(full_path)
      @workingDir          = File.dirname(full_path)
      @full_path_new       = nil
      @filename_new        = nil
      @input_file_pattern  = "*"
      
      @strValidityStart    = ""
      @strValidityStop     = ""
            
      checkModuleIntegrity
   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("AUX_Handler_Generic debug mode is on")
   end
   ## -------------------------------------------------------------
   
   ## rename the file
   def rename(newName)
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_Generic::rename(#{@filename} / #{newName} -> #{@full_path_new})")
      end
      
      prevDir = Dir.pwd
      Dir.chdir(@workingDir)
      
      if @isDebugMode == true then
         @logger.debug("current directory #{@workingDir}")
      end
    
      if @targetDir != "" and @targetDir != nil then
         @full_path_new = "#{@targetDir}/#{newName}"

         if File.exist?(@full_path_new) == true then
            if @isDebugMode == true then
               @logger.debug("Deleting a previously existing file #{@full_path_new}")
            end
            FileUtils.rm(@full_path_new)
         end

         FileUtils.move(@filename, @full_path_new, force:true)
      else
         if File.exist?(newName) == true then
            if @isDebugMode == true then
               @logger.debug("Deleting a previously existing file #{newName}")
            end
            FileUtils.rm(newName)
         end

         if @isDebugMode == true then
            @logger.debug(Dir.pwd)
         end
         FileUtils.move(@filename, newName, force:true)
         @full_path_new = "#{@workingDir}/#{newName}"
      end
      
      if @isDebugMode == true then
         @logger.debug("#{@full_path_new} generated")
      end
      @logger.info("[AUX_001] #{newName} generated from #{@filename}")

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
      return getCreationDateMidnight
   end
   ## -----------------------------------------------------------

   def getCreationDateMidnight
      return self.strDateMidnight
   end
   ## -----------------------------------------------------------

   def getCreationDateNow
      return self.strDateNow
   end
   ## -----------------------------------------------------------


end # class

end # module

