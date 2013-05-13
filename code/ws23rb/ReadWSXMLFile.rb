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

require 'rexml/document'

#module WS

class ReadWSXMLFile

   include REXML

   attr_reader :date, :time, :temperature_indoor, :temperature_outdoor, :humidity_indoor,
       :dewpoint, :forecast, :humidity_outdoor, :pressure, :rain_1hour, :rain_24hours, :windchill,
       :wind_direction, :wind_speed
   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename = "", debug = false)
      @filename            = filename
      @isDebugMode         = debug
      @arrAttrNonReader    = ["filename", "isDebugMode", "arrAttrNonReader"]
      checkModuleIntegrity
      if filename != "" then
         loadData
      end
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadWSXMLFile debug mode is on"
   end
   #-------------------------------------------------------------
   
   def listOfMeteoVariables
      arr = self.instance_variables
      res = Array.new
      arr.each{|vble|
         if @arrAttrNonReader.include?(vble.split("@")[1]) then
            next
         else
            res << vble.split("@")[1]
         end
      }
      return res.compact.sort
   end
   #-------------------------------------------------------------
   
private

   def initVariables
      return
   end
   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      if bCheckOK == false then
        puts "ReadWSXMLFile::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
      @date                = ""
      @dewpoint            = ""
      @forecast            = ""
      @humidity_indoor     = ""
      @humidity_outdoor    = ""
      @pressure            = ""
      @rain_1hour          = ""
      @rain_24hours        = ""
      @temperature_indoor  = ""
      @temperature_outdoor = ""
      @time                = ""
      @wind_direction      = ""
      @wind_speed          = ""
      @windchill           = ""
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def loadData
      fileDecode        = File.new(@filename)

      begin
         xmlFile           = REXML::Document.new(fileDecode)
         if @isDebugMode == true then
            puts "\nParsing #{@filename}"
         end
      rescue Exception => e
         if @isDebugMode == true then
            puts "ERROR XML Parsing #{@filename}"
            puts e
         end
         return false
      end
      
      XPath.each(xmlFile, "ws2300/Date"){
         |date|
         @date = date.text
      }

      XPath.each(xmlFile, "ws2300/Time"){
         |time|
         @time = time.text
      }

      XPath.each(xmlFile, "ws2300/Temperature/Indoor/Value"){
         |value|
         @temperature_indoor = value.text
      }

      XPath.each(xmlFile, "ws2300/Humidity/Indoor/Value"){
         |value|
         @humidity_indoor = value.text
      }

      XPath.each(xmlFile, "ws2300/Temperature/Outdoor/Value"){
         |value|
         @temperature_outdoor = value.text
      }

      XPath.each(xmlFile, "ws2300/Humidity/Outdoor/Value"){
         |value|
         @humidity_outdoor = "#{value.text}.0"
      }

      XPath.each(xmlFile, "ws2300/Dewpoint/Value"){
         |value|
         @dewpoint = value.text
      }

      XPath.each(xmlFile, "ws2300/Wind/Value"){
         |value|
         @wind_speed = value.text
      }

      XPath.each(xmlFile, "ws2300/Wind/Direction/Dir0"){
         |value|
         @wind_direction = value.text
      }

      XPath.each(xmlFile, "ws2300/Windchill/Value"){
         |value|
         @windchill = value.text
      }

      XPath.each(xmlFile, "ws2300/Rain/OneHour/Value"){
         |value|
         @rain_1hour = value.text
      }

      XPath.each(xmlFile, "ws2300/Rain/TwentyFourHour/Value"){
         |value|
         @rain_24hours = value.text
      }

      XPath.each(xmlFile, "ws2300/Pressure/Value"){
         |value|
         @pressure = value.text
      }

      XPath.each(xmlFile, "ws2300/Forecast"){
         |value|
         @forecast = value.text
      }


#       if @isDebugMode == true then
#          puts @date
#          puts @time
#          puts @temperature_indoor
#          puts @humidity_indoor
#          puts @temperature_outdoor
#          puts @humidity_outdoor
#       end

   end   
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------

end # class


# end # module
