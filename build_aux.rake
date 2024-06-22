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
# module AUX
#
#########################################################################

require 'rake'


## =============================================================================
##
## Task associated to aux component

namespace :aux do

   ## ----------------------------------------------------------------

   desc "build aux gem"

   task :build do
      puts "building gem aux"

      cmd = "gem build gem_aux.gemspec"
      puts cmd
      ret = `#{cmd}`
      if $?.exitstatus != 0 then
         puts "Failed to build gem aux"
         exit(99)
      end
      filename = ret.split("File: ")[1].chop
      name     = File.basename(filename, ".*")

      begin
         rm "install/gems/aux_latest.gem"
      rescue Exception => e
      end

      begin
         rm "install/gems/aux_latest.gem.md5"
      rescue Exception => e
      end

      cp filename, "install/gems/aux_latest.gem"
      cp filename, "aux.gem"

      cmd = "md5sum #{filename}"
      ret = `#{cmd}`
      cmd = "echo #{ret.split(" ")[0]} > #{filename}.md5"
      puts cmd
      system(cmd)

      mv filename, "install/gems/"
      mv "aux.gem", "install/gems/"

      ln "#{filename}.md5", "install/gems/aux_latest.gem.md5"
      mv "#{filename}.md5", "install/gems/"

   end

   ## ----------------------------------------------------------------

   desc "uninstall aux gem"

   task :uninstall do
      cmd = "gem uninstall -x aux"
      puts cmd
      system(cmd)
   end
   ## ----------------------------------------------------------------


   ## --------------------------------------------------------------------

   desc "install aux gem"

   task :install do

      Rake::Task["aux:build"].invoke

      Rake::Task["aux:uninstall"].invoke

      cmd = "gem install install/gems/aux_latest.gem"
      puts cmd
      system(cmd)
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
   puts "aux repository management"
   cmd = "rake -f build_aux.rake -T"
   system(cmd)
end

## ==============================================================================
