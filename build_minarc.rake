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
      "cert.pem",\
      "key.pem",\
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

      if args[:suffix].include?("sqlite") == true then
         puts "building gem minarc #{args[:suffix]} with flag MINARC_SQLITE3"
         ENV['MINARC_SQLITE3'] = "true"
      else
         ENV.delete('MINARC_SQLITE3')
      end

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
      puts cmd
      ret = `#{cmd}`
      if $?.exitstatus != 0 then
         puts "Failed to build gem for minArc"
         exit(99)
      end

      begin
         File.unlink("install/gems/minarc_latest.gem.md5")
      rescue Exception => e
         # puts e.to_s
      end

      filename = ret.split("File: ")[1].chop
      name     = File.basename(filename, ".*")
      mv filename, "#{name}_#{args[:suffix]}_#{args[:user]}@#{args[:host]}.gem"
      @filename = "#{name}_#{args[:suffix]}_#{args[:user]}@#{args[:host]}.gem"

      cmd = "md5sum #{@filename}"
      puts cmd
      ret = `#{cmd}`
      cmd = "echo #{ret.split(" ")[0]} > #{@filename}.md5"
      puts cmd
      system(cmd)

      ln "#{@filename}.md5", "install/gems/minarc_latest.gem.md5"

      begin
         rm "install/gems/minarc_latest.gem"
      rescue Exception => e
         # puts e.to_s
      end
      puts "ln #{@filename} install/gems/minarc_latest.gem"
      ln @filename, "install/gems/minarc_latest.gem"

      cp @filename, "install/gems/minarc_#{args[:suffix]}.gem"
      cp @filename, "install/gems/"
      # rm @filename
   end

   ## ----------------------------------------------------------------

   ## ----------------------------------------------------------------

   desc "load Orchestrator / minarc configuration package"

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
         if File.exist?(filename) == true then
            cp filename, "config/#{file}"
         end
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

   ### minARC Containerised tasks

   desc "build docker minARC image [user , host , prefix]"

   task :image_build, [:user, :host, :suffix] do |t, args|
      # args.with_defaults(:user => :borja, :host => :localhost, :suffix => :s2)

      dockerFile = "Dockerfile.#{args[:suffix]}.minarc.#{args[:host]}.#{args[:user]}.yaml"

      puts "building Docker Image minARC with config #{args[:user]} #{args[:suffix]}@#{args[:host]}"
      puts "#{dockerFile}"

      if File.exist?("install/docker/#{dockerFile}") == false then
         puts "DEC Dockerfile #{dockerFile} not present in repository"
         exit(99)
      end

      cmd = "docker image build --rm=false -t app_#{args[:suffix]}_minarc:latest . -f \"install/docker/#{dockerFile}\""
      puts cmd
      retval = system(cmd)
   end

   ## ----------------------------------------------------------------

   desc "build minarc gem & docker compose service image (container)"

   task :build_service, [:user, :host, :suffix] do |t, args|
      args.with_defaults(:user => "borja", :host => "localhost", :suffix => "s2")
      puts "building Docker Container DEC with config #{args[:user]} #{args[:suffix]}@#{args[:host]}"

      cmd = "rake -f build_minarc.rake minarc:build[s2decservice,cloudferro,s2_pg]"
      puts cmd
      system(cmd)

      ### sudo docker image build --rm=false -t app_minarc_s2 . -f install/docker/Dockerfile.decservice.minarc.s2.cloudferro

      dockerFile  = "Dockerfile.decservice.minarc.#{args[:suffix]}.#{args[:host]}"
      composeFile = "docker-compose.minarcservice.#{args[:suffix]}.#{args[:host]}.yml"
      dbName      = "minarc_db_#{args[:suffix]}"
      appName     = "app_minarc_#{args[:suffix]}"

      if File.exist?("install/docker/#{dockerFile}") == false then
         puts "DEC Dockerfile #{dockerFile} not present in repository"
         exit(99)
      end

      # cmd = "docker create --name dec_#{args[:suffix]} . -f \"install/docker/#{dockerFile}\""

      ## Create directories
      cmd = "mkdir -p /volume1/dec/arc/minarc_log"
      puts cmd
      retval = system(cmd)


      cmd = "docker image build --rm=false -t #{appName} . -f \"install/docker/#{dockerFile}\""
      puts cmd
      retval = system(cmd)

      cmd = "docker-compose -f install/docker/#{composeFile} up -d #{dbName}"
      puts cmd
      retval = system(cmd)

      cmd = "docker exec -it minarc_db_s2 psql -U s2minarc -c \"create database s2minarc\""
      puts cmd
      retval = system(cmd)

      cmd = "docker-compose -f install/docker/#{composeFile} up"
      puts cmd
      retval = system(cmd)

   end

   ## ----------------------------------------------------------------


   ## --------------------------------------------------------------------

   desc "help in the kitchen"

   task :help do
      puts
      puts "The kitchen supports the following parameters:"
      puts "suffix: item to tailor the component library dependencies"
      puts "user: item to define the node kept in the repository"
      puts "host: item to define the node kept in the repository"
      puts
      puts "suffix: test | pg | sqlite3"
      puts
      puts "Some of the above flags can be combined:"
      puts
      puts "test: it ships the minArc test tools"
      puts
      puts "pg: it includes installation requirement for postgresql gem"
      puts
      puts "unit tests           : rake -f build_minarc.rake minarc:build[borja,localhost,s2_test_pg]"
      puts
      puts
      puts "ADGS"
      puts "rake -f build_minarc.rake minarc:install[adgs,localhost,adgs_test_pg]"
      puts
      puts "NAOS"
      puts "naosboa@orc_boa       : rake -f build_minarc.rake minarc:build[gsc4eo,nl2-s-aut-srv-01,naos_test]"
      puts "naosboa@orc_boa       : rake -f build_minarc.rake minarc:build[naosboa,orc_boa,naos_test_pg]"
      puts
      puts "CLOUDFERRO LTA"
      puts "s2boa@cloudferro     : rake -f build_minarc.rake minarc:build[s2decservice,cloudferro,s2_pg]"
      puts "client@cloudferro    : rake -f build_minarc.rake minarc:build[s2decservice,cloudferro,s2]"
      puts "testclient@cloudferro: rake -f build_minarc.rake minarc:build[s2decservice,cloudferro,s2_test]"
      puts
      puts "S2BOA"
      puts "s2boa@inputhub       : rake -f build_minarc.rake minarc:build[boa_app_s2boa,e2espm-inputhub,s2_pg]"
      puts
      puts "mansovideo@macblind  : rake -f build_minarc.rake minarc:build[mansovideo,macblind,sqlite3]"
      puts "s2decservice   (obsolete) : rake -f build_minarc.rake minarc:build[s2decservice,e2espm-inputhub,s2_pg]"
      puts
      puts
      puts "image build : rake -f build_minarc.rake minarc:build_service[s2decservice,cloudferro,s2_pg]"
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
