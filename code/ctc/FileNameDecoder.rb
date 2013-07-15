#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #FileNameDecoder class         
#
# Written by DEIMOS Space S.L.
#
# Data Collection Component
# 
# CVS:
#  $Id: FileNameDecoder.rb,v 1.2 2006/10/19 13:07:53 decdev Exp $
#
#########################################################################


#- This class is used for reading the system filename.
#- It decodes the UNIX/Linux Filename following the
#- Earth Explorer filename conventions
 
require 'delegate' 
require 'ctc/SMOS_MF_FileNameDecoder'
 
 
module CTC
 
class FileNameDecoder < SimpleDelegator

   #-------------------------------------------------------------
   
   # Class constructor
   # - file (IN): File to be read
   def initialize(file, debugMode = false)
      @isDebugMode  = debugMode
      checkModuleIntegrity
      @filename     = File::basename(file)
      identifyDelegator
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
     @isDebugMode  = true
     puts "DCC_EE_ReadFileName debug mode is on"
   end
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
   
   def identifyDelegator
      obj     = CTC::SMOS_MF_FileNameDecoder.new(@filename)
      if obj.isValidFile? == true then
         __setobj__(obj) 
      end
   end
   #-------------------------------------------------------------   
   
end # class

end # module

