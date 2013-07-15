#!/usr/bin/env ruby

#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#
#########################################################################

require 'rubygems'
require 'numru/netcdf'
require 'spreadsheet'

require 'ws23rb/WS_PlugIn_Loader'


module WS23RB

include NumRu

class NetCDFConvFromWSExcelFile

   attr_reader :date, :time, :temperature_indoor, :temperature_outdoor, :humidity_indoor,
       :dewpoint, :forecast, :humidity_outdoor, :pressure, :rain_1hour, :windchill,
       :wind_direction, :wind_speed
   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename, vbleName, debug = false)
      @excelname           = filename
      @variableName        = vbleName.downcase
      @isDebugMode         = debug
      @book                = Spreadsheet.open(@excelname)
      @sheet               = @book.worksheet 0
      @columnVble          = 0
      @plugIn              = nil
      checkModuleIntegrity
      loadPlugIn
      createNetCDF
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "NetCDFConvFromWSExcelFile debug mode is on"
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------

   #-------------------------------------------------------------
   
private

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true

      header   = @sheet.row(0)

      if header.include?(@variableName) == false then
         puts
         puts "#{@variableName} not found in #{File.basename(@excelname)} header"
         puts
         bCheckOK = false
      else
         @columnVble = header.index(@variableName)
      end

      if bCheckOK == false then
        puts "NetCDFConvFromWSExcelFile::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
   end
   #-------------------------------------------------------------

   def createNetCDF

      nValues = @sheet.dimensions[1]
      sVar    = @sheet[0,@columnVble]
      varType = ""

      start   = "#{@sheet[1,0]}T#{@sheet[1,1]}"
      start   = start.gsub("-","")
      start   = start.gsub(":","")

      stop    = "#{@sheet[nValues-1,0]}T#{@sheet[nValues-1,1]}"
      stop    = stop.gsub("-","")
      stop    = stop.gsub(":","")

      if @sheet[1,@columnVble].to_s.include?(".") == true then
         varType = "float"
      else
         varType = "int"
      end

      @netCDFfile = NumRu::NetCDF.create("#{sVar}_#{start}_#{stop}.nc")

      # ------------------------------------------------
      # Dimensions

      # Unlimited size
      dimTime = @netCDFfile.def_dim("Time", 0)

      # ------------------------------------------------
      # Global Attributes

      @netCDFfile.put_att("Created", "Casale & Beach")
      @netCDFfile.put_att("History", "created #{Time.now}")

      if @plugIn != nil then
         @netCDFfile.put_att("Verified", "TRUE")
      else
         @netCDFfile.put_att("Verified", "FALSE")
      end

      @netCDFfile.put_att("First_Time", start)
      @netCDFfile.put_att("Last_Time", stop)

      # ------------------------------------------------

      # Variables

      varTime = @netCDFfile.def_var("Time","int",[dimTime])
      varTime.put_att("long_name","Time since Epoch")
      varTime.put_att("unit", "seconds since Epoch 1970-01-01 00:00 UTC")

      varMain = @netCDFfile.def_var(sVar,varType,[dimTime])

      if @plugIn != nil then
         varMain.put_att("unit", @plugIn.unit)
      end


      # ------------------------------------------------

      @netCDFfile.enddef

      # ------------------------------------------------

      idx = 0

      @sheet.each{|row|
         if row[0].downcase == "date" then
            next
         end

         # ---------------------------------------
         # if plug-in, verify threshold values
         if @plugIn != nil then
            ret = @plugIn.verifyThresholds(row[@columnVble].to_f)
            if ret == false then
               next
            end
         end
         # ---------------------------------------

         arr = row[0].split("-")
         arr.concat(row[1].split(":"))

         # Create UTC Time
         atime = Time.utc(arr[0], arr[1], arr[2], arr[3], arr[4], arr[5])
  
         varTime.put(atime.to_i, "index"=>[idx])
         varMain.put(row[@columnVble].to_f, "index"=>[idx])

         idx = idx + 1

      }
      # ------------------------------------------------

   end
   #-------------------------------------------------------------

   def loadPlugIn
      @plugIn = WS23RB::WS_PlugIn_Loader.new(@variableName, @isDebugMode)
      if @plugIn.isPlugInLoaded? == false then
         @plugIn = nil
      end
   end
   #-------------------------------------------------------------

   #-------------------------------------------------------------

end # class

end # module
