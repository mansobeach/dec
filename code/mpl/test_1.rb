require "ruby_explorer_orbit"

require "cuc/Converters"

include CUC::Converters


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

val = test.DateTime2OrbitAbsolute("/Users/borja/Projects/dec/code/mpl/S2A_OPER_MPL_ORBSCT_20150625T073255_99999999T999999_0006.EOF",
                                    strDate)
puts "-----------------------------------------"
puts
puts "Date => #{strDate} Orbit => #{val}"
puts
puts "-----------------------------------------"


# Example with Predicted Orbit File and date in range

strDate = "20170422T120000"

val = test.DateTime2OrbitAbsolute("/Users/borja/Projects/dec/code/mpl/S2A_OPER_MPL_ORBPRE_20170420T072457_20170430T072457_0001.EOF",
                                    strDate)
puts "-----------------------------------------"
puts
puts "Date => #{strDate} Orbit => #{val}"
puts
puts "-----------------------------------------"


lOrbit      = 9572
fAngleAnx   = 78.1299
strROF      = "Predicted"

val = test.PositionInOrbit("/Users/borja/Projects/dec/code/mpl/S2A_OPER_MPL_ORBPRE_20170420T072457_20170430T072457_0001.EOF", lOrbit, fAngleAnx)

puts "-----------------------------------------"
puts
puts "PositionInOrbit (#{strROF}): Orbit => #{lOrbit} / Angle ANX => #{fAngleAnx} => #{val}"
puts
puts "-----------------------------------------"

puts val
puts self.str2date(val).to_time.usec

timePRE = self.str2date(val).to_time

strROF      = "Reference"

val = test.PositionInOrbit("/Users/borja/Projects/dec/code/mpl/S2A_OPER_MPL_ORBSCT_20150625T073255_99999999T999999_0006.EOF", lOrbit, fAngleAnx)

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
