#!/usr/bin/env ruby

require 'rexml/document'

include REXML

xmlFile           = REXML::Document.new

xmlFile << XMLDecl.new

root = xmlFile.add_element("ws2300")

theDate = root.add_element("Date")
theDate.text = Time.now.strftime("%Y-%m-%d")


theTime = root.add_element("Time")
theTime.text =  Time.now.strftime("%H:%M:%S") 

temperature    = root.add_element("Temperature")

# ------------------------------------------------
# Temperature Indoor

temp_indoor    = temperature.add_element("Indoor")

t_indoor_val   = temp_indoor.add_element("Value")
t_indoor_val.text = "N/A"

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
t_outdoor_val.text = "FILL VALUE"

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
h_indoor_val.text = "FILL VALUE"

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

# ------------------------------------------------
# Wind

wind              = root.add_element("Wind")
w_value           = wind.add_element("Value")
w_value.text      = "FILL VALUE"

w_direction       = wind.add_element("Direction")
w_dir_text        = w_direction.add_element("Text")
w_dir_text.text   = "FILL VALUE"


# ------------------------------------------------
# Rain

rain              = root.add_element("Rain")

rain1h            = rain.add_element("OneHour")
rain1h_value      = rain1h.add_element("Value")
rain1h_value.text = "FILL VALUE"

rain24h            = rain.add_element("TwentyFourHour")
rain24h_value      = rain24h.add_element("Value")
rain24h_value.text = "FILL VALUE"

# ------------------------------------------------
# Pressure

pressure           = root.add_element("Pressure")
pressure_value     = pressure.add_element("Value")
pressure_value.text = "FILL VALUE"

# ------------------------------------------------

formatter = REXML::Formatters::Pretty.new
formatter.compact = true
  
File.open("kk.xml","w"){|file| file.puts formatter.write(xmlFile.root,"")}

# xmlFile.write
