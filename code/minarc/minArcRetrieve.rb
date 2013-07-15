#!/usr/bin/env ruby

# == Synopsis
#
# This is a MINARC command line tool that retrieves file(s) from the Archive
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
# -r flag:
#
# This flag determines the selection rule of the candidate files to be retrieved:
# ALL:   all files that fulfills the selection criteria are selected.
# FIRST: first file that fulfills the selection criteria is selected.
# LAST:  last file that fullfills the selection criteria is selected.
# OLDEST: file that has the smallest archive_date is selected.
# NEWEST: file that has the greatest archive_date is selected.
# By default if not specified, ALL rule is applied.
#
#
# -L flag:
#
# This flag is used to specify Location (directiry) in which selected files will be placed.
# No file retrieval is performed. This flag is not compatible with "-l" list
# flag (see below "-l" flag definition). 
#
#
# -l flag:
#
# This flag is used to list ONLY selected file(s) that would be retrieved.
# No file retrieval is performed. This flag is not compatible with "-d" delete
# flag (see below "-d" flag definition). 
#
#
# -d flag:
#
# Optional flag. This flag is used to delete specified selected file(s) after a retrieval.
# If file is not retrieved successfully from the Archive it is not deleted.
#
#
# -R flag:
# 
# Optional flag. It is used to specify that XML Reports should be generated for this execution.
# This flag must be followed by the full name and path of the report to generate.
#
# -r flag:
#
# Optional flag. Enables result filtering when retrieving by file-type.
# Available rules are : ALL, OLDEST, NEWEST.
# ALL : Default behavior ; returns all results.
# OLDEST : returns the result file having the oldest (smallest) archive date
# NEWEST : returns the result file having the most recent (greatest) archive date
#
# -H flag:
#
# Optional flag. This is the Hardlink flag. It is used to perform a Hardlink from the Archive
# to the file desired retrieval location (specified with -L flag). 
# Note that Archive and desired location directories must be in the same filesystem.
#
#
# -T flag:
#
# This flag is used to show all archived file-types.
#
#
# == Usage
# minArcRetrieve.rb -t file-type -s <start> -e <end> -L <full_path_to_location> [-d] [-l]
#     --file <filename>          it retrieves a given filename
#     --type <file-type>         it specifies the file-type of the file to be retrieved
#     --start <YYYYMMDDThhmmss>  
#     --end   <YYYYMMDDThhmmss>
#     --Location <directory>     Directory in which retrieved file(s) will be copied
#     --Hardlink                 It performs a Hardlink rather than a copy from Archive
#     --Report <full filename>   Ask for report generation, full path and name of the report to generate.
#     --rule <filering-rule>     Enable result filtering
#     --delete                   enable delete flag
#     --list                     it lists the files that would be retrieved
#                                according to the selection criteria
#     --help                     shows this help
#     --usage                    shows the usage
#     --Debug                    shows Debug info during the execution
#     --version                  shows version number
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
# CVS: $Id: minArcRetrieve.rb,v 1.16 2008/09/24 10:18:26 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'minarc/FileRetriever'

