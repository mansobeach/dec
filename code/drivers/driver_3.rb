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

require 'snmp'

ifTable_columns = ["ifIndex", "ifDescr", "ifInOctets", "ifOutOctets"]
SNMP::Manager.open(:Host => 'localhost') do |manager|
  manager.walk(ifTable_columns) do |row|
    row.each { |vb| print "\t#{vb.value}" }
    puts
  end
end
