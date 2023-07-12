#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_NASA_EOSDIS_ASTGTM class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_NASA_EOSDIS_ASTGTM.rb
###
### Module AUX management
### 
###
#########################################################################

### NASA EOSDIS ASTGTM V3
### https://lpdaac.usgs.gov/products/astgtmv003/


### NAOS Conversion
### NAOS-TN-OHBI-016 issue 6 13/10/2022

# ASTER:
# ASTERV3 tiles are named with a format like
# ASTERV3DEM/aXX/ASTGTMV003_aXXbYYY/ASTGTMV003_aXXbYYY_dem.tif
# where
# a is N=>north[0-83] or S=>south[1-83] XX is the lower latitude ,
# b is E=>east[0-179] or W=>west[1-180] YYY is the left longitude .
# Each tile covers a 1-degree by 1-degree area.
# ASTERV3DEM/S15/ASTGTMV003_S15W049/ASTGTMV003_S15W049_dem.tif

require 'fileutils'
require 'filesize'
require 'rexml/document'

require 'aux/AUX_Handler_Generic'

module AUX

AUX_Pattern_NASA_EOSDIS_ASTGTM = "*AST*V*3*"

NUM_FILES=22912

class AUX_Handler_NASA_EOSDIS_ASTGTM < AUX_Handler_Generic
   
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

      @arrTiles = Array.new
   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("AUX_Handler_NASA_EOSDIS_ASTGTM debug mode is on")
   end
   ## -------------------------------------------------------------
   
   # NS1_OPER_ASTERV3DEM_20000301T000000_20131130T235959_0003.ZIP
   def rename
      @newName = "#{@mission}_#{@fileClass}_#{@fileType}_#{@strValidityStart}_#{@strValidityStop}_#{@fileVersion}.#{@extension}"
      
      cmd = "zip -r #{@newName} #{@full_path}/"
      @logger.info(cmd)
      ret = system(cmd)

      return @newName
   end
   ## -------------------------------------------------------------

   def convert
      @strCreation = self.getCreationDate 
      parse
      return rename
   end
   ## -------------------------------------------------------------

private

   @listFiles = nil
   
   ## -----------------------------------------------------------
   
   def convert_NAOS
      @mission    = "NS1"
      @fileType   = "ASTERV3DEM"
      @extension  = "ZIP"
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
         @logger.debug("AUX_Handler_NASA_EOSDIS_ASTGTM::parse")
      end

      prevDir = Dir.pwd

      # @full_path iteration needed

      # METADATA only
      arrFiles = Dir["#{@full_path}/ASTGTMV003_*.xml"]

      if arrFiles.length != NUM_FILES then
         @logger.error("Missing metadata files: #{arrFiles.length} vs #{NUM_FILES}")
         raise "Missing metadata files: #{arrFiles.length} vs #{NUM_FILES}"
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

            break

         end
         # ----------------------------
      }

      arrFiles = Dir["#{@full_path}/ASTGTMV003_*.zip"]

      if arrFiles.length != NUM_FILES then
         @logger.error("Missing zip files: #{arrFiles.length} vs #{NUM_FILES}")
         raise "Missing zip files: #{arrFiles.length} vs #{NUM_FILES}"
      end

      arrFiles.each{|aFile|

         tile   = File.basename(aFile, ".*")
         degree = File.basename(aFile, "*.zip").split('_')[1].slice(0,3)

         path   = "#{@full_path}/#{degree}/#{tile}"
         FileUtils.mkdir_p(path)
         @logger.debug(path)

         cmd = "mv #{@full_path}/#{tile}.* #{path}"
         if @isDebugMode == true then
            @logger.debug(cmd)
         end

         ret = system(cmd)

         cmd = "unzip #{path}/#{tile}.zip -d #{path}"
         if @isDebugMode == true then
            @logger.debug(cmd)
         end

         ret = system(cmd)
   
         if ret == false then
            @logger.error("error when unzipping tile #{aFile}")
            @logger.error("failed: #{cmd}")
            break
         end
   
         cmd = "rm -f #{path}/#{tile}.zip"
         if @isDebugMode == true then
            @logger.debug(cmd)
         end

         ret = system(cmd)

      }

      @logger.info("ASTGTM #{@strValidityStart} #{@strValidityStop} Total size: #{Filesize.from("#{iSize}").pretty}")
      
      Dir.chdir(prevDir)

   end
   ## -------------------------------------------------------------
      
end # class

end # module