# Global variables
@@dateLastModification = "$Date: 2008/09/24 10:18:26 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   @full_path_target          = ""
   @full_report_name          = ""
   @filename                  = ""
   @filetype                  = ""
   startVal                   = ""
   endVal                     = ""
   @bHardLink                 = false

   bIncStart = false
   bIncEnd = false

   @isDebugMode            = false
   @bDelete                = false
   @bListOnly              = false
   rule                    = "ALL"
   bShowFileTypes          = false
   showVersion             = false

   arrRules = Array["ALL", "OLDEST", "NEWEST", "FIRST", "LAST"]
   
   opts = GetoptLong.new(
     ["--Location", "-L",              GetoptLong::REQUIRED_ARGUMENT],
     ["--file", "-f",                  GetoptLong::REQUIRED_ARGUMENT],
     ["--type", "-t",                  GetoptLong::REQUIRED_ARGUMENT],
     ["--start", "-s",                 GetoptLong::REQUIRED_ARGUMENT],
     ["--end",   "-e",                 GetoptLong::REQUIRED_ARGUMENT],
     ["--Report", "-R",                GetoptLong::REQUIRED_ARGUMENT],
     ["--rule", "-r",                  GetoptLong::REQUIRED_ARGUMENT],
     ["--list", "-l",                  GetoptLong::NO_ARGUMENT],
     ["--delete", "-d",                GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",                 GetoptLong::NO_ARGUMENT],
     ["--Hardlink", "-H",              GetoptLong::NO_ARGUMENT],
     ["--Types", "-T",                 GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",                 GetoptLong::NO_ARGUMENT],
     ["--version", "-v",               GetoptLong::NO_ARGUMENT],
     ["--help", "-h",                  GetoptLong::NO_ARGUMENT],
     ["--boundary_start_on", "-S",     GetoptLong::NO_ARGUMENT],
     ["--boundary_end_on", "-E",       GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"             then @isDebugMode = true
            when "--delete"            then @bDelete     = true
            when "--list"              then @bListOnly   = true
            when "--version"           then showVersion = true
	         when "--Location"          then @full_path_target   = arg.to_s
	         when "--Report"            then @full_report_name   = arg.to_s
	         when "--rule"              then rule                = arg.to_s.upcase
            when "--file"              then @filename           = arg.to_s
	         when "--type"              then @filetype           = arg.to_s
            when "--start"             then startVal            = arg.to_s
            when "--end"               then endVal              = arg.to_s
			   when "--help"              then RDoc::usage
	         when "--usage"             then RDoc::usage("usage")
            when "--boundary_start_on" then bIncStart           = true
            when "--boundary_end_on"   then bIncEnd             = true
            when "--Hardlink"          then @bHardLink          = true
            when "--Types"             then bShowFileTypes      = true
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
 
   if bShowFileTypes == true then
      arrFiles = ArchivedFile.getFileTypes()
      arrTypes = Array.new
      arrFiles.each{|aFile|
         arrTypes << aFile.filetype
      }
      puts arrTypes.sort
      exit(0)
   end

   # Check all flags and combinations
 
   if @bDelete == true and @bListOnly == true then
      RDoc::usage("usage")
   end

   if @bListOnly == false and @full_path_target == "" then
      RDoc::usage("usage")
   end

   if (startVal != "" and endVal == "") or  (startVal == "" and endVal != "") then
      puts
      puts "Single-bounded intervals are not allowed..."
      puts
      RDoc::usage("usage")
      exit(99)
   end

   if @bListOnly == true and @full_path_target != "" then
      RDoc::usage("usage")
   end

   if @filename != "" and @filetype != "" then
      RDoc::usage("usage")
   end

   if @filename != "" and rule != "ALL" then
      puts
      puts "Rules have no effects when retrieving a file by file-name :-|"
      puts
   end

   if !arrRules.include?(rule) then
      puts
      puts "Invalid rule : '#{rule}' !"
      puts
      RDoc::usage("usage")      
   end

   if @bListOnly == false and @full_path_target.slice(0,1) != "/" then
      puts
      puts "Target directory must be specified with a full path"
      puts
      exit(99)
   end

   dateExpr = "[0-9]{8}T[0-9]{6}"
   if (startVal != "" and endVal != "") and (startVal.match(dateExpr) == nil or endVal.match(dateExpr) == nil) then
      puts
      puts "Invalid date format..."
      puts
      RDoc::usage("usage")
      exit(99)
   end

   begin
      if startVal != "" and endVal != "" then
#         startVal = Time.utc(startVal.slice(0,4), startVal.slice(4,2), startVal.slice(6,2), startVal.slice(9,2), startVal.slice(11,2), startVal.slice(13,2) )
#         endVal   = Time.utc(endVal.slice(0,4), endVal.slice(4,2), endVal.slice(6,2), endVal.slice(9,2), endVal.slice(11,2), endVal.slice(13,2) )
         startVal = DateTime.parse(startVal)
         endVal   = DateTime.parse(endVal)
      end
   rescue Exception
      puts
      puts "Invalid date format or value out of bounds..."
      puts
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


   fileRetriever = MINARC::FileRetriever.new(@bListOnly)

   if @isDebugMode == true then
      fileRetriever.setDebugMode
   end

   if @full_report_name != "" then
      if @full_report_name.index('/') == nil or @full_report_name.index('/') != 0 then
         puts
         puts "Please specify a full path and name for the report file !"
         puts
         exit(99)   
      else
         fileRetriever.enableReporting(@full_report_name)
      end
   end

   fileRetriever.setRule(rule)

   ret = false
   if @filetype != "" then
      ret = fileRetriever.retrieve_by_type(@full_path_target, @filetype, startVal, endVal, @bDelete, bIncStart, bIncEnd, @bHardLink)
   else
      ret = fileRetriever.retrieve_by_name(@full_path_target, @filename, @bDelete, @bHardLink)
   end

   if ret == true then
      exit(0)
   else
      exit(99)
   end

end

#-------------------------------------------------------------


#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
