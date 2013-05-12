#!/usr/bin/env ruby

# === Written by Casale-Beach

require 'dbm/DatabaseModel'
require 'ddc/DDC_Migrations'

puts "START"

if Interface.table_exists?() == false then
   CreateInterfaces.up
end

if SentFile.table_exists?() == false then
   CreateSentFiles.up
end

puts "END"
