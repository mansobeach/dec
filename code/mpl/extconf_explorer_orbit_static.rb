# Loads mkmf which is used to make makefiles for Ruby extensions
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

libs = ['-lexplorer_data_handling', '-lexplorer_file_handling', '-lexplorer_orbit', '-lexplorer_lib']

dir_config('explorer_orbit', HEADER_DIRS, LIB_DIRS)

# iterate though the libs array, and append them to the $LOCAL_LIBS array used for the makefile creation
libs.each do |lib|
  $LOCAL_LIBS << "#{lib} "
end

# puts $LOCAL_LIBS

create_makefile('ruby_explorer_orbit')

