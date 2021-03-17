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
### module DEC
###
#########################################################################

require 'rake'

### ============================================================================
###
### Task associated to DEC component

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
   
   ### ====================================================================
   ###
   ### DEC Containerised tasks
   
   ## ----------------------------------------------------------------

   ## ----------------------------------------------------------------

   desc "build docker DEC image [user , host , prefix]"

   task :image_build, [:user, :host, :suffix] do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost, :suffix => :s2)
      puts "building Docker Image DEC with config #{args[:user]} #{args[:suffix]}@#{args[:host]}"
   
      dockerFile = "Dockerfile.dec.#{args[:suffix]}.#{args[:host]}.#{args[:user]}"
   
      if File.exist?("install/docker/#{dockerFile}") == false then
         puts "DEC Dockerfile #{dockerFile} not present in repository"
         exit(99)
      end
   
      cmd = "docker image build --rm=false -t app_dec_#{args[:suffix]}:latest . -f \"install/docker/#{dockerFile}\""
      puts cmd
      retval = system(cmd)
   end

   ## ----------------------------------------------------------------

   desc "build DEC gem & docker DEC image"

   task :image_build_all, [:user, :host, :suffix] => :build do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost, :suffix => :s2)
      puts "building Docker Image DEC with config #{args[:user]} #{args[:suffix]}@#{args[:host]}"
   
      dockerFile = "Dockerfile.dec.#{args[:suffix]}.#{args[:host]}.#{args[:user]}"
   
      if File.exist?("install/docker/#{dockerFile}") == false then
         puts "DEC Dockerfile #{dockerFile} not present in repository"
         exit(99)
      end
   
      cmd = "docker image build --rm=false -t app_dec_#{args[:suffix]}:latest . -f \"install/docker/#{dockerFile}\""
      puts cmd
      retval = system(cmd)
   end

   ## ----------------------------------------------------------------

   desc "build DEC gem & docker image (container)"

   task :container_build, [:user, :host, :suffix] do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost, :suffix => :s2)
      puts "building Docker Container DEC with config #{args[:user]} #{args[:suffix]}@#{args[:host]}"
   
      dockerFile = "Dockerfile.dec.#{args[:suffix]}.#{args[:host]}.#{args[:user]}"
   
      if File.exist?("install/docker/#{dockerFile}") == false then
         puts "DEC Dockerfile #{dockerFile} not present in repository"
         exit(99)
      end
   
      cmd = "docker create --name dec_#{args[:suffix]} . -f \"install/docker/#{dockerFile}\""
      puts cmd
      retval = system(cmd)
   end
   
   ## ----------------------------------------------------------------

   desc "run DEC container"

   task :container_run, [:user, :host, :suffix] do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost, :suffix => :s2)
      puts "Executing Docker Container DEC with config #{args[:user]} #{args[:suffix]}@#{args[:host]}"
      cmd = "docker container rm dec_#{args[:suffix]}"
      puts cmd
      system(cmd)
      cmd = "docker container run -dit --restart always --name dec_#{args[:suffix]} --hostname dec_#{args[:suffix]} --mount source=volume_dec,target=/volumes/dec --init  app_dec_#{args[:suffix]}:latest"
      puts cmd
      retval = system(cmd)
   end

   ## ----------------------------------------------------------------

   desc "shell to DEC container"

   task :container_shell, [:user, :host, :suffix] do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost, :suffix => :s2)
      puts "Getting shell to Docker Container DEC with config #{args[:user]} #{args[:suffix]}@#{args[:host]}"      
      cmd = "docker container exec -i -t dec_#{args[:suffix]} /bin/bash"
      puts cmd
      retval = system(cmd)
   end

   ## ----------------------------------------------------------------

   ### ====================================================================
   ###
   ### DEC GEM Management tasks
   
   ## ----------------------------------------------------------------
   
   desc "build DEC gem [user, host, suffix = s2 | s2odata]"

   task :build, [:user, :host, :suffix] => :load_config do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost, :suffix => "s2_test_pg")
      puts "building gem dec #{args[:suffix]} with config #{args[:user]}@#{args[:host]}"
   
      if File.exist?("#{@rootConf}/#{args[:user]}@#{args[:host]}") == false then
         puts "DEC configuration not present in repository"
         exit(99)
      end
   
      ## -------------------------------
      ##
      ## Build flags
      ##
      if args[:suffix].include?("odata") == true then
         puts "building gem dec #{args[:suffix]} with flag DEC_ODATA"
         ENV['DEC_ODATA'] = "true"
      else
         ENV.delete('DEC_ODATA')
      end

      if args[:suffix].include?("test") == true then
         puts "building gem dec #{args[:suffix]} with flag DEC_TEST"
         ENV['DEC_TEST'] = "true"
      else
         ENV.delete('DEC_TEST')
      end
      
      if args[:suffix].include?("pg") == true then
         puts "building gem dec #{args[:suffix]} with flag DEC_PG"
         ENV['DEC_PG'] = "true"
      else
         ENV.delete('DEC_PG')
      end
            
      ## -------------------------------
   
      cmd = "gem build gem_dec.gemspec"
      ret = `#{cmd}`
      if $? != 0 then
         puts "Failed to build gem for DEC"
         exit(99)
      end
      filename = ret.split("File: ")[1].chop
      name     = File.basename(filename, ".*")
      mv filename, "#{name}_#{args[:suffix]}_#{args[:user]}@#{args[:host]}.gem"
      @filename = "#{name}_#{args[:suffix]}_#{args[:user]}@#{args[:host]}.gem"
      cp @filename, "install/gems/dec_#{args[:suffix]}.gem"
      cp @filename, "install/gems/"
      # rm @filename
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
      args.with_defaults(:user => :borja, :host => :localhost)
      
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

   ## --------------------------------------------------------------------

   desc "load DEC configuration package"

   task :load_config, [:user, :host, :suffix] do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost, :suffix => "s2_test_pg")
      puts "loading configuration for #{args[:user]}@#{args[:host]} for #{args[:suffix]}"      
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

   task :install ,[:user, :host, :suffix] => :build do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost, :suffix => :s2_pg)
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
      rm @filename
   end
   ## --------------------------------------------------------------------

   desc "Start DEC with docker compose"

   task :start, [:user, :host, :suffix] do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost, :suffix => :s2)
      conf = "docker-compose.dec.#{args[:suffix]}.#{args[:host]}.#{args[:user]}.yml"
      cmd  = "docker-compose -f install/docker/#{conf} up -d"
      puts cmd
      system(cmd)
   end

   ## --------------------------------------------------------------------

   desc "Stop DEC with docker compose"

   task :stop, [:user, :host, :suffix] do |t, args|
      args.with_defaults(:user => :borja, :host => :localhost, :suffix => :s2)
      conf = "docker-compose.dec.#{args[:suffix]}.#{args[:host]}.#{args[:user]}.yml"
      cmd  = "docker-compose -f install/docker/#{conf} down"
      puts cmd
      system(cmd)
   end


   ## --------------------------------------------------------------------

   ## Use this task to maintain an index of the relevant configurations
   ##
   desc "help in the kitchen"

   task :help do
      puts "The kitchen supports the following parameters"
      puts "user => used to define the node" 
      puts "host => used to define the node"
      puts "suffix: odata | test | pg"
      puts
      puts "Some of the above flags can be combined:"
      puts
      puts "> odata : it ships only the decODataClient"
      puts "> test  : it ships the DEC test tools"
      puts "> pg    : it includes installation requirement for postgresql gem"
      puts
      puts
      puts "Most used recipees:" 
      puts
      puts "DEC unit tests"
      puts "rake -f build_dec.rake dec:install[borja,localhost,s2_test_pg]"
      puts "rake -f build_dec.rake dec:install[borja,localhost,s2_test_odata]"
      puts
      puts "S2PDGSENG / Inputhub"
      puts "pull VPMC & VPMC_TCI"
      puts "push HTTP_FERRO"
      puts "rake -f build_dec.rake dec:build[push_lisboa,e2espm-inputhub,s2]"
      puts
      puts "Obsolete:"
      puts "rake -f build_dec.rake dec:build[s2decservice,e2espm-inputhub,s2_pg]"
      puts "Pending ftp port management within containers:"
      puts "rake -f build_dec.rake dec:build[s2decservice_vpmc,e2espm-inputhub,s2]"
      puts
      puts "CloudFerro / S2BOA"
      puts "pull LISBOA"
      puts "pull LOCALFERRO"
      puts "rake -f build_dec.rake dec:build[dec,s2boa-cloudferro,s2]"
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

