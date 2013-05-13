# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

# Give it a name
extension_name = 'ruby2300'

# The destination
dir_config(extension_name)

have_library("open2300")

dir_config('open2300', '/Users/borja/Projects/dec/code/ruby2300', '/Users/borja/Projects/dec/code/ruby2300')

$LDFLAGS << " -Wl,-rpath,/Users/borja/Projects/dec/code/ruby2300"

# Do the work
create_makefile(extension_name)
