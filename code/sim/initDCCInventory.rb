#!/usr/bin/env ruby

#########################################################################
#
# initDCCInventory
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Collector Component
# 
# CVS:
#
#########################################################################

# It deletes all DCC Inventory tables content and the it invokes addInterfaces2Database.rb
# to load the INTERFACES table

require 'dbm/DatabaseModel'


#===============================================================================


def main

   puts "\ninitDCCInventory ..."
   print "\nAll data in DCC Inventory will be DELETED !!!\n"

   res = ""

   while res.chop != "N" and res.chop != "Y"
      print "\nDo you want to continue? [Y/N]\n\n"
      res = STDIN.gets.upcase
   end

   if res.chop == "N" then
      puts "\n\nwise guy !! ;-p \n\n\n"
      exit(0)
   end

   ReceivedFile.delete_all

   TrackedFile.delete_all
   
   Interface.delete_all

   
   # Load INTERFACES with the configuration
   cmd = "addInterfaces2Database.rb -p EXTERNAL"
   system(cmd)
end

#===============================================================================


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
