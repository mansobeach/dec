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

  
SNMP::Manager.open(:Host => 'localhost') do |manager|
      response = manager.get(["sysDescr.0", "sysName.0"])
      response.each_varbind do |vb|
          puts "#{vb.name.to_s}  #{vb.value.to_s}  #{vb.value.asn1_type}"
      end
end




