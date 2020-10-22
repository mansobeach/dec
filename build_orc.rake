#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #DEC repository management
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === Data Exchange Component (DEC) repository
## 
## Git: rakefile,v $Id$ $Date$
##
## module DEC
##
#########################################################################

require 'rake'


## =============================================================================
##
## Task associated to ORC component

namespace :orc do

   ## -----------------------------
   ## Orchestrator Config files
   
   @arrConfigFiles = [\
      "orchestratorConfigFile.xml",\
      "orchestrator_log_config.xml"]
   ## -----------------------------


   @rootConf = "config/oper_orc"

   ## ----------------------------------------------------------------
   
   desc "build orc gem"

   task :build, [:user, :host] => :load_config do |t, args|
      args.with_defaults(:user => :orctest, :host => "localhost")
      puts "building gem orchestrator with config #{args[:user]}@#{args[:host]}"
   
      if File.exist?("#{@rootConf}/#{args[:user]}@#{args[:host]}") == false then
         puts "Orchestrator configuration not present in repository"
         exit(99)
      end
   
      cmd = "gem build gem_orc.gemspec"
      ret = `#{cmd}`
      if $? != 0 then
         puts "Failed to build gem for Orchestrator"
         exit(99)
      end
      filename = ret.split("File: ")[1].chop
      name     = File.basename(filename, ".*")
      cp filename, "orc.gem"
      mv "orc.gem", "install"
      mv filename, "#{name}_#{args[:user]}@#{args[:host]}.gem"
      @filename = "#{name}_#{args[:user]}@#{args[:host]}.gem"
      # mv filename, "install/gems"
      cp @filename, "install/gems/"
   end

   ## ----------------------------------------------------------------

   desc "list Orchestrator configuration packages"

   task :list_config do
      cmd = "ls #{@rootConf}"
      system(cmd)
   end

   ## ----------------------------------------------------------------

   desc "load Orchestrator configuration package"

   task :load_config, [:user, :host] do |t, args|
      args.with_defaults(:user => :orctest, :host => "localhost")
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
      args.with_defaults(:user => :orctest, :host => :localhost)
            
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

   task :install ,[:user, :host] => :build do |t, args|
      args.with_defaults(:user => :orctest, :host => :localhost)
      puts
      puts @filename
      puts
      cmd = "gem uninstall -x orc"
      puts cmd
      system(cmd)
      cmd = "gem install #{@filename}"
      puts cmd
      system(cmd)
   end
   ## --------------------------------------------------------------------

   ## --------------------------------------------------------------------

end


## ==============================================================================

task :default do
   puts "DEC / ORC repository management"
   cmd = "rake -f build_orc.rake -T"
   system(cmd)
end

## ==============================================================================

