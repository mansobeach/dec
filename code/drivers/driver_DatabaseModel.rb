#!/usr/bin/ruby

#########################################################################
#
# driver_DCC_FileSender
#
# Written by DEIMOS Space S.L. (bolf)
#
# RPF
# 
# CVS:
#
#########################################################################

require 'dbm/DatabaseModel'

# aROP = InventoryROP.new
# 
# aROP.name = "dbm new ROP"
# aROP.rop_id = 1

lock = InventoryParams.find_by_keyword("FILE_TRANSFER_LOCK")

if lock == nil then
   puts "Create LOCK"
else
   # UNLOCK on
   puts "--------------------------"
   puts "LOCK_VALUE"
   puts lock.value
   puts "--------------------------"

   if lock.value == "1" then
      puts "locked"
      InventoryParams.update_all "value = '0'", "keyword = 'FILE_TRANSFER_LOCK'"
   else
      puts "unlocked"
      InventoryParams.update_all "value = '1'", "keyword = 'FILE_TRANSFER_LOCK'"
      # Set Locked
   end


end


exit

lock = InventoryParams.find_by_keyword("FILE_TRANSFER_LOCK")
      

lock = InventoryParams.find_by_keyword("FILE_TRANSFER_LOCK")
      
if lock != nil then
   puts "HEYYY?!?!?!"
end




