#!/usr/bin/env ruby

# === Written by Casale-Beach

require 'dbm/DatabaseModel'
require 'dcc/DCC_Migrations'

puts "START"

if Interface.table_exists?() == false then
   CreateInterfaces.up
end

if ReceivedFile.table_exists?() == false then
   CreateReceivedFiles.up
end

if TrackedFile.table_exists?() == false then
   CreateTrackedFiles.up
end


puts "END"
