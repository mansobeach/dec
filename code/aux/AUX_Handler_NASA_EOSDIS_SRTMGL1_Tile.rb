#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_NASA_EOSDIS_SRTMGL1_Tile class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_NASA_EOSDIS_SRTMGL1_Tile.rb
###
### Module AUX management
### 
###
#########################################################################

### NASA EOSDIS ASTGTM V3
### https://lpdaac.usgs.gov/products/srtmgl1v003/

# 3601/3601 1 arc-second  (30 metres) => 12967201 items
# SRTM1 data are sampled at 1 arc-second of latitude and longitude and each file contains 3,601 lines and 3,601 samples. 
# The rows at the north and south edges, as well as the columns at the east and west edges of each tile, overlap, and are identical to, the edge rows and columns in the
# adjacent tile

# The data are in "geographic" projection ( also known as Equirectangular or Plate Carrée) , which
# means the data is presented with respectively equal intervals of latitude and longitude in the
# vertical and horizontal dimensions. More technically, the projection maps meridians to vertical
# straight lines of constant spacing, and circles of latitude (“parallels”) to horizontal straight lines
# of constant spacing. This might be thought of as no projection at all, but simply a latitude -
# longitude data array.

# The two-byte data are in Motorola "big-endian" order with the most significant byte first.

require 'fileutils'
require 'filesize'
require 'rexml/document'

require 'aux/AUX_Handler_Generic'

module AUX

AUX_Pattern_NASA_EOSDIS_SRTMGL1_Tile = "???????.hgt"

class AUX_Handler_NASA_EOSDIS_SRTMGL1_Tile < AUX_Handler_Generic
   
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
         else convert
      end

      @arrTiles = Array.new
   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("AUX_Handler_NASA_EOSDIS_SRTMGL1_Tile debug mode is on")
   end
   ## -------------------------------------------------------------
   
   # NS1_OPER_ASTERV3DEM_20000301T000000_20131130T235959_0003.ZIP
   def rename
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_NASA_EOSDIS_SRTMGL1_Tile::rename")
      end

      return
   end
   ## -------------------------------------------------------------

   def convert
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_NASA_EOSDIS_SRTMGL1_Tile::convert")
      end
      # @strCreation = self.getCreationDate 
      parse
      return rename
   end
   ## -------------------------------------------------------------

private

   @listFiles = nil
   
   ## -----------------------------------------------------------
   
   def convert_NAOS
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_NASA_EOSDIS_SRTMGL1_Tile::convert_NAOS")
      end
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

   ## -------------------------------------------------------------

   def parse
      
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_NASA_EOSDIS_SRTMGL1_Tile::parse")
      end

      lat         = @filename.slice(1,2).to_f
      lon         = @filename.slice(4,3).to_f
      currentLat  = lat
      currentLon  = lon

      bLonEast    = nil
      bLatNorth   = nil
      
      if @filename.slice(0,1) == 'N' then
         bLatNorth = true
         currentLat = currentLat + 1
      elsif @filename.slice(0,1) == 'S' then
         bLatNorth = false
      else
         @logger.error("SRTM height filename #{@filename} does not meet [N|S]XX[E|W]YYY.hgt")
         raise "Incorrect SRTMGL1 filename #{@filename}"
      end

      if @filename.slice(3,1) == 'E' then
         bLonEast = true
      elsif @filename.slice(3,1) == 'W' then
         bLonEast = false
      else
         @logger.error("SRTM height filename #{@filename} does not meet [N|S]XX[E|W]YYY.hgt")
         raise "Incorrect SRTMGL1 filename #{@filename}"
      end

      if @isDebugMode == true then
         @logger.debug("SRTMGL1 Tile lat: #{lat}#{@filename.slice(0,1)} lon: #{lon}#{@filename.slice(3,1)}")
      end
      
      idx         = 1

      File.open(@full_path, "rb") do |handler|
         while rawbytes = handler.read(2)
            # DEM is encoded as 16bit big endian / need to covert to little endian
            bytes       = rawbytes.unpack('CC')
            value       = bytes[0] << 8 | bytes[1]
            
            if @isDebugMode == true then
               @logger.debug("[#{idx}] - #{currentLat} #{@filename.slice(0,1)} degrees #{currentLon} #{@filename.slice(3,1)} degrees => #{value} metres")
            end
            
            idx+=1

            if bLonEast == true then
               currentLon = currentLon + (1 / (60.0 * 60.0)) 
            else
               currentLon = currentLon - (1 / (60.0 * 60.0))
            end

            if idx % 3600 == 0 then
               currentLon  = lon
               if bLatNorth == true then
                  currentLat = currentLat - (1 / (60.0 * 60.0)) 
               else
                  currentLat = currentLat + (1 / (60.0 * 60.0))
               end
            end
         end
      end
   end
   ## -------------------------------------------------------------
      
end # class

end # module
