#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to reverse FOS OBSM NUC File
# into engineering coefficients

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
# == Copyleft
# ESA (Casale & Beach)


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
require 'writeexcel'

# ------------------------------------------------------------------------------
#
# FOM-MSI Issue 5.0
#
# FS-MSI-96 (Long Table)
#
# FS-MSI-97 (Short Table)
#
# FS-MSI-98 (For the complete NUC table transfer verification, 
#            a dedicated EEPROM check sum test can be commanded)
#
# This option allows to cumulate the checksum calculation results of each 156 sub-tables
#
# FS-MSI-54 allows to load a new NUC without without verification or
#            without correction after triggered error
# ------------------------------------------------------------------------------

# Detector & Band ordering is driven by
# [S2GICD-MSI] Issue 8.0  
# Table 3.4-2: Detector Number Coding / page 349 [FOM-MSI]:
#
#  Detector | VCM (1bit)| WICOM Id (2bits) | Detector(1bit) - odd / even -
#  12       |     0     |     00        |  0
#  11       |     0     |     00        |  1
#  10       |     0     |     01        |  0
#  09       |     0     |     01        |  1
#  08       |     0     |     10        |  0
#  07       |     0     |     10        |  1
#  06       |     1     |     00        |  0
#  05       |     1     |     00        |  1
#  04       |     1     |     01        |  0
#  03       |     1     |     01        |  1
#  02       |     1     |     10        |  0
#  01       |     1     |     10        |  1
#

@arrDetectors = [12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]

@arrBands     = ["01", "02", "03", "04", "05", "06", "07", "08", "8A", "09", "10", "11", "12"]

@NUM_DETECTORS = 12
@NUM_BANDS     = 13

# ------------------------------------------------------------------------------

# Coefficients order
# 
# A1, ZS, A2, C

# ------------------------------------------------------------------------------

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
@LAST_WORD_CKSUM        = "0005"
@LAST_NUC_ADDR          = 1052507

# ------------------------------------------------------------------------------


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

   parseNUCFile

#    puts @cksum_nuc 
#    puts @iTotalLength

   createOutputDir

   @iSubTable = 0

   createReversedNUC


   Dir.chdir(@prevDir)
   exit(0)

end


#---------------------------------------------------------------------

def init
   
   @confDir    = File.dirname(__FILE__)
   @nucMapFile = "#{@confDir}/NUC_RAM_MAP.xls"
      
   # ---------------------------------------------
   # Read detector and bands mapping offset
    
   @book                = Spreadsheet.open(@nucMapFile, 'r')
   @sheet               = @book.worksheet 0
  
   # ---------------------------------------------
  
   bFirst             = true
   @iSubTable         = 0
   @counterST         = 0

   @hSubTables       = Hash.new
   @hSubTableAddr    = Hash.new

   @arrChksmComputed    = Array.new
   @arrChksmParsed      = Array.new

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

            @hSubTableAddr[@iSubTable] = arrAddr

#             if @isDebugMode == true then
#                puts "#{@iSubTable} - #{valBase} - #{valLength}"
#             end
            
            @iSubTable = @iSubTable + 1
         }
         
   @iSubTable         = -1
   
end

#-------------------------------------------------------------


#-------------------------------------------------------------

def parseNUCFile

   @nucFile = File.open(@filename, "r")

   if @isDebugMode == true then
      puts "Processing #{@filename}"
      puts
   end

   @iCurrentSubTable = 0
   @iCurrentDataLine = 0
   @iTotalLength     = 0
   @cksum_nuc        = "0000"
   @iCurrentWord     = 0
   @iCounter         = 0
      
   initSubTable

   # -------------------------------------------------------
   File.readlines(@filename).each do |line|
      processLine(line)
   end
   # -------------------------------------------------------
  
   # Comeplete NUC computation  

   @cksum_nuc = (@cksum_nuc.hex ^ @LAST_WORD_CKSUM.hex).to_s(16)
  
   if @isDebugMode == true then
      puts "OBSM CHECKSUM=#{@cksum_nuc}"
   end  
  
end

#-------------------------------------------------------------

def initSubTable

   # puts "New Subtable #{@iCurrentSubTable}"
   
   @isEndSubTable                   = false
   @iCurrentPixel                   = 0
   @iSTLength                       = 0
   @iCounter                        = 0
   @iCurrentStart                   = @hSubTableAddr[@iCurrentSubTable][0]
   @iCurrentSubTableLength          = @hSubTableAddr[@iCurrentSubTable][1]
   @hSubTables[@iCurrentSubTable]   = Array.new
   
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
   
#    if @iSubTable == 0 then
#       exit
#    end   
   
   if @isDebugMode == true then
      puts "==============================================="
      puts "SubTable #{@iCurrentSubTable} - #{@iCurrentSubTableLength}"
      puts
   end 
   @iSubTable = @iSubTable + 1
   
   
end

#-------------------------------------------------------------

