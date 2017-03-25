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


module E2E

   Struct.new("Event", :library, :gauge_name, :system, :start, :stop, :value, :explicit_reference, :values)
   
   Struct.new("Explicit_Reference", :explicit_reference, :annotation, :value)

end
