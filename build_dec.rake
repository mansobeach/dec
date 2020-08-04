#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DEC repository management
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component (DEC) repository
# 
# Git: rakefile,v $Id$ $Date$
#
# module DEC
#
#########################################################################

require 'rake'

## =============================================================================
##
## Task associated to DEC component

namespace :dec do

   ## -----------------------------
   ## DEC Config files
   
   @arrConfigFiles = [\
      "dec_interfaces.xml",\
      "dec_incoming_files.xml",\
      "dec_outgoing_files.xml",\
      "ft_mail_config.xml",\
      "dec_log_config.xml",\
      "dec_config.xml"]
   ## -----------------------------
   
   @rootConf = "config/oper_dec"
   
   ## ----------------------------------------------------------------
   
   desc "build DEC gem"

   task :build, [:user, :host] => :load_config do |t, args|
      args.with_defaults(:user => :dectest, :host => :localhost)
      puts "building gem DEC with config #{args[:user]}@#{args[:host]}"
   
      if File.exist?("#{@rootConf}/#{args[:user]}@#{args[:host]}") == false then
         puts "DEC configuration not present in repository"
         exit(99)
      end
   
      cmd = "gem build gem_dec.gemspec"
      ret = `#{cmd}`
      if $? != 0 then
         puts "Failed to build gem for DEC"
         exit(99)
      end
      filename = ret.split("File: ")[1].chop
      name     = File.basename(filename, ".*")
      mv filename, "#{name}_#{args[:user]}@#{args[:host]}.gem"
      @filename = "#{name}_#{args[:user]}@#{args[:host]}.gem"
      cp @filename, "install/gems/dec.gem"
      cp @filename, "install/gems/"
   end

   ## ----------------------------------------------------------------

   desc "list DEC configuration packages"

   task :list_config do
      cmd = "ls #{@rootConf}"
      system(cmd)
   end
   
   ## ----------------------------------------------------------------
   
   desc "check DEC configuration package"
   
   task :check_config, [:user, :host] do |t, args|
      args.with_defaults(:user => :dectest, :host => :localhost)
      
      if File.exist?("#{@rootConf}/#{args[:user]}@#{args[:host]}") == false then
         puts "DEC configuration not present in repository"
         exit(99)
      end
      
      path     = "#{@rootConf}/#{args[:user]}@#{args[:host]}"
      prefix   = "#{args[:user]}@#{args[:host]}#"
      
      @arrConfigFiles.each{|file|
         filename = "#{path}/#{prefix}#{file}"
         if File.exist?(filename) == false then
            puts "#{filename} not found :-("
         else
            puts "#{filename} is present :-)"
         end
      }
      
   end
   # --------------------------------------------------------------------

   desc "save DEC configuration package"

   task :save_config, [:user, :host] do |t, args|
      args.with_defaults(:user => :dectest, :host => :localhost)
            
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

   ## --------------------------------------------------------------------

   desc "load DEC configuration package"

   task :load_config, [:user, :host] do |t, args|
      args.with_defaults(:user => :dectest, :host => :localhost)
      puts "loading configuration for #{args[:user]}@#{args[:host]}"      
      path     = "#{@rootConf}/#{args[:user]}@#{args[:host]}"
      
      if File.exist?(path) == false then
         mkdir_p path
      end
      
      prefix   = "#{args[:user]}@#{args[:host]}#"
      
      @arrConfigFiles.each{|file|
         filename = "#{path}/#{prefix}#{file}"
         if File.exist?(filename) == true then
            cp filename, "config/#{file}"
         else
            puts "#{filename} not found #{'1F480'.hex.chr('UTF-8')}"
            exit(99)
         end
      }
   end
   ## ----------------------------------------------------------------
   
   desc "uninstall DEC gem"
   
   task :uninstall do
      cmd = "gem uninstall -x dec"
      puts cmd
      system(cmd)      
   end
   ## ----------------------------------------------------------------

   desc "install DEC"

   task :install ,[:user, :host] => :build do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost)
      puts
      puts @filename
      puts
      
      Rake::Task["dec:uninstall"].invoke
#      cmd = "gem uninstall -x dec"
#      puts cmd
#      system(cmd)
      
      cmd = "gem install #{@filename}"
      puts cmd
      system(cmd)
   end
   ## --------------------------------------------------------------------

   desc "perform RSpec TDD/BDD"

   task :test_rspec do
      cmd = "rspec -fd --profile --default-path code/dec"
      puts cmd
      ret = system(cmd)

      if ret != true then
         puts "Failed to execute rspec for DEC"
         exit(99)
      end
   end
   ## --------------------------------------------------------------------

end
## =============================================================================



## =============================================================================

task :default do
   puts "DEC repository management"
   cmd = "rake -f build_dec.rake -T"
   system(cmd)
end

## =============================================================================

