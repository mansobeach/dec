#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to reverse FOS OBSM NUC File
# into engineering coefficients

# == Usage
#  reverseOBSM_NUC.rb  -f <nuc_file> --Subtable <st> [-P]
#     --Parse               it parses only input OBSM NUC file
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --Force               force mode
#     --version             shows version number      
# 

# == Author
# Borja Lopez Fernandez
#
# == Copyleft
# ESA / ESRIN


#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === ESA / ESRIN
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
#
# Coefficients order grouped by 4 pixels (cf. [NUC-US-TN] GS2.TN.ASD.SY.00046 issue 3)
# 
# A1, ZS, A2, C
#
# Parameters A1 and A2: are coded on 16 bits : 6 bits integer part et 10 bits decimal part
#
# Parameters C and Zs: are coded on 16 bits : 12 bits integer part et 4 bits decimal part 
#
# MSB is on the left_side : Big-Endian (source is [FOS-SCOSOBSM-NUC] issue 2.2)
#
# Refer to RID to FOM-MSI below for "official" feedback by ASF
# https://eop.esa.int/pls/rid/ridRidDetail.RidDetailReport?cProjectid=16&cReview=S2_FOM_ISS_1.2&nRidID=93589&cCommand=View
#
# C   is Dark Signal
# ZS  is the abscise of the break point of the bilinear model after Dark Signal correction
# ZS  must be always positive 
#
# At VCU delivery, the memory contains parameters allowing a NEUTRAL CORRECTION for each pixel
# (a1 = a2 = 1, C = Zs =0).
#
# Y = 0                    / if X < C  / C is DARK SIGNAL
# Y = A1*(X-C)             / if C <= X <= (C + ZS)
# Y = A2(X-C-ZS) + A1*ZS   / if X > (C + ZS)
#
# ------------------------------------------------------------------------------
#
#=> Examples:
#     
#     1.002 for A1 or A2
#     Step 1: 1.002 * 1024 = 1026.048
#     Step 2: 1026 (dec) = 0000010000000010 (binary)
#     Step 3: 0000010000000010 (binary) = 0402 (hex)
#     
#     1.2 for A1 or A2:
#     Step 1: 1.2 * 1024 = 1228.8
#     Step 2: 1229 (dec) = 0000010011001101 (bin)
#     Step 3: 0000010011001101 (bin) = 04CD (hex)
# 
#     466.179 for C and Zs
#     Step 1: 466.179 * 16 = 7458.864
#     Step 2: 7459 (dec) = 0001110100100011 (bin)
#     Step 3: 0001110100100011 (bin) = 1D23 (hex)
# 
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
   @reqST         = nil
   @isParseOnly   = false

   opts = GetoptLong.new(
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT],
     ["--Parse", "-P",           GetoptLong::NO_ARGUMENT],
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
     ["--SubTable", "-S",        GetoptLong::REQUIRED_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt
            when "--file"     then @filename    = arg.to_s.upcase
            when "--SubTable" then @reqST       = arg.to_i           
            when "--Debug"    then @isDebugMode = true
            when "--Parse"    then @isParseOnly = true
            when "--Force"    then @isForceMode = true
            when "--version"  then
               print("\nESA - ESRIN ", File.basename($0), " $Revision: 1.0 \n\n\n")
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

   createOutputDir

   @iSubTable = 0

   if @isParseOnly  == false then
      createReversedNUC
   end

   Dir.chdir(@prevDir)
   exit(0)

end

#---------------------------------------------------------------------

def init
   
   @confDir       = File.dirname(__FILE__)
   @nucMapFile    = "#{@confDir}/NUC_RAM_MAP.xls" 
   @targetDirName = "#{@filename.split("_")[8]}_REVERSED_NUC"
         
   # ---------------------------------------------
   # Read detector and bands mapping offset
    
   @book                = Spreadsheet.open(@nucMapFile, 'r')
   @sheet               = @book.worksheet 0
   # ---------------------------------------------
     
   bFirst               = true
   @iSubTable           = 0
   @counterST           = 0
   @hSubTables          = Hash.new
   @hSubTableAddr       = Hash.new
   @arrSTName           = Array.new
   @arrChksmComputed    = Array.new
   @arrChksmParsed      = Array.new

   # ---------------------------------------------

   12.downto(1){|detector| 
      @arrBands.each do |band|
         @arrSTName << "D#{detector.to_s.rjust(2,'0')}B#{band}"
      end
   }

   # ---------------------------------------------

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
   # Initialise again to start with ST index 0      
   @iSubTable = -1   
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
   @iTotalLength     = 0
   @cksum_nuc        = "0000"
   @iCurrentWord     = 0
   @iCounter         = 0
      
   initSubTable

   # -------------------------------------------------------
   File.readlines(@filename).each do |line|
      ret = processLine(line)
      if ret == false then
         return
      end
   end
   # -------------------------------------------------------
  
   # Complete NUC computation  

   @cksum_nuc = (@cksum_nuc.hex ^ @LAST_WORD_CKSUM.hex).to_s(16)
  
   if @isDebugMode == true then
      puts "OBSM CHECKSUM=#{@cksum_nuc}"
   end  
  
end

#-------------------------------------------------------------

def initSubTable

#    if @isDebugMode == true then
#       puts "New Subtable #{@iCurrentSubTable}"
#    end

   @isEndSubTable                   = false
   @getNextStart                    = true
   @iCurrentPixel                   = 0
   @iSTLength                       = 0
   @iSTRealLength                   = 0
   @iCounter                        = 0
   @iCurrentStart                   = @hSubTableAddr[@iCurrentSubTable][0].to_i.to_s(16).hex
   @iCurrentSubTableLength          = @hSubTableAddr[@iCurrentSubTable][1]
   @hSubTables[@iCurrentSubTable]   = Array.new
   
   # ---------------------------------------------
   # Check subtable length short / long 
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
   # ---------------------------------------------
      
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
      return processDataLine(line)
   end
   return true
end

#-------------------------------------------------------------

def processDataLine(line)
   fields = line.split(",")
   
   decodeFieldStart(fields[0])
   decodeFieldCount(fields[1])
   decodeFieldData(fields[2])
   
   if @isEndSubTable == true then
      if @iCurrentSubTable == @LAST_SUBTABLE then
         return # false
      end
      @iCurrentSubTable = @iCurrentSubTable + 1
      if @reqST != nil and @reqST < @iCurrentSubTable then
         return false
      end
      initSubTable
   end
   return true
end
#-------------------------------------------------------------

def decodeFieldStart(field)
   val = field.split("=")[1].to_s.hex
   
   if @getNextStart == true then
      if @iCurrentStart != val then
         puts "Wrong start address ST #{@iSubTable} - #{val} should be #{@iCurrentStart}"
      else
         if @isDebugMode == true then
            puts "ST #{@iSubTable} - \
D#{@arrDetectors[@iSubTable/@NUM_BANDS]}B#{@arrBands[@iSubTable%@NUM_BANDS]} CORRECT START address - #{val}"
         end
      end
      @getNextStart = false
   end
   return val
end
#-------------------------------------------------------------

def decodeFieldCount(field)
   val = field.split("=")[1]
   @iSTLength        = @iSTLength      + val.hex
   @iTotalLength     = @iTotalLength   + val.hex

   if @iSTLength == @iCurrentSubTableLength then
#      puts "NEW TABLE DETECTED !!!!!!!!!!!!!!!"
#      puts @iCurrentSubTableLength
#      puts @iSTLength
#      puts @iSTRealLength
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
      if element.length == 0 or element == nil or element.chop == '' then
         next
      end
      
      if element.to_s.length != @NUM_NIBBLE then
         puts "ERROR decodeFieldData is not Nibble = > #{element} / #{element.length} ! :-("
         exit
      end
      arrData << element
   }
      
   arrData.each{|word|
   
      @iSTRealLength = @iSTRealLength + 1
   
      if @iCounter == @iCurrentSubTableLength -1 then
         if @isDebugMode == true and (@reqST == @iSubTable) then
            puts "#{@iCurrentWord} => #{@iCurrentWord.to_s(16)} => #{@iCounter} => #{word} / CHKSUM => #{word}"
         end

         @cksum_nuc = (@cksum_nuc.hex ^ @LAST_WORD_CKSUM.hex).to_s(16).upcase.rjust(4, '0')

         if @cksum_nuc != word then
            puts "Wrong chksum ST #{@iSubTable} - \
D#{@arrDetectors[@iSubTable/@NUM_BANDS]}B#{@arrBands[@iSubTable%@NUM_BANDS]} / got #{word} - expected #{@cksum_nuc}"
         else
            if @isDebugMode == true then
               puts "ST #{@iSubTable} - \
D#{@arrDetectors[@iSubTable/@NUM_BANDS]}B#{@arrBands[@iSubTable%@NUM_BANDS]} CORRECT CHKSUM - #{word}"
            end
         end

         @arrChksmParsed      << word
         @arrChksmComputed    << @cksum_nuc
         
         @cksum_nuc = "0000"         
         next
      end

      @cksum_nuc     = (@cksum_nuc.hex ^ word.hex).to_s(16).upcase.rjust(4, '0')
#       puts @cksum_nuc
#       exit
      
      if @isDebugMode == true and (@reqST == @iSubTable) then
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
   @workbook   = WriteExcel.new("nuc_reversed_#{iST.to_s.rjust(3, '0')}_#{@arrSTName[iST]}.xls")
   @worksheet  = @workbook.add_worksheet
   @worksheet.freeze_panes(1, 0)
   format      = @workbook.add_format
   format.set_bold
   @worksheet.write(0, 0, "Pixel", format)
   
   @worksheet.write(0, 1, "A1 (Hex)", format)
   @worksheet.write(0, 2, "ZS (Hex)", format)
   @worksheet.write(0, 3, "A2 (Hex)", format)
   @worksheet.write(0, 4, "C  (Hex)", format)

   @worksheet.write(0, 1+4+0,   "A1 (Eng)", format)
   @worksheet.write(0, 1+4+1,   "ZS (Eng)", format)
   @worksheet.write(0, 1+4+2,   "A2 (Eng)", format)   
   @worksheet.write(0, 1+4+3,   "C  (Eng)", format)
   
   return 
end
#-------------------------------------------------------------

def createOutputDir
   cmd            = "rm -rf #{@targetDirName}"
   system(cmd)
   cmd            = "mkdir -p #{@targetDirName}"
   system(cmd)
   @prevDir       = Dir.pwd
   Dir.chdir(@targetDirName)
end
#---------------------------------------------------------------------

def createReversedNUC
   (0..155).each do |i|
      puts "reversing OBSM NUC Sub-Table #{i.to_s.rjust(3, '0')} / #{@arrSTName[i]}"
      processNUCFile(i)
   end
end

#---------------------------------------------------------------------

def processNUCFile(iST)

   length = @hSubTables[iST].length - 1
      
   arrA1 = Array.new
   arrZS = Array.new
   arrA2 = Array.new
   arrC  = Array.new
   
   idx   = 0
   
   (0..length/16).each do |i|
      (1..4).each do |j|
          arrA1 << @hSubTables[iST][idx]
          idx = idx + 1
      end
      
      (1..4).each do |j|
          arrZS << @hSubTables[iST][idx]
          idx = idx + 1
      end

      (1..4).each do |j|
          arrA2 << @hSubTables[iST][idx]
          idx = idx + 1 
      end

      (1..4).each do |j|
          arrC << @hSubTables[iST][idx]
          idx = idx + 1
      end
   end

   # ---------------------------------------------
   # Create new Excel for each SubTable
   createNewExcel(iST)
   # ---------------------------------------------
  
   row = 1
   
   arrA1.each{|value|
      if value == nil then
         next
      end
      binValue       = value.to_i(16).to_s(2).rjust(16, '0')
      binValueInt    = binValue.slice(0,6)
      binValueFrac   = binValue.slice(6,16)
      fValue         = "#{binValueInt.to_i(2)}.#{binValueFrac.to_i(2)}".to_f
      fValue         = convertHex2Eng_A(value)
      if iST == @reqST or @reqST == nil and @isDebugMode == true then
         puts "A1 - pixel #{row+1} - #{value} - #{fValue}"
      end
      @worksheet.write(row, 0, row)
      @worksheet.write(row, 1, value)
      @worksheet.write(row, 1+4,fValue)
#      @worksheet.write(row, 1+4, "=MID(B#{row+1},1,1)")
      row = row + 1
   }
  
   row = 1
   arrZS.each{|value|
      if value == nil then
         next
      end
      binValue = value.to_i(16).to_s(2).rjust(16, '0')
      binValueInt    = binValue.slice(0,12)
      binValueFrac   = binValue.slice(12,16)
      fValue         = "#{binValueInt.to_i(2)}.#{binValueFrac.to_i(2)}".to_f
      fValue         = convertHex2Eng_C(value)
      if iST == @reqST or @reqST == nil and @isDebugMode == true then
         puts "ZS - pixel #{row+1} - #{value} - #{fValue}"
      end
      @worksheet.write(row, 2, value)
      @worksheet.write(row, 2+4,fValue)
      row = row + 1
   }

   row = 1
   arrA2.each{|value|
      if value == nil then
         next
      end
      binValue       = value.to_i(16).to_s(2).rjust(16, '0')
      binValueInt    = binValue.slice(0,6)
      binValueFrac   = binValue.slice(6,16)
      fValue         = "#{binValueInt.to_i(2)}.#{binValueFrac.to_i(2)}".to_f
      fValue         = convertHex2Eng_A(value)
      if iST == @reqST or @reqST == nil and @isDebugMode == true then
         puts "A2 - pixel #{row+1} - #{value} - #{fValue}"
      end
      @worksheet.write(row, 3, value)
      @worksheet.write(row, 3+4,fValue)
#      @worksheet.write(row, 1+4, "=MID(B#{row+1},1,1)")
      row = row + 1
   }

   row = 1
   arrC.each{|value|
      if value == nil then
         next
      end
      binValue = value.to_i(16).to_s(2).rjust(16, '0')
      binValueInt    = binValue.slice(0,12)
      binValueFrac   = binValue.slice(12,16)
      fValue         = "#{binValueInt.to_i(2)}.#{binValueFrac.to_i(2)}".to_f
      fValue         = convertHex2Eng_C(value)
      if iST == @reqST or @reqST == nil and @isDebugMode == true then
         puts "C  - pixel #{row+1} - #{value} - #{fValue}"
      end
      @worksheet.write(row, 4, value)
      @worksheet.write(row, 4+4,fValue)
      row = row + 1
   }

   @workbook.close
  
   if iST == @reqST then
      exit
   end  
end


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

def convertHex2Eng_A(value)
   kk = value.to_i(10)/(1024.0).to_f
   return kk.round(3)
end
#-------------------------------------------------------------

def convertHex2Eng_C(value)
   kk = value.to_i(10)/(16.0).to_f
   return kk.round(3)
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

