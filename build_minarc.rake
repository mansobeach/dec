#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #DEC repository management
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component (DEC) repository
### 
### Git: rakefile,v $Id$ $Date$
###
### module ARC
###
#########################################################################

require 'rake'


## =============================================================================
##
## Task associated to minARC component

namespace :minarc do

   ## -----------------------------
   ## minARC Config files
   
   @arrConfigFiles = [\
      "minarc_config.xml",\
      "minarc_log_config.xml"]
   ## -----------------------------
   
   @rootConf = "config/oper_arc"

   ## ----------------------------------------------------------------
   
   desc "build minarc gem"

   task :build, [:user, :host, :suffix] => :load_config do |t, args|
      args.with_defaults(:user => :borja, :host => "localhost", :suffix => :s2)
      puts "building gem minarc_#{args[:suffix]} with config #{args[:user]}@#{args[:host]}"
   
      if File.exist?("#{@rootConf}/#{args[:user]}@#{args[:host]}") == false then
         puts "minARC configuration not present in repository"
         exit(99)
      end
   
      cmd = "gem build gem_minarc.gemspec"
      ret = `#{cmd}`
      if $?.exitstatus != 0 then
         puts "Failed to build gem for minArc"
         exit(99)
      end
      filename = ret.split("File: ")[1].chop
      name     = File.basename(filename, ".*")
      mv filename, "#{name}_#{args[:suffix]}_#{args[:user]}@#{args[:host]}.gem"
      @filename = "#{name}_#{args[:suffix]}_#{args[:user]}@#{args[:host]}.gem"
      cp @filename, "install/gems/minarc_#{args[:suffix]}.gem"
      cp @filename, "install/gems/"
      # rm @filename
   end

   ## ----------------------------------------------------------------

   ## ----------------------------------------------------------------

   desc "load Orchestrator configuration package"

   task :load_config, [:user, :host] do |t, args|
      args.with_defaults(:user => :borja, :host => "localhost")
      puts "loading configuration for #{args[:user]}@#{args[:host]}"      
      path     = "#{@rootConf}/#{args[:user]}@#{args[:host]}"
      
      if File.exist?(path) == false then
         mkdir_p path
      end
      
      prefix   = "#{args[:user]}@#{args[:host]}#"
      
      @arrConfigFiles.each{|file|
         filename = "#{path}/#{prefix}#{file}"
         cp filename, "config/#{file}"
      }
   end
   ## --------------------------------------------------------------------

   desc "save Orchestrator configuration package"

   task :save_config, [:user, :host] do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost)
            
      path     = "#{@rootConf}/#{args[:user]}@#{args[:host]}"
      
      if File.exist?(path) == false then
         mkdir_p path
      else
         puts
         puts "THINK CAREFULLY !"
         puts
         puts "this will overwrite configuration for #{args[:user]}@#{args[:host]}"
         puts
         puts "proceed? Y/n"
               
         c = STDIN.getc   
         if c != 'Y' then
            exit(99)
         end
      end
      
      prefix   = "#{args[:user]}@#{args[:host]}#"
      
      @arrConfigFiles.each{|file|
         cp "config/#{file}", filename = "#{path}/#{prefix}#{file}"
      }
   end
   ## --------------------------------------------------------------------

   ## ----------------------------------------------------------------
   
   desc "uninstall minARC gem"
   
   task :uninstall do
      cmd = "gem uninstall -x minarc"
      puts cmd
      system(cmd)      
   end
   ## ----------------------------------------------------------------

   task :install ,[:user, :host] => :build do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost)
      puts
      puts @filename
      puts
      
      Rake::Task["minarc:uninstall"].invoke
      
      cmd = "gem install #{@filename}"
      puts cmd
      system(cmd)
      rm @filename
   end
   ## --------------------------------------------------------------------

#   # to verify the installation and gem dependencies installation without gemfile
#   task :test_install
#   
#   end
   ## --------------------------------------------------------------------

end


## ==============================================================================

task :default do
   puts "minArc repository management"
   cmd = "rake -f build_minarc.rake -T"
   system(cmd)
end

## ==============================================================================

