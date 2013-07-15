#!/usr/bin/env ruby

require "ws23rb/CharterFromWSExcelFile"

# parser = WS23RB::CharterFromWSExcelFile.new("/Users/borja/Projects/dec/code/ws23rb/test/test.xls",true)

parser = WS23RB::CharterFromWSExcelFile.new("/Users/borja/Projects/dec/code/ws23rb/test/accumulated_meteo_data.xls",true)

parser.generateCharts

