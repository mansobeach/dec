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

require 'rubygems'
require 'mini_exiftool'
require 'getoptlong'

require 'cuc/WrapperExifTool'

# MAIN script function

def main

   @bConfirmed  = false
   @filename    = ""



   opts = GetoptLong.new(
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
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
            when "--file"              then @filename    = arg.to_s
			   when "--help"              then usage
	         when "--usage"             then usage
         end
      end
   rescue Exception
      exit(99)
   end

   if @filename == "" then
      usage
   end

   begin
      mdata = MiniExiftool.new @filename
      puts mdata.date_time_original
      puts mdata.duration
      puts mdata.mime_type
   rescue MiniExiftool::Error => e
      $stderr.puts e.message
      exit -1
   end
   
   parser = CUC::WrapperExifTool.new(@filename, false)
   
   puts parser.date_time_original
   
   # puts parser.title
   
   exit(0)

end 
#-------------------------------------------------------------
#-------------------------------------------------------------

def usage
   fullpathFile = `which #{File.basename($0)}` 
   system("head -97 #{fullpathFile}")
   exit
end

#-------------------------------------------------------------


#==========================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
