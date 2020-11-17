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

## rake -f build_minarc.rake minarc:build[s2decservice,e2espm-inputhub,s2_pg]

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
      args.with_defaults(:user => :borja, :host => "localhost", :suffix => "s2_test_pg")
      puts "building gem minarc #{args[:suffix]} with config #{args[:user]}@#{args[:host]}"
   
      if File.exist?("#{@rootConf}/#{args[:user]}@#{args[:host]}") == false then
         puts "minARC configuration not present in repository"
         exit(99)
      end
   
      ## -------------------------------
      ##
      ## Build flags
      ##
      
      if args[:suffix].include?("pg") == true then
         puts "building gem minarc #{args[:suffix]} with flag MINARC_PG"
         ENV['MINARC_PG'] = "true"
      else
         ENV.delete('MINARC_PG')
      end
   
      if args[:suffix].include?("test") == true then
         puts "building gem minarc #{args[:suffix]} with flag MINARC_TEST"
         ENV['MINARC_TEST'] = "true"
      else
         ENV.delete('MINARC_TEST')
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

   task :install ,[:user, :host, :suffix] => :build do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost, :suffix => :s2_pg)
      puts
      puts @filename
      puts
      
      Rake::Task["minarc:uninstall"].invoke
      
      cmd = "gem install #{@filename} --no-document"
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

   ## --------------------------------------------------------------------

   desc "help in the kitchen"

   task :help do
      puts
      puts "The kitchen supports the following parameters:"
      puts "suffix: item to tailor the component library dependencies" 
      puts "user: item to define the node kept in the repository" 
      puts "host: item to define the node kept in the repository"
      puts
      puts "suffix: test | pg"
      puts
      puts "Some of the above flags can be combined:"
      puts
      puts "test: it ships the minArc test tools"
      puts
      puts "pg: it includes installation requirement for postgresql gem"
      puts
      puts "unit tests : rake -f build_minarc.rake minarc:build[borja,localhost,s2_test_pg]"
      puts "s2decservice : rake -f build_minarc.rake minarc:build[s2decservice,e2espm-inputhub,s2_pg]"
      puts "s2boa : rake -f build_minarc.rake minarc:build[boa_app_s2boa,e2espm-inputhub,s2_pg]"
      puts
      puts
   end
   ## --------------------------------------------------------------------


end


## ==============================================================================

task :default do
   puts "minArc repository management"
   cmd = "rake -f build_minarc.rake -T"
   system(cmd)
end

## ==============================================================================

