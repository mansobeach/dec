#!/usr/bin/env ruby

require "ws23rb/NetCDFConvFromWSExcelFile"

parser = WS23RB::NetCDFConvFromWSExcelFile.new("/Users/borja/Projects/dec/code/ws23rb/test/accumulated_meteo_data.xls",
                                             "dewpoint", true)


