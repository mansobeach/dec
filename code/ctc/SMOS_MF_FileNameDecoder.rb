#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #SMOS_MF_FileNameDecoder class         
#
# === Written by DEIMOS Space S.L.
#
# === Data Collection Component
# 
# CVS: $Id: SMOS_MF_FileNameDecoder.rb,v 1.2 2006/10/19 13:07:53 decdev Exp $
#
#- This class is used for reading the system filename.
#- It decodes the UNIX/Linux Filename following the
#- Earth Explorer filename conventions
#- This class is a specialization made for the SMOS MF Reports files
#
#########################################################################
 

module CTC
 
class SMOS_MF_FileNameDecoder

   attr_reader :fileType, :fileClass, :fileVersion, :startValidity, :stopValidity,
               :fileContent, :dateStart, :dateStop

   #-------------------------------------------------------------
   
   # Class constructor
   # - file (IN): File to be read
   def initialize(file, debugMode = false)
      @isDebugMode  = debugMode
      checkModuleIntegrity
      @filename     = File::basename(file)
      resetMembers
      decodeFileName
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode  = true
      puts "SMOS_MF_FileNameDecoder debug mode is on"
   end
   #-------------------------------------------------------------

   #-------------------------------------------------------------
   
   # This Method returns true if the filename is a Valid one
   # filename, otherwise it returns false
   def isValidFile?
      if @filename.slice(0, 7) != "SM_MREP" then
         return false
      end
      return true
   end
   #-------------------------------------------------------------
   
   # Pass one different filename to be processed
   # - file (IN): File name
   def setFile(file)
      @filename = file
      decodeFileName
   end
   #-------------------------------------------------------------
   

   #-------------------------------------------------------------
   
private
   @isDebugMode        = false
   @filename           = nil
   
   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true   
   end
   #-------------------------------------------------------------

   # SM_MREP_RRRRRRRRRR.YYYYMMDD.YYYYMMDDTHHMMSS_YYYYMMDDTHHMMSS.[D|W|M].zip
   # Decode all posible header fields from unix filename.
   # - fullname (IN): file path name
   def decodeFileName
      @fileType      = @filename.slice(8,10)
      
      if @isDebugMode == true
         puts "Decoding #{filename} :"
         puts "File Type      : #{@fileType} "
         puts "File Class     : #{@fileClass} "
         puts "File Version   : #{@fileVersion} "
         puts "Validity Start : #{@startValidity} "
         puts "Validity Stop  : #{@stopValidity} "
         puts
      end
   end
   #-------------------------------------------------------------   
   
   # Put all members with empty string
   def resetMembers
      @fileType      = ""
      @fileClass     = ""
      @fileVersion   = ""
      @startValidity = ""
      @stopValidity  = ""
      @fileContent   = ""
      @dateStart     = Time.utc("1999")
      @dateStop      = Time.utc("1999")
   end
   #-------------------------------------------------------------

end # class

end # module
