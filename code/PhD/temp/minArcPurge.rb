#!/usr/bin/env ruby

# == Synopsis
#
# This is a MINARC command line tool that ***DELETES ALL FILES*** !
#
# ***BE CAREFUL*** using this tool because there is NO ROLLBACK  :-|
#
# 
# 
# -Y flag:
#
# This is the delete confirmation flag. It is required to avoid accidents.
#
# == Usage
#
# (THINK IT TWICE !!! :-|)
# 
# This tool will ERASE all MINARC data.
#
# minArcPurge.rb [-Y]
#
#
# == Author
# DEIMOS-Space S.L.
#
# == Copyright
# Copyright (c) 2008 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# === Mini Archive Component (MinArc)
#
# CVS: $Id: minArcPurge.rb,v 1.2 2008/12/10 15:56:51 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require "minarc/MINARC_DatabaseModel"


# MAIN script function

def main

   @bConfirmed  = false

   opts = GetoptLong.new(
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--YES",   "-Y",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT]
     )

   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"             then @isDebugMode = true
            when "--YES"               then @bConfirmed  = true
            when "--version"           then showVersion  = true
			   when "--help"              then RDoc::usage
	         when "--usage"             then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end

   if @bConfirmed == false then
      RDoc::usage("usage")
   end

   pwd = Dir.pwd

   # Clean-up for CECProductionTimeline


   #------------------------------------------------------------------
   puts
   puts "Clean up of the Archive"

   archiveRoot = ENV["MINARC_ARCHIVE_ROOT"]

   Dir.chdir(archiveRoot)

   ArchivedFile.delete_all

   cmd = "chmod -R a+x *"
   system(cmd)
   
   cmd = "chmod -R a+w *"
   system(cmd)

   cmd = "\\rm -rf *"
   system(cmd)
   
   exit(0)

end 
#-------------------------------------------------------------


#==========================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
