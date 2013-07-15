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

class WS_PlugIn_Loader

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(variable, debug = false)
      @isDebugMode   = debug
      @variable      = variable
      @plugInKlass   = nil
      @plugInObj     = nil
      checkModuleIntegrity
      loadPlugIn
   end
   #-------------------------------------------------------------
  
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "WS_PlugIn_Loader debug mode is on"
   end
   #-------------------------------------------------------------

   def isPlugInLoaded?
      if @plugInObj != nil then
         return true
      else
         return false
      end
   end
   #-------------------------------------------------------------

   # Variable plug-in methods

   def unit
      return @plugInObj.unit
   end
   #-------------------------------------------------------------
 
   def variable
      return @plugInObj.variable
   end
   #-------------------------------------------------------------

   def thresholds
      return @plugInObj.thresholds
   end
   #-------------------------------------------------------------

   def verifyThresholds(value)
      return @plugInObj.verifyThresholds(value)
   end
   #-------------------------------------------------------------

   def failedThreshold
      return @plugInObj.failedThreshold
   end
   #-------------------------------------------------------------

private

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true

      if bCheckOK == false then
        puts "WS_PlugIn_Loader::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
   end
   #-------------------------------------------------------------

   def loadPlugIn
      plugIn = "ws23rb/WS_PlugIn_#{@variable}"
      begin
         require plugIn
         @plugInKlass   = eval("WS_PlugIn_#{@variable}")
         @plugInObj     = @plugInKlass.new
         if @isDebugMode == true then
#            puts
#            puts "Loaded plug-in WS_PlugIn_#{@variable}"
#            puts
         end
      rescue Exception => e
         if @isDebugMode == true then
#            puts
#            puts "Could not load plug-in for variable #{@variable}"
#            puts e.to_s
         end
      end
   end
   #-------------------------------------------------------------

end # class

end # module

