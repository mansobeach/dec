#!/usr/bin/env ruby

# == Synopsis
#
# This is a MINARC command line tool that archives a given file. 
# If such file or a file with exactly same filename is already 
# archived in the system, an error will be raised.
# 
# 
# -f flag:
#
# Mandatory flag, stands for "--file".
# This option is used to specify the file to be archived. 
# File must be specified with the full path location.
#
#
# -t flag:
#
# Optional flag, stands for "--type".
# This flag is used to specify the file-type of the file to be archived.
# By default MINARC will determine the file-type automatically, nevertheless 
# such classification may be overidden using this parameter. 
# In case MINARC fails to determine the file-type, it shall be specified by this flag. 
#
#
# -m flag:
#
# Optional flag, stands for "--move".
# This flag is used to "move" specified source file to the Archive.
# Source file location must be in the same Archive filesystem ($MINARC_ARCHIVE_ROOT).
# By default minArcStore.rb copies source file from the specified location and optionally
# once it is archived it deletes it (see "-d" flag). This flag is not compatible with -d & -H flags.
#
#
# -d flag:
#
# Optional flag, stands for "--delete".
# This flag is used to delete specified source file after a successful Archiving.
# If file is not archived successfully it is not deleted. This flag is not compatible with -m flag.
# 
#
# -U flag:
#
# Optional flag, stands for "--Unpack".
# This is the Unpack flag. It is used to unpack/decompress file before archiving it.
# The file format must be supported to perform the unpack action.
# The following formats are supported:
# - zip
# - tar
# - tgz
# - gz
#
#
# -H flag:
#
# Optional flag. This is the Hardlink flag. It is used to perform a Hardlink from the source file
# (specified with -f flag) to the Archive location . 
# Note that Archive and source file location must be in the same filesystem.
# This flag is not compatible with -d flag.
#
#
# -a flag:
# Optional flag, stands for "--additional-fields".
# Allows to specify additional fields to fill in the archived_files table and the values
# to fill them with. Field names and values must be separated by ":".
#
#
# -T flag:
#
# Standalone flag, stands for "--Types".
# This flag is used to show all archived file-types.
# It is not compatible with any other flags and does not trigger the archiving process.
#
#
# == Usage
# minArcStore.rb -f <full_path_file> [-t type-of-the-file] [-d]
#     --file <full_path_file>    it specifies the file to be archived
#     --type <file-type>         it specifies the file-type of the file to be archived
#     --delete                   enable delete flag
#     --move                     it moves the file to the Archive
#     --update                   it updates the Archive with new file if previously present
#     --Unpack                   enable file unpacking for supported extensions
#     --additional-fields        allows to specify additional fields to fill in the archived_files table.
#     --Hardlink                 enables hardlinking the file to the archive.
#     --Types                    it shows all file-types archived
#     --help                     shows this help
#     --Usage                    shows the usage
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
# CVS: $Id: minArcStore.rb,v 1.13 2008/09/25 11:37:23 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

require 'minarc/FileArchiver2'
require "minarc/MINARC_DatabaseModel"

# Global variables
@@dateLastModification = "$Date: 2008/09/25 11:37:23 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   @full_path_filename     = ""
   @filename               = ""
   @filetype               = ""
   @isDebugMode            = false
   @bDelete                = false
   @bMove                  = false
   @bUnpack                = false
   bShowFileTypes          = false
   showVersion             = false
   @arrAddFields           = Array.new
   @bHardLink              = false
   @bUpdate                = false
   
   opts = GetoptLong.new(
     ["--file", "-f",               GetoptLong::REQUIRED_ARGUMENT],
     ["--type", "-t",               GetoptLong::REQUIRED_ARGUMENT],
     ["--additional-fields", "-a",  GetoptLong::REQUIRED_ARGUMENT],
     ["--Hardlink", "-H",           GetoptLong::NO_ARGUMENT],
     ["--Types", "-T",              GetoptLong::NO_ARGUMENT],
     ["--delete", "-d",             GetoptLong::NO_ARGUMENT],
     ["--update", "-u",             GetoptLong::NO_ARGUMENT],
     ["--move", "-m",               GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",              GetoptLong::NO_ARGUMENT],
     ["--Unpack", "-U",             GetoptLong::NO_ARGUMENT],
     ["--Usage", "-g",              GetoptLong::NO_ARGUMENT],
     ["--version", "-v",            GetoptLong::NO_ARGUMENT],
     ["--help", "-h",               GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"             then @isDebugMode = true
            when "--delete"            then @bDelete     = true
            when "--move"              then @bMove       = true
            when "--update"            then @bUpdate     = true
            when "--version"           then showVersion  = true
	         when "--file"              then @full_path_filename = arg.to_s
	         when "--type"              then @filetype           = arg.to_s
            when "--additional-fields" then @arrAddFields       = arg.to_s.split(":")
            when "--Types"             then bShowFileTypes      = true
			   when "--help"              then RDoc::usage
	         when "--usage"             then RDoc::usage("usage")
            when "--Unpack"            then @bUnpack = true
            when "--Hardlink"          then @bHardLink = true
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
 
   if bShowFileTypes then
      arrFiles = ArchivedFile.getFileTypes()
      arrFiles.each{|aFile|
         puts aFile.filetype
      }
      exit(0)
   end  

   if @bDelete and @bMove then
      RDoc::usage("usage")
   end

   if @bHardLink and @bMove then
      RDoc::usage("usage")
   end


   if @full_path_filename == "" then
      RDoc::usage("usage")
   end
   
   if @full_path_filename.slice(0,1) != "/" then
      puts
      puts "File must be specified with a full path"
      puts
      exit(99)
   end

   if File.directory?(@full_path_filename) == true and @bUnpack == true then
      puts
      puts "Unpack flag cannot be used with a directory !"
      puts
      exit(99)
   end

   @filename = File.basename(@full_path_filename)

   # Check if it is a supported file for unpackaging 
   if @bUnpack == true then
      extension = File.extname(@filename).to_s.downcase
      bSupported = false
      case extension
         when ".zip"  then bSupported = true
         when ".tar"  then bSupported = true
         when ".gz"   then bSupported = true
         when ".tgz"  then bSupported = true
      end

      if bSupported == false then
         puts "#{fileName} is not supported for unpacking ! :-("
         puts
         exit(99)
      end
   end

   # Check the additional field list
   if @arrAddFields.size != 0 and @arrAddFields.size.modulo(2) != 0 then
      puts "Invalid additional-fields list ! :-("
      puts
      exit(99)
   end

   archiver  = MINARC::FileArchiver.new(@bMove, @bHardLink, @bUpdate)
   
   if @isDebugMode then
      archiver.setDebugMode
   end

   ret = archiver.archive(@full_path_filename, @filetype, @bDelete, @bUnpack, @arrAddFields)
   
   if ret == false then
      puts
      puts "MINARC could not archive #{@filename}"
      puts
      exit(99)
   end

   if @isDebugMode then
      puts
      puts "Operation successful !"
      puts
   end
 
   exit(0)

end

#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
