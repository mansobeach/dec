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



module WS23RB

class WS_PlugIn_wind_direction

   attr_reader :failedThreshold, :thresholds, :unit, :variable

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(debug = false)
      @isDebugMode      = debug
      @variable         = "wind_direction"
      @unit             = "degrees [0-359]"
      @failedThreshold  = ""     

      # ------------------------------------------
      # Edit the following lines to modify the thresholds 
      # applied to the variable wind_direction
      @thresholds = Array.new
      # @thresholds << " > 0.0"
      @thresholds << " < 360.1"
      # ------------------------------------------
   end
   #-------------------------------------------------------------
  
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "WS_PlugIn_wind_direction debug mode is on"
   end
   #-------------------------------------------------------------
 
   def verifyThresholds(value)
      ret = true
      @failedThreshold  = ""   
      @thresholds.each{|condition|
         ret = eval("#{value} #{condition}")
         if ret == false then
            @failedThreshold = condition
            return ret
         end
      }
      return ret
   end
   #-------------------------------------------------------------

private

   #-------------------------------------------------------------
   #-------------------------------------------------------------

end # class

end # module

