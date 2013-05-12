#!/usr/bin/env ruby



require 'ws23rb/ReadWSXMLFile'

parser = ReadWSXMLFile.new("#{Dir.pwd}/METEO_CASALE.xml", false)

ret = parser.listOfMeteoVariables

puts ret

exit
# 
# exit
# 
# puts parser.date
# puts parser.time
# puts parser.outdoorTemp
# puts parser.outdoorHumidity
# 
