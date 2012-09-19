#!/usr/bin/env ruby

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
require 'ws23rb/WS_PlugIn_Loader'

module WS23RB

class TemperatureCorrection
   # Class constructor
   def initialize(debug = false)
      @isDebugMode         = debug
      checkModuleIntegrity
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "TemperatureCorrection debug mode is on"
   end
   #-------------------------------------------------------------

private

   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true

      if bCheckOK == false then
        puts "TemperatureCorrection::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
   end
   #-------------------------------------------------------------
   

end # class

end # module
