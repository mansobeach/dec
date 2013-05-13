#!/usr/bin/env ruby

require "ws23rb/WSExcelFileCreator"
# #require "ws23rb/WSExcelFileVerifier"
# require 'rubygems'
# #require 'spreadsheet'
# 
# puts Dir.pwd

#require 'rubygems'
#require 'writeexcel'
#require 'WriteExcel'



# handler = WS23RB::WSExcelFileVerifier.new("EXCEL_METEO_CASALE_201202bis.xls", "kaki.xls", true)
# 
# hErrors = handler.verify
# 
# handler.createFlaggedExcel



handler = WS23RB::WSExcelFileCreator.new("EXCEL_METEO_CASALE_201202bis.xls", "pedo.xls", true)

handler.createDailySheets

handler.createStatisticSheets



# book                = Spreadsheet.open("EXCEL_METEO_CASALE_201202bis.xls")
# sheet               = book.worksheet 0
# 
#       hErrors.each{|row, column|
#          puts "Error in row #{row+1} column #{column+1}"   
#          sheet[row, column] = "ERROR"
#       }
#       
# book.write("KAKO.xls")

#handler.flagErrors(hErrors)