def processLine(line)
   arr = line.split("=")
  
   if @arrHeaderFields.include?(arr[0]) == true then
      if @isDebugMode == true then
         puts "Field #{arr[0]} is equal to #{arr[1]}"
      end
      # verifyHeaderValue(arr[0], arr[1].chop)
   else
      processDataLine(line)
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
         
   @iCurrentDataLine = @iCurrentDataLine + 1
   
   if @isEndSubTable == true then
      if @iCurrentSubTable == @LAST_SUBTABLE then
         return
      end
      # exit
      @iCurrentSubTable = @iCurrentSubTable + 1
      initSubTable
   end
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
   @iSTLength  = @iSTLength + val.hex
   @iTotalLength     = @iTotalLength + val.hex
#   puts @iTotalLength.to_s(16)
   
   if @iSTLength == @iCurrentSubTableLength then
      @isEndSubTable = true
   end
   
end
#-------------------------------------------------------------

# Decode OBSM NUC data field
def decodeFieldData(field)
   arrData = Array.new
   # arr = field.split("=")[1].split(/^[A-Z0-9]{4}$/)
   arr = field.split("=")[1].split(/(....)/)
   arr.each{|element|
      if element.length == 0 or element.chop == "" then
         next
      end
      if element.to_s.length != @NUM_NIBBLE then
         puts element.length
         puts element
         puts "Error decodeFieldData ! :-("
         exit
         next
      end
      arrData << element
   }
      
   arrData.each{|word|
   
      if @iCounter == @iCurrentSubTableLength -1 then
         if @isDebugMode == true then
            puts "#{@iCurrentWord} => #{@iCurrentWord.to_s(16)} => #{@iCounter} => #{word} / CHKSUM => #{word}"
         end

         @cksum_nuc = (@cksum_nuc.hex ^ @LAST_WORD_CKSUM.hex).to_s(16)

         if @cksum_nuc != word then
            puts "Wrong chksum ST #{@iSubTable} - \
D#{@arrDetectors[@iSubTable/@NUM_BANDS]}B#{@arrBands[@iSubTable%@NUM_BANDS]} / got #{word} - expected #{@cksum_nuc}"
         end

         @arrChksmParsed      << word
         @arrChksmComputed    << @cksum_nuc
         
         @cksum_nuc = "0000"         
         next
      end

      @cksum_nuc     = (@cksum_nuc.hex ^ word.hex).to_s(16)
      
      if @isDebugMode == true then
         puts "#{@iCurrentWord} => #{@iCurrentWord.to_s(16)} => #{@iCounter} => #{word} / CHKSUM => #{@cksum_nuc}"
      end
      # puts @cksum_nuc
      @hSubTables[@iCurrentSubTable] << word
      @iCounter      = @iCounter + 1
      @iCurrentWord  = @iCurrentWord + 1
            
   }
   # puts arrData.length
end
#-------------------------------------------------------------

def createNewExcel(iST)
   @workbook   = WriteExcel.new("nuc_reversed_#{iST}.xls")
   @worksheet  = @workbook.add_worksheet
   return 
end
#-------------------------------------------------------------

def createOutputDir
   now            = Time.now.strftime("%Y%m%dT%H%M%S") 
   @dirReversed   = "#{now}_nuc_reversed"
   cmd            = "mkdir -p #{@dirReversed}"
   system(cmd)
   @prevDir       = Dir.pwd
   Dir.chdir(@dirReversed)
end
#---------------------------------------------------------------------

def createReversedNUC
   (0..155).each do |i|
      processNUCFile(i)
   end
end

#---------------------------------------------------------------------

def processNUCFile(iST)

   length = @hSubTableAddr[0][1] - 2
   length = @hSubTables[iST].length - 1
   
   puts length
      
   arrA1 = Array.new
   arrZS = Array.new
   arrA2 = Array.new
   arrC  = Array.new
   
   idx = 0
   
   (0..length/16).each do |i|
   
      (1..4).each do |j|
          arrA1 << @hSubTables[0][idx]
          idx = idx + 1
      end
      
      (1..4).each do |j|
          arrZS << @hSubTables[0][idx]
          idx = idx + 1 
      end

      (1..4).each do |j|
          arrA2 << @hSubTables[0][idx]
          idx = idx + 1 
      end

      (1..4).each do |j|
          arrC << @hSubTables[0][idx]
          idx = idx + 1 
      end

   end

   createNewExcel(iST)

   row = 0
   arrA1.each{|value|
      puts "A1 - pixel #{row+1} - #{value}"
      @worksheet.write(row, 0, value)
      row = row + 1
   }
  
   row = 0
   arrZS.each{|value|
      puts "ZS - pixel #{row+1} - #{value}"
      @worksheet.write(row, 1, value)
      row      = row + 1
   }

   row = 0
   arrA2.each{|value|
      puts "A2 - pixel #{row+1} - #{value}"
      @worksheet.write(row, 2, value)
      row      = row + 1
   }

   row = 0
   arrC.each{|value|
      puts "C - pixel #{row+1} - #{value}"
      @worksheet.write(row, 3, value)
      row      = row + 1
   }

   @workbook.close
  
end

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

