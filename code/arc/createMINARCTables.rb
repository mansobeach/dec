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

require 'arc/MINARC_DatabaseModel'
require 'arc/MINARC_Migrations'

puts "START"

if ArchivedFile.table_exists?() == false then
   CreateArchivedFiles.up
end
