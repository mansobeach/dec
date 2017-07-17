#########################################################################
#
# === Wrapper for Ruby to EXPLORER_DATA_HANDLING CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
# 
#
#########################################################################

require 'mkmf'

$CXXFLAGS += " -Wincompatible-pointer-types-discards-qualifiers"

LIBDIR      = RbConfig::CONFIG['libdir']
INCLUDEDIR  = RbConfig::CONFIG['includedir']

# Driven by the target platform, select the physical library architecture
LIB_DIRS    = [LIBDIR, File.expand_path(File.join(File.dirname(__FILE__), "../lib/LINUX64"))]
LIB_DIRS    = [LIBDIR, File.expand_path(File.join(File.dirname(__FILE__), "../lib/MACIN64"))]

HEADER_DIRS = [INCLUDEDIR, File.expand_path(File.join(File.dirname(__FILE__), "../include"))]

# array of all libraries that the C extension should be compiled against
# - libexplorer_orbit.a
# - others 

libs = ['-lexplorer_data_handling', '-lexplorer_file_handling', '-lexplorer_visibility', '-lexplorer_lib']

dir_config('explorer_data_handling', HEADER_DIRS, LIB_DIRS)

# iterate though the libs array, and append them to the $LOCAL_LIBS array used for the makefile creation
libs.each do |lib|
   puts lib
  $LOCAL_LIBS << "#{lib} "
end

create_makefile('ruby_explorer_data_handling')
