#!/usr/bin/env ruby

require "rubygems"
require "numru/dcl"
require "numru/ggraph"


include NumRu



gphys = GPhys::IO.open('T.jan.nc', 'T') 
 
DCL.gropn(1) 

DCL.sgpset('isub', 96) 

DCL.sgpset('lfull',true) 

DCL.uzfact(0.6) 

GGraph.set_fig('itr'=> 2) 

GGraph.line(gphys.mean(0,1),true, 'exchange'=>true)

#GGraph.line(gphys.mean(0,1), true, 'exchange'=>true) 

DCL.grcls

exit





# gphys = GPhys::IO.open('dewpoint.nc', 'dewpoint')

gphys = GPhys::IO.open('wind_speed_20111203T000220_20111209T001947.nc', 'wind_speed')

DCL.gropn(1)

#DCL.sgpset('lcntl', false) #; DCL.uzfact(0.7)

GGraph.contour(gphys)

DCL.grcls
