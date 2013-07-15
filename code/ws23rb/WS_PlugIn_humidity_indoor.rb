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

class WS_PlugIn_humidity_indoor

   attr_reader :failedThreshold, :thresholds, :unit, :variable

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(debug = false)
      @isDebugMode      = debug
      @variable         = "humidity_indoor"
      @unit             = "%"
      @failedThreshold  = ""     

      # ------------------------------------------
      # Edit the following lines to modify the thresholds 
      # applied to the variable humidity_indoor
      @thresholds = Array.new
      @thresholds << " < 100.0"
      @thresholds << " > 0.0"
      # ------------------------------------------
   end
   #-------------------------------------------------------------
  
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "WS_PlugIn_humidity_indoor debug mode is on"
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

