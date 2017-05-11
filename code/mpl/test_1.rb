require "ruby_explorer_orbit"

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




test.PositionInOrbit("/Users/borja/Projects/dec/code/mpl/S2A_OPER_MPL_ORBPRE_20170420T072457_20170430T072457_0001.EOF", 9572, 78.1299)

exit

# # ------------------------------------------------------------------------------
# #
# # This version works without the so called processing id
# # 
# test.PositionInOrbit("/Users/borja/Projects/dec/code/mpl/S2A_OPER_MPL_ORBSCT_20150625T073255_99999999T999999_0006.EOF",
#                                     "20201220T120000", \
#                                     9558, 78.1299)
# # 
# # ------------------------------------------------------------------------------
