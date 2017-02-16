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

require 'minarc/MINARC_DatabaseModel'
require 'minarc/MINARC_Migrations'

puts "START"

if ArchivedFile.table_exists?() == false then
   CreateArchivedFiles.up
end
