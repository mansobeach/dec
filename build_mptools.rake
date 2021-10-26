#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #DEC repository management
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === mptools repository
### 
### Git: rakefile,v $Id$ $Date$
###
### module MPL
###
#########################################################################

require 'rake'

### ============================================================================
###
### Task associated to MPL codebase

namespace :mptools do

   ## -----------------------------
   ## mptools Config files
   
   @arrConfigFiles = [\
      "mptools_log_config.xml"\
   ]
   ## -----------------------------
   
   @rootConf = "config"
   
   ### ====================================================================
   ###
   ### mptools GEM Management tasks
   
   ## ----------------------------------------------------------------
   
   desc "build mptools gem [user, host, suffix = s2 | s2odata]"

   task :build, [:platform] => :extension_setup do |t, args|
      args.with_defaults(:platform => "MACIN64")
      puts "building mptools for platform #{args[:platform]}"
   
      ENV['MPTOOLS_PLATFORM'] = args[:platform]
   
      if File.exist?("#{@rootConf}/") == false then
         puts "mptools configuration not present in repository"
         exit(99)
      end
   
      ## -------------------------------
      
      # Rake::Task["dec:update_manpages"].invoke
   
      ## -------------------------------
   
      cmd = "gem build gem_mptools.gemspec"
      puts cmd
      ret = `#{cmd}`
      if $? != 0 then
         puts "Failed to build gem for mptools"
         exit(99)
      end
      filename = ret.split("File: ")[1].chop
      name     = File.basename(filename, ".*")
      mv filename, "#{name}_#{args[:platform]}.gem"
      @filename = "#{name}_#{args[:platform]}.gem"
      cp @filename, "install/gems/"
      # rm @filename
   end

   ## ----------------------------------------------------------------

   desc "compile mptools C bindings"

   task :compile, [:platform] do |t, args|
      args.with_defaults(:platform => "MACIN64")
      
      puts "compile C extensions"
      
      prevDir = Dir.pwd
      
      Dir.chdir("code/mpl/lib/#{args[:platform]}")
      
      cmd = "gcc -fPIC -g -O3 -shared -o libearth_explorer_cfi.so -Wl,-force_load libexplorer_visibility.a libexplorer_orbit.a libexplorer_lib.a libexplorer_file_handling.a libxml2.a libexplorer_data_handling.a libexplorer_pointing.a libtiff.a libgeotiff.a"
      puts cmd
      system(cmd)
      
      cmd = "mv -f libearth_explorer_cfi.so ../../"
      puts cmd
      system(cmd)
      
      
      Dir.chdir(prevDir)
      Dir.chdir("code/mpl")
      cmd = "ruby extconf_earth_explorer_cfi.rb"
      puts cmd
      system(cmd)
      
      cmd = "make clean"
      puts cmd
      system(cmd)

      cmd = "make"
      puts cmd
      system(cmd)

      Dir.chdir(prevDir)      
      
   end
   ## ----------------------------------------------------------------

   ## ----------------------------------------------------------------

   desc "setup C extension for the specified platform"

   task :extension_setup, [:platform] do |t, args|
      args.with_defaults(:platform => "MACIN64")
      
      puts "compile C extensions"
      
      prevDir = Dir.pwd
      
      Dir.chdir("code/mpl")
      
      cmd = "cp extconf_earth_explorer_cfi_#{args[:platform]}.rb extconf_earth_explorer_cfi.rb"
      puts cmd
      system(cmd)
      
      Dir.chdir(prevDir)      
      
   end
   ## ----------------------------------------------------------------

   desc "list mptools configuration packages"

   task :list_config do
      cmd = "ls #{@rootConf}"
      system(cmd)
   end
   
   ## ----------------------------------------------------------------
   
   desc "update man pages"

   task :update_manpages do
      cmd = "ronn man/mptools.1.ronn"
      puts cmd
      system(cmd)
      
   end   
   ## ----------------------------------------------------------------
   
   desc "check mptools configuration package"
   
   task :check_config do
            
      path     = "#{@rootConf}/"
      
      @arrConfigFiles.each{|file|
         filename = "#{path}/#{file}"
         if File.exist?(filename) == false then
            puts "#{filename} not found :-("
         else
            puts "#{filename} is present :-)"
         end
      }
      
   end
   ## ----------------------------------------------------------------


   ## --------------------------------------------------------------------

   desc "load mptools configuration package"

   task :load_config do
      puts "loading mptools configuration"      
      path     = "#{@rootConf}/"
      
      if File.exist?(path) == false then
         mkdir_p path
      end
            
      @arrConfigFiles.each{|file|
         filename = "#{path}/#{file}"
         if File.exist?(filename) == true then
            puts "config #{filename} is present"
         else
            puts "#{filename} not found #{'1F480'.hex.chr('UTF-8')}"
            exit(99)
         end
      }
   end
   ## ----------------------------------------------------------------
   
   desc "uninstall mptools gem"
   
   task :uninstall do
      cmd = "gem uninstall -x mptools"
      puts cmd
      system(cmd)      
   end
   ## ----------------------------------------------------------------

   desc "install mptools"

   task :install ,[:platform] => :build do |t, args|
      args.with_defaults(:platform => "MACIN64")
      puts
      puts @filename
      puts
      
      Rake::Task["mptools:uninstall"].invoke
#      cmd = "gem uninstall -x dec"
#      puts cmd
#      system(cmd)
      
      cmd = "gem install #{@filename} -- --with-cflags=-Wno-implicit-function-declaration"
      puts cmd
      system(cmd)
      rm @filename
   end
   ## --------------------------------------------------------------------


   ## --------------------------------------------------------------------


   ## --------------------------------------------------------------------

   ## Use this task to maintain an index of the relevant configurations
   ##
   desc "help in the kitchen"

   task :help do
      puts "The mptools kitchen requires the following parameters"
      puts "platform => MACIN64 | LINUX64" 
      puts
      puts
   end
   ## --------------------------------------------------------------------

   ## --------------------------------------------------------------------

   desc "perform RSpec TDD/BDD"

   task :test_rspec do
      cmd = "rspec -fd --profile --default-path code/dec"
      puts cmd
      ret = system(cmd)

      if ret != true then
         puts "Failed to execute rspec for mptools"
         exit(99)
      end
   end
   ## --------------------------------------------------------------------

end
## =============================================================================



## =============================================================================

task :default do
   puts "mptools repository management"
   cmd = "rake -f build_mptools.rake -T"
   system(cmd)
end

## =============================================================================

