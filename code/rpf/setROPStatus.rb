#!/usr/bin/env ruby


# == Synopsis
#
# This is the setROPStatus command line tool that manually changes the ROP Status.
# To be used only for testing purposes.
# 
#
# == Usage
# setROPStatus.rb   -R <numROP>   -s <STATUS>
#              --ROP       <nROP>
#              --status    STATUS_NEW
#                          STATUS_VALIDATED
#                          STATUS_CONSOLIDATED
#                          STATUS_TRANSFERRED
#                          STATUS_BEING_TRANSFERRED
#              --help      shows this help
#              --usage     shows the usage
#              --Debug     shows Debug info during the execution
#              --version   shows version number
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2006 ESA - Deimos Space S.L.
#


#########################################################################
#
# Ruby script setROPStatus
# 
# Written by DEIMOS Space S.L.   (bolf)
#
# Data Exchange Component -> Mission Management & Planning Facility
# 
# CVS:
#   $Id: setROPStatus.rb,v 1.1 2007/01/09 15:27:30 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'cuc/DirUtils'
require 'dbm/DatabaseModel'

# Global variables
@@dateLastModification = "$Date$"   # to keep control of the last modification
                                       # of this script
@@debugMode       = 0                  # execution showing Debug Info
@@mnemonic        = ""


# MAIN script function
def main
   include           CUC::DirUtils
   
   @@debugMode       = 0 
   @@nROP            = 0
   @@bResult         = false
   @@status  = ""

   
   opts = GetoptLong.new(
     ["--mnemonic", "-m",       GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--ROP", "-R",            GetoptLong::REQUIRED_ARGUMENT],
     ["--status", "-s",         GetoptLong::REQUIRED_ARGUMENT]
     )
    
   
   begin 
      opts.each do |opt, arg|  
         case opt      
            when "--Debug"   then @@debugMode = 1
            when "--version" then
               print("\nESA - DEIMOS-Space S.L.", File.basename($0), " $Revision: 1.1 $  [", @@dateLastModification, "]\n\n\n")
               exit (0)
            when "--mnemonic" then
               @@mnemonic = arg         
            when "--help" then RDoc::usage
            when "--ROP" then
                @@nROP    = arg.to_i
            when "--status" then
                @@status  = arg.to_s                         
         end
      end
   rescue Exception
      exit(99)
   end
 
   if @@status == "" or @@nROP == 0 then
      RDoc::usage("usage")
   end
   
   
   ret = true
   case @@status
      when "STATUS_VALIDATED"         then ret = InventoryROP.setROPStatus(@@nROP, InventoryROP::STATUS_VALIDATED)
      when "STATUS_CONSOLIDATED"      then ret = InventoryROP.setROPStatus(@@nROP, InventoryROP::STATUS_CONSOLIDATED)
      when "STATUS_TRANSFERRED"       then ret = InventoryROP.setROPStatus(@@nROP, InventoryROP::STATUS_TRANSFERRED)
      when "STATUS_BEING_TRANSFERRED" then ret = InventoryROP.setROPStatus(@@nROP, InventoryROP::STATUS_BEING_TRANSFERRED)
      else
         puts "Ilegal --status option : #{@@status}\n\n"
         exit(99)
   end

   if ret == false then
      puts "Could not set Status #{@@status} to ROP #{@@nROP} ! :-(" 
      puts
      exit(99)
   end
   exit(0)
end
#---------------------------------------------------------------------
#---------------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
