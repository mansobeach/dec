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

require 'date'

require 'aux/AUX_Handler_Generic'

module AUX

AUX_Pattern_IGS_Broadcast_Ephemeris = "brdc0???.??n"

class AUX_Handler_IGS_Broadcast_Ephemeris < AUX_Handler_Generic

   ## -------------------------------------------------------------
   
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir, isDebug = false)
      # puts "AUX_Handler_IGS_Broadcast_Ephemeris::initialize"
      @target = target
      super(full_path, dir, isDebug)
      
      @strValidityStart    = ""
      @strValidityStop     = ""
      
      if target.upcase == "S3" then
         @mission    = "S3_"
         @fileType = "GN_1_NAV_AX"
      end
      
      if target.upcase == "POD" then
         @mission    = "POD"
         @fileType = "AUX_NAV_AX"
      end

      @instanceID = "____________________EGP_O_NR_POD"
      @extension  = "SEN3"
   end      
   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   ## -------------------------------------------------------------
   
   def rename
      @strCreationDate  = self.getCreationDate
      @newName          = "#{@mission}_#{@fileType}_#{@strValidityStart}_#{@strValidityStop}_#{@strCreationDate}_#{@instanceID}.#{@extension}"
      super(@newName)
      return @full_path_new
   end
   ## -------------------------------------------------------------

   def convert
      @strCreation = self.getCreationDate 
      parse
      return rename
   end
   ## -------------------------------------------------------------
   

private

   ## -----------------------------------------------------------
   
   ## -----------------------------------------------------------

   def parse
      filename          = File.basename(@full_path)
      doy               = filename.slice(4,3)
      year              = "20#{filename.slice(9,2)}"
      day               = Date.strptime("#{year}-#{doy}", '%Y-%j').strftime('%Y%m%d')
      @strValidityStart = "#{day}T000000"
      @strValidityStop  = "#{day}T000000"
   end
   ## -----------------------------------------------------------
      
end # class

end # module

