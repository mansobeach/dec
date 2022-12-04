#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #DEC repository management
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === eocfi repository
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

namespace :eocfi do

   ## -----------------------------
   ## eocfi Config files
   
   @arrConfigFiles = [\
      "eocfi_log_config.xml"\
   ]
   ## -----------------------------
   
   @rootConf = "config"
   
   ### ====================================================================
   ###
   ### eocfi GEM Management tasks
   
   ## ----------------------------------------------------------------
   
   desc "build eocfi gem [user, host, suffix = s2 | s2odata]"

   task :build, [:platform] do |t, args|
      args.with_defaults(:platform => "MACIN64")
      puts "building eocfi for platform #{args[:platform]}"
   
      ENV['EOCFI_PLATFORM'] = args[:platform]
   
      if File.exist?("#{@rootConf}/") == false then
         puts "eocfi configuration not present in repository"
         exit(99)
      end
   
      ## -------------------------------
   
      cmd = "cp -f code/eocfi/ext/lib/#{args[:platform]}/*.a code/eocfi/"
      puts cmd
      system(cmd)
   
      cmd = "cp code/eocfi/ext/extconf_earth_explorer_cfi_#{args[:platform]}.rb code/eocfi/ext/extconf_earth_explorer_cfi.rb"
      puts cmd
      system(cmd)
      ## -------------------------------
   
      cmd = "gem build gem_eocfi.gemspec"
      puts cmd
      ret = `#{cmd}`
      if $? != 0 then
         puts "Failed to build gem for eocfi"
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

   desc "compile eocfi C bindings"

   task :compile, [:platform] do |t, args|
      args.with_defaults(:platform => "MACIN64")
      
      puts "compile C extensions"
      
      prevDir = Dir.pwd

=begin      
      Dir.chdir("code/mpl/lib/#{args[:platform]}")
      
      cmd = "gcc -fPIC -g -O3 -shared -o libearth_explorer_cfi.so -Wl,-force_load libexplorer_visibility.a libexplorer_orbit.a libexplorer_lib.a libexplorer_file_handling.a libxml2.a libexplorer_data_handling.a libexplorer_pointing.a libtiff.a libgeotiff.a"
      puts cmd
      system(cmd)
      
      cmd = "mv -f libearth_explorer_cfi.so ../../"
      puts cmd
      system(cmd)
=end      
      
      Dir.chdir(prevDir)
      Dir.chdir("code/mpl/ext")
      cmd = "ruby extconf_earth_explorer_cfi_#{args[:platform]}.rb"
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



   ## ----------------------------------------------------------------

   desc "setup C extension for the specified platform"

   task :makelib, [:platform] do |t, args|
      args.with_defaults(:platform => "MACIN64")
    
      puts "link C library"
    
      prevDir = Dir.pwd
    
      Dir.chdir("code/mpl/lib/#{args[:platform]}")
 
      cmd = "gcc -fPIC -g -O3 -shared -o libearth_explorer_cfi.so -Wl,-force_load libexplorer_visibility.a libexplorer_orbit.a libexplorer_lib.a libexplorer_file_handling.a libxml2.a libexplorer_data_handling.a libexplorer_pointing.a libtiff.a libgeotiff.a"
      puts cmd
      system(cmd)
    
      Dir.chdir(prevDir)
          
   end
   ## ----------------------------------------------------------------

   desc "list eocfi configuration packages"

   task :list_config do
      cmd = "ls #{@rootConf}"
      system(cmd)
   end
   
   ## ----------------------------------------------------------------
   
   desc "update man pages"

   task :update_manpages do
      cmd = "ronn man/eocfi.1.ronn"
      puts cmd
      system(cmd)
      
   end   
   ## ----------------------------------------------------------------
   
   desc "check eocfi configuration package"
   
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

   desc "load eocfi configuration package"

   task :load_config do
      puts "loading eocfi configuration"      
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
   
   desc "uninstall eocfi gem"
   
   task :uninstall do
      cmd = "gem uninstall -x eocfi"
      puts cmd
      system(cmd)      
   end
   ## ----------------------------------------------------------------

   desc "install eocfi"

   task :install ,[:platform] => :build do |t, args|
      args.with_defaults(:platform => "MACIN64")
      puts
      puts @filename
      puts
      
      Rake::Task["eocfi:uninstall"].invoke
      
      # cmd = "gem install #{@filename} -- --with-cflags=-Wno-implicit-function-declaration"
      cmd = "gem install #{@filename} --no-document"
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
      puts "The eocfi kitchen requires the following parameters"
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
         puts "Failed to execute rspec for eocfi"
         exit(99)
      end
   end
   ## --------------------------------------------------------------------

end
## =============================================================================



## =============================================================================

task :default do
   puts "eocfi repository management"
   cmd = "rake -f build_eocfi.rake -T"
   system(cmd)
end

## =============================================================================

