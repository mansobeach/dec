#########################################################################
#
# === Wrapper for Ruby to EARTH EXPLORER CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
# 
#
#########################################################################

require 'mkmf'

# https://www.cprogramming.com/tutorial/shared-libraries-linux-gcc.html
# https://ruby-doc.org/stdlib-2.5.1/libdoc/mkmf/rdoc/MakeMakefile.html
#rpath

## PENDING
## https://apidock.com/ruby/MakeMakefile/find_library
## https://stackoverflow.com/questions/58870610/using-mkmf-with-ruby-ext-linking-a-static-library-with-l-and-i-and-l
## have_library("curl")


## MODIFY FLAGS ???????????????!!!!!!!!!!!!!!!!!!
## $CXXFLAGS += " -I/usr/local/gr/include -L/usr/local/gr/lib -lGR -lm -Wl,-rpath,/usr/local/gr/lib "


LIBDIR     = RbConfig::CONFIG['libdir']
INCLUDEDIR = RbConfig::CONFIG['includedir']

# HEADER_DIRS = [INCLUDEDIR]

# setup constant that is equal to that of the file path that holds that static libraries that will need to be compiled against


prevDir = Dir.pwd

# Dir.chdir(File.join(File.dirname(__FILE__), 'lib/LINUX64/'))
# Dir.chdir(File.dirname(__FILE__))

cmd = "gcc -Wl,--whole-archive libexplorer_visibility.a libexplorer_orbit.a libexplorer_lib.a libexplorer_file_handling.a libxml2.a libexplorer_data_handling.a libexplorer_pointing.a libtiff.a libgeotiff.a -shared -o libearth_explorer_cfi.so -Wl,-no-whole-archive"
puts cmd
system(cmd)

cmd = "cp libearth_explorer_cfi.so ../../"
puts cmd
system(cmd)

# Dir.chdir(prevDir)

## NEED SOME FULL-PATH !!!!!!!!!!!!!!!!!!!!!!!!!

LIB_DIRS = [LIBDIR, "../../", "..", File.dirname(__FILE__), ".", "/usr/lib/", "/usr/local/lib/", "/usr/lib/system"]

HEADER_DIRS = [INCLUDEDIR, File.expand_path(File.join(File.dirname(__FILE__), "../include"))]

# puts LIB_DIRS

# array of all libraries that the C extension should be compiled against
# - libexplorer_orbit.a
# - others 

# libs = ['-lxml2', '-lexplorer_lib', '-lexplorer_orbit', '-lexplorer_pointing', '-lexplorer_data_handling', '-lexplorer_file_handling', '-lexplorer_visibility', '-learth_explorer_cfi']
libs = ['-learth_explorer_cfi']

#find_library('earth_explorer_cfi')

dir_config('eocfi', HEADER_DIRS, LIB_DIRS)


# iterate though the libs array, and append them to the $LOCAL_LIBS array used for the makefile creation
libs.each do |lib|
  puts lib
  $LOCAL_LIBS << "#{lib} "
end

## create LD_LIBRARY_PATH at execution time
# ENV['LD_LIBRARY_PATH'] = File.expand_path( File.join(File.dirname(__FILE__), "../..") )

# puts $LOCAL_LIBS

create_makefile('ruby_earth_explorer_cfi')

