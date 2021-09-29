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


prevDir = Dir.pwd

Dir.chdir(File.join(File.dirname(__FILE__), 'lib/LINUX64/'))


cmd = "gcc -Wl,--whole-archive libexplorer_visibility.a libexplorer_orbit.a libexplorer_lib.a libexplorer_file_handling.a libxml2.a libexplorer_data_handling.a libexplorer_pointing.a libtiff.a libgeotiff.a -shared -o libearth_explorer_cfi.so -Wl,-no-whole-archive"
puts cmd
system(cmd)

cmd = "cp libearth_explorer_cfi.so ../../"
puts cmd
system(cmd)

Dir.chdir(prevDir)

# LIB_DIRS = [LIBDIR, File.expand_path(File.join(File.dirname(__FILE__), "lib/#{ENV['MPTOOLS_PLATFORM']}"))]  
LIB_DIRS = [LIBDIR, File.dirname(__FILE__), File.expand_path(File.join(File.dirname(__FILE__), "lib/LINUX64"))]  

HEADER_DIRS = [INCLUDEDIR, File.expand_path(File.join(File.dirname(__FILE__), "include"))]

# puts LIB_DIRS

# array of all libraries that the C extension should be compiled against
# - libexplorer_orbit.a
# - others 

libs = ['-learth_explorer_cfi']

dir_config('mpl', HEADER_DIRS, LIB_DIRS)


# iterate though the libs array, and append them to the $LOCAL_LIBS array used for the makefile creation
libs.each do |lib|
  puts lib
  $LOCAL_LIBS << "#{lib} "
end

# puts $LOCAL_LIBS

create_makefile('ruby_earth_explorer_cfi')

