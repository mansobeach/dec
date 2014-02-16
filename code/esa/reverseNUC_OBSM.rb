#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to generate the daily meteo files

# == Usage
#  reverseNUC.rb  -f <nuc_file>
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --Force               force mode
#     --version             shows version number      
# 

# == Author
# Borja Lopez Fernandez
#
# == Copyright
# Casale Beach


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
require 'getoptlong'
require 'spreadsheet'

@arrHeaderFields = ["DOMAIN", "ID", "VERSION", "TYPE", "DESCRIPTION",
      "CREATIONDATE", "DEVICE", "STARTADDR", "ENDADDR", "LENGTH", "CHECKSUM", "UNIT"]

@COLUMN_BASE            = 0
@COLUMN_LENGTH          = 1
@NUM_NIBBLE             = 4

@NUM_PIXEL_SHORT        = 1296
@NUM_PIXEL_LONG         = 2592

@LENGTH_SUBTABLE_SHORT  = 5185
@LENGTH_SUBTABLE_LONG   = 10369

@LAST_SUBTABLE          = 155

# MAIN script function
def main

   @locker        = nil
   @filename      = nil
   @isDebugMode   = false
   @isForceMode   = false

   opts = GetoptLong.new(
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT],
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt
            when "--file"     then @filename    = arg.to_s.upcase          
            when "--Debug"    then @isDebugMode = true
            when "--Force"    then @isForceMode = true
            when "--version"  then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--usage"   then usage
            when "--help"    then usage                        
         end
      end
   rescue Exception
      exit(99)
   end

   if @filename == nil then
      usage
   end

   init

   @nucFile = File.open(@filename, "r")

   if @isDebugMode == true then
      puts "Processing #{@filename}"
      puts
   end

   processNUC

   exit(0)

end
#---------------------------------------------------------------------

def init
   
   @confDir    = File.dirname(__FILE__)
   @nucMapFile = "#{@confDir}/NUC_RAM_MAP.xls"
   
   @book                = Spreadsheet.open(@nucMapFile, 'r')
   @sheet               = @book.worksheet 0

   bFirst            = true
   iSubTable         = 0
   @currentISubTable = 0

   @hSubTableAddr = Hash.new

   @sheet.each{|row|  
            if bFirst == true then
               bFirst = false
               next
            end

            valBase     = row[@COLUMN_BASE].to_i
            valLength   = row[@COLUMN_LENGTH].to_i

            arrAddr     = Array.new
            arrAddr[0]  = valBase
            arrAddr[1]  = valLength

            @hSubTableAddr[iSubTable] = arrAddr

#             if @isDebugMode == true then
#                puts "#{iSubTable} - #{valBase} - #{valLength}"
#             end
            
            iSubTable = iSubTable + 1
         }
end

#-------------------------------------------------------------

def initSubTable
   @iCurrentPixel          = 0
   @iSubTableLength        = 0
   @iCurrentStart          = @hSubTableAddr[@iCurrentSubTable][0]
   @iCurrentSubTableLength = @hSubTableAddr[@iCurrentSubTable][1]
   @isStartSubTable  = true
   
   if @hSubTableAddr[@iCurrentSubTable][1] == @LENGTH_SUBTABLE_SHORT then
      @numPixels = @NUM_PIXEL_SHORT
   else
      if @hSubTableAddr[@iCurrentSubTable][1] == @LENGTH_SUBTABLE_LONG then
         @numPixels = @NUM_PIXEL_LONG
      else
         puts "ERROR initSubTable"
         exit(99)
      end
   end
   
   puts "==============================================="
   puts "SubTable #{@iCurrentSubTable} - #{@iCurrentSubTableLength}"
   puts 
   
end
#-------------------------------------------------------------

def processNUC

   @iCurrentSubTable = 0
   @iCurrentDataLine = 0
   @iTotalLength     = 0
   
   initSubTable

   # -------------------------------------------------------
   File.readlines(@filename).each do |line|
      processLine(line)
   end
   # -------------------------------------------------------


end

#-------------------------------------------------------------

def processLine(line)
   arr = line.split("=")
  
   if @arrHeaderFields.include?(arr[0]) == true then
      if @isDebugMode == true then
         puts "Field #{arr[0]} is equal to #{arr[1]}"
      end
      verifyHeaderValue(arr[0], arr[1].chop)
   else
      processDataLine(line)
      
#       if @iCurrentDataLine == 3 then
#          exit
#       end
   end
   
end

#-------------------------------------------------------------

#-------------------------------------------------------------

def verifyHeaderValue(field, value)

   bVerified = false
   
   if field == "DOMAIN" then
      if value != "0" then
         puts "ERROR: DOMAIN=#{value} and should be 0"
      end
   end
   
   if field == "ID" then
      if value != "0" then
         puts "ERROR: ID=#{value} and should be 0"
      end
   end

   if field == "VERSION" then
      if value != "0" then
         puts "ERROR: VERSION=#{value} and should be 0"
      end
   end

   if field == "TYPE" then
      if value != "PATCH" then
         puts "ERROR: TYPE=#{value} and should be PATCH"
      end
   end

   if field == "UNIT" then
      if value != "2" then
         puts "ERROR: UNIT=#{value} and should be 2"
      end
   end
   
end
#-------------------------------------------------------------

def processDataLine(line)
   fields = line.split(",")
   decodeFieldStart(fields[0])
   decodeFieldCount(fields[1])
   decodeFieldData(fields[2])
   
   if @isStartSubTable == true then
      @isStartSubTable == false
   end
   
   @iCurrentDataLine = @iCurrentDataLine + 1
   
end
#-------------------------------------------------------------

def decodeFieldStart(field)
   val = field.split("=")[1]
#    puts val
#    puts val.hex
end
#-------------------------------------------------------------

def decodeFieldCount(field)
#   puts field
   val = field.split("=")[1]
   @iSubTableLength  = @iSubTableLength + val.hex
   @iTotalLength     = @iTotalLength + val.hex
#   puts @iTotalLength.to_s(16)
   
   if @iSubTableLength == @iCurrentSubTableLength then
      puts "END OF TABLE"
      
      if @iCurrentSubTable == @LAST_SUBTABLE then
         exit
      end
      
      @iCurrentSubTable = @iCurrentSubTable + 1
      initSubTable
    #  exit
   end
   
end
#-------------------------------------------------------------

def decodeFieldData(field)
   arrData = Array.new
   arr = field.split("=")[1].split(/^[A-Z0-9]{4}$/)
   arr = field.split("=")[1].split(/(....)/)
   arr.each{|element|
      if element.to_s.length != @NUM_NIBBLE then
         next
      end
      arrData << element
   }
   return arrData
end
#-------------------------------------------------------------


#-------------------------------------------------------------

def usage
   fullpathFile = `which #{File.basename($0)}`
   puts File.basename($0)
   puts fullpathFile
   system("head -21 #{fullpathFile}")
   exit
end

#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================

