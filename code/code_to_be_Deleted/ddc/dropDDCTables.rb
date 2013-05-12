#!/usr/bin/env ruby

# === Written by Casale-Beach

require 'dbm/DatabaseModel'
require 'ddc/DDC_Migrations'

puts "START"

if Interface.table_exists?() == true then
   CreateInterfaces.down
end

if SentFile.table_exists?() == true then
   CreateSentFiles.down
end

puts "END"
