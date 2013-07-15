#!/usr/bin/ruby


require 'snmp'  

include SNMP

manager = Manager.new(:Host => 'localhost')
varbind = VarBind.new("1.3.6.1.2.1.1.5.0", OctetString.new("My System Name"))
manager.set(varbind)
manager.close
