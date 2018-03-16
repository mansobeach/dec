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
# This is a confirmation flag
#
# == Usage
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
# CVS: $Id: minArcPurge.rb,v 1.1 2008/11/10 09:39:34 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc'

require "arc/MINARC_DatabaseModel"


# MAIN script function

def main

   @bConfirmed  = false

   opts = GetoptLong.new(
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--YES",   "-Y",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT]
     )

   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"             then @isDebugMode = true
            when "--YES"               then @bConfirmed  = true
            when "--version"           then showVersion  = true
			   when "--help"              then usage
	         when "--usage"             then usage
         end
      end
   rescue Exception
      exit(99)
   end

   if @bConfirmed == false then
      usage
   end

   pwd = Dir.pwd

   # Clean-up for CECProductionTimeline


   #------------------------------------------------------------------
   
   archiveRoot = ENV["MINARC_ARCHIVE_ROOT"]

   
   puts
   puts "Clean up of the Archive in #{archiveRoot}"
   puts

   
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
#-------------------------------------------------------------

def usage
   fullpathFile = `which #{File.basename($0)}` 
   system("head -24 #{fullpathFile}")
   exit
end

#-------------------------------------------------------------


#==========================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
