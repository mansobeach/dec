#!/usr/bin/env ruby

#########################################################################
#
# === Wrapper for Ruby to EXPLORER EO CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
# 
#
#########################################################################

require './ruby_explorer_data_handling'

require 'cuc/Converters'

include CUC::Converters

statDB         = "./data/S2__OPER_MPL_GND_DB"
roef           = "./data/S2A_OPER_MPL_ORBSCT"
swath          = "./data/S2A_OPER_MPL_SWTVIS"

test1          = MPL::Explorer_Data_Handling.new
arrStationID   = test1.ReadStationID(statDB, true)

exit


test2          = MPL::Explorer_Visibility.new

arrStationID.each{|station_id|
   outFile  = "S2A_OPER_MPL_GNDVIS_#{station_id}.xml"
   
   puts outFile
   
   retVal   = test2.StationVisTimeCompute(
                                    roef, 
                                    swath, 
                                    statDB, 
                                    station_id, 
                                    10000, 
                                    10143, 
                                    outFile,
                                    true
                                    )


}

exit



# val      = test1.check_library_version






puts
puts val
puts


exit


exit



puts
puts " ---------------------------------"
puts "TEST Explorer_Lib begin"

test0    = MPL::Explorer_Lib.new
val      = test0.check_library_version

puts 
puts val
puts

puts "TEST Explorer_Lib end"
puts " ---------------------------------"
puts

# exit

puts
puts " ---------------------------------"
puts "TEST Explorer_Visibility begin"

test1    = MPL::Explorer_Visibility.new
val      = test1.check_library_version

puts 
puts val
puts
 
puts "TEST Explorer_Visibility end"
puts " ---------------------------------"
puts
# 
# exit

puts
puts " ---------------------------------"
puts "TEST Explorer_Orbit begin"

test0    = MPL::Explorer_Orbit.new
val      = test0.check_library_version

puts 
puts val
puts

puts "TEST Explorer_Orbit end"
puts " ---------------------------------"
puts

exit


test     = MPL::Explorer_Orbit.new


# version  = test.xo_check_library_version
# 
# puts "-----------------------------------------"
# puts
# puts version
# puts
# puts "-----------------------------------------"

# Example with Reference Orbit File

strDate = "20170422T120000"

val = test.DateTime2OrbitAbsolute("data/S2A_OPER_MPL_ORBSCT_20150625T073255_99999999T999999_0006.EOF",
                                    strDate)
puts "-----------------------------------------"
puts
puts "Date => #{strDate} Orbit => #{val}"
puts
puts "-----------------------------------------"


# Example with Predicted Orbit File and date in range

strDate = "20170422T120000"

val = test.DateTime2OrbitAbsolute("data/S2A_OPER_MPL_ORBPRE_20170420T072457_20170430T072457_0001.EOF",
                                    strDate)
puts "-----------------------------------------"
puts
puts "Date => #{strDate} Orbit => #{val}"
puts
puts "-----------------------------------------"


lOrbit      = 9572
fAngleAnx   = 78.1299
strROF      = "Predicted"

val = test.PositionInOrbit("data/S2A_OPER_MPL_ORBPRE_20170420T072457_20170430T072457_0001.EOF", lOrbit, fAngleAnx)

puts "-----------------------------------------"
puts
puts "PositionInOrbit (#{strROF}): Orbit => #{lOrbit} / Angle ANX => #{fAngleAnx} => #{val}"
puts
puts "-----------------------------------------"

puts val
puts self.str2date(val).to_time.usec

timePRE = self.str2date(val).to_time

strROF      = "Reference"

val = test.PositionInOrbit("data/S2A_OPER_MPL_ORBSCT_20150625T073255_99999999T999999_0006.EOF", lOrbit, fAngleAnx)

puts "-----------------------------------------"
puts
puts "PositionInOrbit (#{strROF}): Orbit => #{lOrbit} / Angle ANX => #{fAngleAnx} => #{val}"
puts
puts "-----------------------------------------"


puts self.str2date(val).to_time.usec

timeOSF = self.str2date(val).to_time

puts
puts
puts "Difference between OSF and PRE #{(timeOSF - timePRE)} seconds"
puts
puts
