#########################################################################
#
# === Wrapper for Ruby to EARTH EXPLORER CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
# 
#
#########################################################################

require 'mkmf'

LIBDIR     = RbConfig::CONFIG['libdir']
INCLUDEDIR = RbConfig::CONFIG['includedir']

# HEADER_DIRS = [INCLUDEDIR]

# setup constant that is equal to that of the file path that holds that static libraries that will need to be compiled against

LIB_DIRS = [LIBDIR, File.expand_path(File.join(File.dirname(__FILE__), "lib/MACIN64"))]

HEADER_DIRS = [INCLUDEDIR, File.expand_path(File.join(File.dirname(__FILE__), "include"))]

# puts LIB_DIRS

# array of all libraries that the C extension should be compiled against
# - libexplorer_orbit.a
# - others 

libs = ['-lxml2', '-lexplorer_lib', '-lexplorer_orbit', '-lexplorer_data_handling', '-lexplorer_file_handling', '-lexplorer_visibility']

#libs = ['-lxml2', '-lexplorer_lib', '-lexplorer_orbit', '-lexplorer_data_handling', '-lexplorer_file_handling']

dir_config('mpl', HEADER_DIRS, LIB_DIRS)


# iterate though the libs array, and append them to the $LOCAL_LIBS array used for the makefile creation
libs.each do |lib|
  puts lib
  $LOCAL_LIBS << "#{lib} "
end

# puts $LOCAL_LIBS

create_makefile('ruby_earth_explorer_cfi')

