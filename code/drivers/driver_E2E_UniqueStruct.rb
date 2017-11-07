#!/usr/bin/env ruby

#########################################################################
#
# driver_E2E_CSWCreateQuery
#
#
#########################################################################

Struct.new("Explicit_Reference", :explicit_reference, :annotation, :value)     
@arrERs     = Array.new

explicit_reference   = "S2A_OPER_PRD_HKTM___20150721T213239_20150721T213241_0001"
name                 = "LTA-ARCHIVING-TIME=PAC2"
value                = "2015-07-21T22:05:30"
@arrERs << Struct::Explicit_Reference.new(explicit_reference, name, value)


explicit_reference   = "S2A_OPER_PRD_HKTM___20150721T213239_20150721T213241_0001"
name                 = "LTA-ARCHIVING-TIME=PAC1"
value                = "2015-07-21T22:05:30"
@arrERs << Struct::Explicit_Reference.new(explicit_reference, name, value)

explicit_reference   = "S2A_OPER_PRD_HKTM___20150721T213239_20150721T213241_0001"
name                 = "LTA-ARCHIVING-TIME=PAC2"
value                = "2015-07-21T22:05:30"
@arrERs << Struct::Explicit_Reference.new(explicit_reference, name, value)

explicit_reference   = "S2A_OPER_PRD_HKTM___20150721T213239_20150721T213241_0001"
name                 = "LTA-ARCHIVING-TIME=PAC1"
value                = "2015-07-21T22:05:30"
@arrERs << Struct::Explicit_Reference.new(explicit_reference, name, value)

explicit_reference   = "S2A_OPER_PRD_HKTM___20150721T213239_20150721T213241_0001"
name                 = "LTA-ARCHIVING-TIME=PAC1"
value                = "2015-07-21T22:05:30"
@arrERs << Struct::Explicit_Reference.new(explicit_reference, name, value)


puts @arrERs.uniq
