#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #AUX_Parser_IGS_Broadcast_Ephemeris class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component
# 
# Git: $Id: AUX_Parser_IGS_Broadcast_Ephemeris.rb,v 1.21 2013/03/14 13:40:57 bolf Exp $
#
# Module AUX management
# 
#
#########################################################################

### https://cddis.nasa.gov/Data_and_Derived_Products/GNSS/broadcast_ephemeris_data.html

### AUX_NAV_AX

### All variables in GPS time scale

## brdc0010.20g  Glonass (Daily)

## Hourly GPS Broadcast Ephemeris Files
## brdc0010.20n  IGS

## brdcdddf.yyn.Z
## where
## > ddd: day of year of the GPS end time of the period covered by the file
## > f: hour letter of the GPS end time of the period covered by the file
## > yy: 2-digit year of the GPS end time of the period covered by the file

## S3__GN_1_NAV_AX_20130605T000000_20130605T234500_20130606T030000___________________EGP_O_NR_POD.SEN3

### RINEX format

module AUX

class AUX_Parser_IGS_Broadcast_Ephemeris

   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, logger = nil, isDebug = false)
      if isDebug == true then
         setDebugMode
      end

      @full_path  = full_path
      @filename   = File.basename(full_path)

      checkModuleIntegrity

   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   ## -------------------------------------------------------------
   

private

   @listFiles = nil
   @mailer    = nil

   ## -----------------------------------------------------------
   
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      puts @full_path
      puts @filename
      return
   end
   ## -----------------------------------------------------------

      
end # class

end # module

