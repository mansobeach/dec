#!/usr/bin/env ruby

# == Synopsis
#
# This is a MINARC command line tool that deletes file(s) from the Archive
# according to given criteria. 
# 
# 
# -f flag:
#
# This is a "selection criteria" flag. This option is used to specify the file to be retrieved. 
# Wildcards are allowed. If more than one file matches Rule flag is applied.
# This flag is not compatible with file-type flag "-t" and validity times.
#
#
# -t flag:
#
# This is a "selection criteria flag" is used to specify the file-type of the file to be retrieved.
# This flag is not compatible with the filename selection flag "-f".
#
#
# -s flag:
#
# This flag is used specify the validity start of the file(s) to be retrieved.
# This flag must be specified together "-e" flag. See below "-e" flag specification.
#
#
# -e flag:
#
# This flag is used specify the validity end of the file(s) to be retrieved.
# This flag must be specified together "-s" flag. See above "-s" flag specification.
# 
#
# --boundary_start_on flag:
# This flag is used to specify that time criteria specified overlapping files 
# with validity start sooner than requested are discarded. 
# By default this flag is disabled.
# 
#
# --boundary_end_on flag:
# This flag is used to specify that time criteria specified overlapping files 
# with validity end later than requested are discarded. 
# By default this flag is disabled.
#
#
#
# -R flag:
# 
# Optional flag. It is used to specify that XML Reports should be generated for this execution.
# This flag must be followed by the full path and name of the report to generate.
# -l flag:
#
# This flag is used to list ONLY selected file(s) that would be retrieved.
# No file retrieval is performed. This flag is not compatible with "-d" delete
# flag (see below "-d" flag definition). 
#
#
#
# == Usage
# minArcDelete.rb -t <filetype> [-s <start> -e <end>] | -f <filename>
#     --file <filename>          it deletes a given filename
#     --type <filetype>          file-type of the file to be deleted
#     --start <YYYYMMDDThhmmss>  
#     --end   <YYYYMMDDThhmmss>
#     --Report <full filename>   Ask for report generation, full path and name of the report to generate.
#     --list                     it lists the files that would be retrieved
#                                according to the selection criteria
#     --help                     shows this help
#     --usage                    shows the usage
#     --Debug                    shows Debug info during the execution
#     --version                  shows version number
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
# CVS: $Id: minArcDelete.rb,v 1.10 2008/09/24 10:18:26 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'arc/FileDeleter'

# Global variables
@@dateLastModification = "$Date: 2008/09/24 10:18:26 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   @filename                  = ""
   @filetype                  = ""
   startVal                   = ""
   endVal                     = ""

   @full_report_name          = ""

   bIncStart = false
   bIncEnd = false

   @isDebugMode            = false
   @bListOnly              = false

   showVersion             = false
   
   opts = GetoptLong.new(
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT],
     ["--type", "-t",            GetoptLong::REQUIRED_ARGUMENT],
     ["--start", "-s",           GetoptLong::REQUIRED_ARGUMENT],
     ["--end",   "-e",           GetoptLong::REQUIRED_ARGUMENT],
     ["--Report", "-R",          GetoptLong::REQUIRED_ARGUMENT],
     ["--list", "-l",            GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT],
     ["--boundary_start_on",     GetoptLong::NO_ARGUMENT],
     ["--boundary_end_on",       GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"             then @isDebugMode = true
            when "--list"              then @bListOnly   = true
            when "--version"           then showVersion  = true
            when "--file"              then @filename           = arg.to_s
	         when "--type"              then @filetype           = arg.to_s
            when "--start"             then startVal            = arg.to_s
            when "--end"               then endVal              = arg.to_s
	         when "--Report"            then @full_report_name   = arg.to_s
			   when "--help"              then RDoc::usage
	         when "--usage"             then RDoc::usage("usage")
            when "--boundary_start_on" then bIncStart           = true
            when "--boundary_end_on"   then bIncEnd             = true
         end
      end
   rescue Exception
      exit(99)
   end

   if showVersion then 
      if File.exist?("#{ENV['MINARC_BASE']}/bin/minarc/version.txt") then
         aFile = File.new("#{ENV['MINARC_BASE']}/bin/minarc/version.txt")
      else
         puts "version.txt is not present !"
         exit(99)
      end

      binVersion = aFile.gets.chomp

      puts
      puts "Mini-Archive Component - Version #{binVersion}"
      puts

      aFile.close
      exit(0)
   end
 
   # Check all flags and combinations

   if (startVal != "" and endVal == "") or  (endVal == "" and endVal != "") then
      puts
      puts "Single-bounded intervals are not allowed..."
      puts
      RDoc::usage("usage")
   end

   if @filename == "" and @filetype == "" then
      RDoc::usage("usage")
   end

   if @filename != "" and @filetype != "" then
      RDoc::usage("usage")
   end

   begin
      if startVal != "" and endVal != "" then
         startVal = DateTime.parse(startVal)
         endVal   = DateTime.parse(endVal)
      end
   rescue Exception
      puts
      puts "Error on date provided. See date format below."
      RDoc::usage("usage")
   end

   if startVal != "" then
      if startVal > endVal then
         puts
         puts "Requested Start Time cannot be later than End Time ! :-p"
         puts
         exit(99)
      end
   end


   fileDeleter = ARC::FileDeleter.new(@bListOnly)

   if @isDebugMode == true then
      fileDeleter.setDebugMode
   end

   if @full_report_name != "" then
      if @full_report_name.index('/') == nil or @full_report_name.index('/') != 0 then
         puts
         puts "Please specify a full path and name for the report file !"
         puts
         exit(99)   
      else
         fileDeleter.enableReporting(@full_report_name)
      end
   end

   if @filetype != "" then
      fileDeleter.delete_by_type(@filetype, startVal, endVal, bIncStart, bIncEnd)
   else
      fileDeleter.delete_by_name(@filename)
   end
   #

   exit(0)

end

#-------------------------------------------------------------


#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
