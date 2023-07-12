#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_NASA_EOSDIS_MOD09A01 class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_NASA_EOSDIS_MOD09A01.rb
###
### Module AUX management
### 
###
#########################################################################

### NASA EOSDIS MODIS MOD09A01 V6.1
### https://ladsweb.modaps.eosdis.nasa.gov/filespec/MODIS/61/MOD09A1_c61

require 'filesize'
require 'rexml/document'

require 'aux/AUX_Handler_Generic'

module AUX

AUX_Pattern_NASA_EOSDIS_MOD09A1 = "*MOD09A1*"

class AUX_Handler_NASA_EOSDIS_MOD09A1 < AUX_Handler_Generic
   
   include REXML

   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)

      @target = target
      
      super(full_path, dir, logger, isDebug)
      
      case @target.upcase
         when "NAOS" then convert_NAOS
         when "S3"   then convert_S3
         when "POD"  then convert_POD
         else raise "#{@target.upcase} not supported"
      end

      @@num_files = 305

   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("AUX_Handler_NASA_EOSDIS_MOD09A01 debug mode is on")
   end
   ## -------------------------------------------------------------
   
   # NS1_OPER_AUX_RFM____20220707T000000_99999999T999999_0001.ZIP
   def rename
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_NASA_EOSDIS_MOD09A1::rename")
      end
      @newName = "#{@mission}_#{@fileClass}_#{@fileType}_#{@strValidityStart}_#{@strValidityStop}_#{@fileVersion}.#{@extension}"
      return
   end
   ## -------------------------------------------------------------

   def convert
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_NASA_EOSDIS_MOD09A1::convert")
      end
      @strCreation = self.getCreationDate

      parse

      rename
      
      prevDir = Dir.pwd
      Dir.chdir(@full_path)
      if @isDebugMode == true then
         @logger.debug("CWD changed to #{Dir.pwd}")
      end

      @logger.debug(@newName)
      @logger.debug(@targetDir)
      cmd = "zip -0 -r -m -T #{@targetDir}/#{@newName} MOD09A1*"
      
      if @isDebugMode == true then
         @logger.debug(cmd)
      end
      ret = system(cmd)
      
      Dir.chdir(prevDir)
      if @isDebugMode == true then
         @logger.debug("CWD changed to #{Dir.pwd}")
      end
   end
   ## -------------------------------------------------------------

private

   @listFiles = nil
   
   ## -----------------------------------------------------------
   
   def convert_NAOS
      @mission    = "NS1"
      @fileType   = "AUX_RFM___"
      @extension  = "zip"
   end
   ## -----------------------------------------------------------

   def convert_S3
      raise "not implemented for #{@target}"
   end
   ## -------------------------------------------------------------

   def convert_POD
      raise "not implemented for #{@target}"
   end
   ## -------------------------------------------------------------

   def parse
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_NASA_EOSDIS_MOD09A01::parse")
      end

      prevDir = Dir.pwd

      # @full_path iteration needed

      arrFiles = Dir["#{@full_path}/MOD09A1*.hdf"]

      if arrFiles.length != @@num_files then
         @logger.error("Missing hdf files: #{arrFiles.length} vs #{@@num_files}")
      end

      arrFiles = Dir["#{@full_path}/MOD09A1*.xml"]

      if arrFiles.length != @@num_files then
         @logger.error("Missing metadata files: #{arrFiles.length} vs #{@@num_files}")
      end

      iSize    = 0
      bFirst   = true

      arrFiles.each{|aFile|
         if @isDebugMode == true then
            @logger.debug(aFile)
         end
         fileHandler       = File.new(aFile)
         xmlFile           = REXML::Document.new(fileHandler)
         path              = "GranuleMetaDataFile/GranuleURMetaData/DataFiles/DataFileContainer/FileSize"
         XPath.each(xmlFile, path){
            |size|
            iSize = iSize + size.text.to_i
         }

         # ----------------------------
         #
         # extract the first metadata
         if bFirst == true then
            bFirst = false
            path   = "GranuleMetaDataFile/GranuleURMetaData/CollectionMetaData/VersionID"
            XPath.each(xmlFile, path){
               |version|
               @fileVersion = version.text.to_s.rjust(4,'0')
            }
            path   = "GranuleMetaDataFile/GranuleURMetaData/CollectionMetaData/ShortName"
            XPath.each(xmlFile, path){
               |name|
               @name = name.text
            }
            @logger.info("Found #{@name}:#{@fileVersion}")

            path   = "GranuleMetaDataFile/GranuleURMetaData/RangeDateTime/RangeBeginningDate"
            XPath.each(xmlFile, path){
               |date_start|
               @date_start = date_start.text.to_s.gsub('-', '')
            }

            path   = "GranuleMetaDataFile/GranuleURMetaData/RangeDateTime/RangeBeginningTime"
            XPath.each(xmlFile, path){
               |time_start|
               @time_start = time_start.text.to_s.slice(0,8).gsub(':', '')
            }

            path   = "GranuleMetaDataFile/GranuleURMetaData/RangeDateTime/RangeEndingDate"
            XPath.each(xmlFile, path){
               |date_end|
               @date_end = date_end.text.to_s.gsub('-', '')
            }

            path   = "GranuleMetaDataFile/GranuleURMetaData/RangeDateTime/RangeEndingTime"
            XPath.each(xmlFile, path){
               |time_end|
               @time_end = time_end.text.to_s.slice(0,8).gsub(':', '')
            }

            @strValidityStart = "#{@date_start}T#{@time_start}"
            @strValidityStop  = "#{@date_end}T#{@time_end}"

         end
         # ----------------------------
      }

      @logger.info("MOD09A1 #{@strValidityStart} #{@strValidityStop} Total size: #{Filesize.from("#{iSize}").pretty}")
      Dir.chdir(prevDir)

   end
   ## -------------------------------------------------------------
      
end # class

end # module
