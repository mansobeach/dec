#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_USGS_EROS_SRTMGL1_Tile class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_USGS_EROS_SRTMGL1_Tile.rb
###
### Module AUX management
### 
###
#########################################################################

### NASA EOSDIS ASTGTM V3
### https://lpdaac.usgs.gov/products/srtmgl1v003/

### DEM is supplied as geotiff / likely converted with GDAL

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

AUX_Pattern_USGS_EROS_SRTMGL1_Tile = "???_????_1arc_v3.tif"

class AUX_Handler_USGS_EROS_SRTMGL1_Tile < AUX_Handler_Generic
   
   include REXML

   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)
      @target = target
      
      begin
         require 'gdal'
      rescue Exception => e
         raise "#{e.to_s}"
      end

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
      @logger.debug("AUX_Handler_USGS_EROS_SRTMGL1_Tile debug mode is on")
   end
   ## -------------------------------------------------------------
   
   # NS1_OPER_ASTERV3DEM_20000301T000000_20131130T235959_0003.ZIP
   def rename
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_USGS_EROS_SRTMGL1_Tile::rename")
      end

      return
   end
   ## -------------------------------------------------------------

   def convert
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_USGS_EROS_SRTMGL1_Tile::convert")
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
         @logger.debug("AUX_Handler_USGS_EROS_SRTMGL1_Tile::convert_NAOS")
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
         @logger.debug("AUX_Handler_USGS_EROS_SRTMGL1_Tile::parse")
      end

      lat         = @filename.slice(1,2).to_f
      lon         = @filename.slice(5,3).to_f
      currentLat  = lat
      currentLon  = lon

      bLonEast    = nil
      bLatNorth   = nil
      
      if @filename.slice(0,1) == 'n' then
         bLatNorth = true
         currentLat = currentLat + 1
      elsif @filename.slice(0,1) == 's' then
         bLatNorth = false
      else
         @logger.error("SRTM height filename #{@filename} does not meet [n|s]_XX[e|w]YYY_1arc_v3.tif")
         raise "Incorrect SRTMGL1 filename #{@filename}"
      end

      if @filename.slice(4,1) == 'e' then
         bLonEast = true
      elsif @filename.slice(4,1) == 'w' then
         bLonEast = false
      else
         @logger.error("SRTM height filename #{@filename} does not meet [n|s]_XX[e|w]YYY_1arc_v3.tif")
         raise "Incorrect SRTMGL1 filename #{@filename}"
      end

      if @isDebugMode == true then
         @logger.debug("SRTMGL1 Tile lat: #{lat}#{@filename.slice(0,1)} lon: #{lon}#{@filename.slice(4,1)}")
      end
      
      geotiff = Gdal::Gdal.open(@full_path)
      dem     = geotiff.get_raster_band(1)

      if @isDebugMode == true then
         geotiff.get_metadata_list.each{|item|
            @logger.debug(item)
         }
         @logger.debug("#{dem.XSize} - #{dem.YSize} => #{Gdal::Gdal.get_data_type_name(dem.DataType)}")
      end


      for i in 0..dem.XSize-1 do
          
         for j in 0..dem.YSize-1 do
            # puts dem.read_raster(j, i, 1, 1)
            # unpack as a 16-bit unsigned, native endian (uint16_t)
            value = dem.read_raster(j, i, 1, 1).unpack('S')

            if @isDebugMode == true then
               @logger.debug("raster[#{j},#{i}] => #{currentLat} #{@filename.slice(0,1)} degrees #{currentLon} #{@filename.slice(4,1)} degrees => #{value[0]} metres")
            end

            if bLonEast == true then
               currentLon = currentLon + (1 / (60.0 * 60.0)) 
            else
               currentLon = currentLon - (1 / (60.0 * 60.0))
            end

            if j == 3600 then
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
