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

class WriteWSXMLFile

   include REXML

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename = "", debug = false)
      @filename            = filename
      
      if debug == true then
         setDebugMode
      end
      
      @arrAttrNonReader    = ["filename", "isDebugMode", "arrAttrNonReader"]
      checkModuleIntegrity
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "WriteWSXMLFile debug mode is on"
   end
   #-------------------------------------------------------------
   
   def write(hVariables)
      writeData(hVariables)
      saveFile
   end
   #-------------------------------------------------------------
   
private

   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
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
      
      # ---------------------------------------------
      # check that external commands needed are available
      
      isToolPresent = `which curl`   
      
      if isToolPresent[0,1] != '/' then
         puts "\n\ReadWSXMLFile::checkModuleIntegrity\n"
         puts "Fatal Error: curl tool not present in PATH !!   :-(\n\n\n"
         bDefined = false
      end
      # ---------------------------------------------

      if bCheckOK == false or bDefined == false then
        puts "ReadWSXMLFile::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
      
      @urlService1   = "icanhazip.com"
      cmd            = "curl -s #{@urlService1}"

      if @isDebugMode == true then
         puts cmd
      end

      @publicIP = `#{cmd}`
      
      @publicIP = @publicIP.to_s.chop
      
      if @isDebugMode == true then
         puts @publicIP
      end

   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   # Write the file 

   def writeData(hVariables)
      @xmlFile           = REXML::Document.new
      @xmlFile << XMLDecl.new

      root = @xmlFile.add_element("ws2300")
      root.add_attribute("simplified", "true")
      root.add_attribute("ip", @publicIP)

      theDate = root.add_element("Date")
      theDate.text = Time.now.strftime("%Y-%m-%d")

      theTime = root.add_element("Time")
      theTime.text =  Time.now.strftime("%H:%M:%S") 

      temperature    = root.add_element("Temperature")

      # ------------------------------------------------
      # Temperature Indoor

      temp_indoor    = temperature.add_element("Indoor")
      t_indoor_val   = temp_indoor.add_element("Value")
      
      if hVariables.has_key?("temperature_indoor") == true then
         t_indoor_val.text = hVariables["temperature_indoor"]
      else
         t_indoor_val.text = "N/A"
      end

      # t_indoor_min   = temp_indoor.add_element("Min")
      # t_indoor_min.text = "N/A"
      # 
      # t_indoor_max   = temp_indoor.add_element("Max")
      # t_indoor_max.text = "N/A"
      # 
      # t_indoor_minT   = temp_indoor.add_element("MinTime")
      # t_indoor_minT.text = "N/A"
      # 
      # t_indoor_minD   = temp_indoor.add_element("MinDate")
      # t_indoor_minD.text = "N/A"
      # 
      # t_indoor_maxT   = temp_indoor.add_element("MaxTime")
      # t_indoor_maxT.text = "N/A"
      # 
      # t_indoor_maxD   = temp_indoor.add_element("MaxDate")
      # t_indoor_maxD.text = "N/A"

      # ------------------------------------------------
      # Temperature Outdoor

      temp_outdoor    = temperature.add_element("Outdoor")
      t_outdoor_val   = temp_outdoor.add_element("Value")

      if hVariables.has_key?("temperature_outdoor") == true then
         t_outdoor_val.text = hVariables["temperature_outdoor"]
      else
         t_outdoor_val.text = "N/A"
      end



      # t_outdoor_min   = temp_outdoor.add_element("Min")
      # t_outdoor_min.text = "N/A"
      # 
      # t_outdoor_max   = temp_outdoor.add_element("Max")
      # t_outdoor_max.text = "N/A"
      # 
      # t_outdoor_minT   = temp_outdoor.add_element("MinTime")
      # t_outdoor_minT.text = "N/A"
      # 
      # t_outdoor_minD   = temp_outdoor.add_element("MinDate")
      # t_outdoor_minD.text = "N/A"
      # 
      # t_outdoor_maxT   = temp_outdoor.add_element("MaxTime")
      # t_outdoor_maxT.text = "N/A"
      # 
      # t_outdoor_maxD   = temp_outdoor.add_element("MaxDate")
      # t_outdoor_maxD.text = "N/A"


      humidity    = root.add_element("Humidity")

      # ------------------------------------------------
      # humidity Indoor

      hum_indoor    = humidity.add_element("Indoor")

      h_indoor_val   = hum_indoor.add_element("Value")
      
      if hVariables.has_key?("humidity_indoor") == true then
         h_indoor_val.text = hVariables["humidity_indoor"]
      else
         h_indoor_val.text = "N/A"
      end

      # h_indoor_min   = hum_indoor.add_element("Min")
      # h_indoor_min.text = "N/A"
      # 
      # h_indoor_max   = hum_indoor.add_element("Max")
      # h_indoor_max.text = "N/A"
      # 
      # h_indoor_minT   = hum_indoor.add_element("MinTime")
      # h_indoor_minT.text = "N/A"
      # 
      # h_indoor_minD   = hum_indoor.add_element("MinDate")
      # h_indoor_minD.text = "N/A"
      # 
      # h_indoor_maxT   = hum_indoor.add_element("MaxTime")
      # h_indoor_maxT.text = "N/A"
      # 
      # h_indoor_maxD   = hum_indoor.add_element("MaxDate")
      # h_indoor_maxD.text = "N/A"

      # ------------------------------------------------
      # humidity Outdoor

      hum_outdoor    = humidity.add_element("Outdoor")

      h_outdoor_val   = hum_outdoor.add_element("Value")
      h_outdoor_val.text = "FILL VALUE"

      if hVariables.has_key?("humidity_outdoor") == true then
         h_outdoor_val.text = hVariables["humidity_outdoor"]
      else
         h_outdoor_val.text = "N/A"
      end


      # h_outdoor_min   = hum_outdoor.add_element("Min")
      # h_outdoor_min.text = "N/A"
      # 
      # h_outdoor_max   = hum_outdoor.add_element("Max")
      # h_outdoor_max.text = "N/A"
      # 
      # h_outdoor_minT   = hum_outdoor.add_element("MinTime")
      # h_outdoor_minT.text = "N/A"
      # 
      # h_outdoor_minD   = hum_outdoor.add_element("MinDate")
      # h_outdoor_minD.text = "N/A"
      # 
      # h_outdoor_maxT   = hum_outdoor.add_element("MaxTime")
      # h_outdoor_maxT.text = "N/A"
      # 
      # h_outdoor_maxD   = hum_outdoor.add_element("MaxDate")
      # h_outdoor_maxD.text = "N/A"

      # ------------------------------------------------
      # Dewpoint
      # To be done

      dewpoint    = root.add_element("Dewpoint")
      dew_value   = dewpoint.add_element("Value")

      if hVariables.has_key?("dewpoint") == true then
         dew_value.text = hVariables["dewpoint"]
      else
         dew_value.text = "N/A"
      end


      # ------------------------------------------------
      # Wind

      wind              = root.add_element("Wind")
      w_value           = wind.add_element("Value")

      if hVariables.has_key?("wind_speed") == true then
         w_value.text = hVariables["wind_speed"]
      else
         w_value.text = "N/A"
      end

      w_direction       = wind.add_element("Direction")
      w_dir_text        = w_direction.add_element("Text")

      if hVariables.has_key?("wind_direction") == true then
         w_dir_text.text = hVariables["wind_direction"]
      else
         w_dir_text.text = "N/A"
      end

      w_dir_text        = w_direction.add_element("Dir0")

      if hVariables.has_key?("wind_pointing_degrees") == true then
         w_dir_text.text = hVariables["wind_pointing_degrees"]
      else
         w_dir_text.text = "N/A"
      end


      # ------------------------------------------------
      # Rain

      rain              = root.add_element("Rain")

      rain1h            = rain.add_element("OneHour")
      rain1h_value      = rain1h.add_element("Value")
 
     if hVariables.has_key?("rain_1h") == true then
         rain1h_value.text = hVariables["rain_1h"]
      else
         rain1h_value.text = "N/A"
      end

      rain24h            = rain.add_element("TwentyFourHour")
      rain24h_value      = rain24h.add_element("Value")
      
      if hVariables.has_key?("rain_24h") == true then
         rain24h_value.text = hVariables["rain_24h"]
      else
         rain24h_value.text = "N/A"
      end

      # ------------------------------------------------
      # Pressure

      pressure           = root.add_element("Pressure")
      pressure_value     = pressure.add_element("Value")

      if hVariables.has_key?("rel_pressure") == true then
         pressure_value.text = hVariables["rel_pressure"]
      else
         pressure_value.text = "N/A"
      end

      # ------------------------------------------------
   end   
   #-------------------------------------------------------------
   
   def saveFile
      if @isDebugMode == true then
         puts "Saving file #{@filename}"
         puts
      end
      formatter = REXML::Formatters::Pretty.new
      formatter.compact = true
      File.open(@filename,"w"){|file| file.puts formatter.write(@xmlFile.root,"")}
   end
   #-------------------------------------------------------------

end # class


# end # module
