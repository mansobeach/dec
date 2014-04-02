#!/usr/bin/env ruby

# == Synopsis
#
# This is a MINARC command line tool that reallocates a given file previosuly archived. 
# Arcnive reallocation is meant by changing the directory location
# If reallocated file is not already archived in the system, an error will be raised.
# 
# 
# -f flag:
#
# Mandatory flag, stands for "--file".
# This option is used to specify the file to be archived. 
# File must be specified with the full path location of the new storage directory.
#
#
#
# -a flag:
# Optional flag, stands for "--additional-fields".
# Allows to specify additional fields to fill in the archived_files table and the values
# to fill them with. Field names and values must be separated by ":".
#
#
#
# == Usage
# minArcReallocate.rb -f <full_path_file>
#     --file <full_path_file>    it specifies the file to be archived
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
# Borja Lopez Fernandez
#
# == Copyright
# Copyright (c) 2014 Casale & Beach
#

#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#
#########################################################################

require 'rubygems'
require 'getoptlong'
require 'rdoc'

require 'minarc/FileArchiver2'
require 'minarc/MINARC_DatabaseModel'

# Global variables
@dateLastModification = "$Date: 2008/09/25 11:37:23 $"   # to keep control of the last modification
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
     ["--Debug", "-D",              GetoptLong::NO_ARGUMENT],
     ["--Usage", "-g",              GetoptLong::NO_ARGUMENT],
     ["--version", "-v",            GetoptLong::NO_ARGUMENT],
     ["--help", "-h",               GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"             then @isDebugMode = true
            when "--version"           then showVersion  = true
	         when "--file"              then @full_path_filename = arg.to_s
	         when "--type"              then @filetype           = arg.to_s
            when "--additional-fields" then @arrAddFields       = arg.to_s.split(":")
			   when "--help"              then usage
	         when "--usage"             then usage
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
 

   if @full_path_filename == "" then
      usage
   end
   
   if @full_path_filename.slice(0,1) != "/" then
      puts
      puts "File must be specified with a full path"
      puts
      exit(99)
   end

   @filename   = File.basename(@full_path_filename)
   @full_path  = File.dirname(@full_path_filename)

   # Check the additional field list
   if @arrAddFields.size != 0 and @arrAddFields.size.modulo(2) != 0 then
      puts "Invalid additional-fields list ! :-("
      puts
      exit(99)
   end

   archiver  = MINARC::FileArchiver.new
   
   if @isDebugMode then
      archiver.setDebugMode
   end

   ret = archiver.reallocate(@full_path_filename)
   
   if ret == false then
      puts
      puts "MINARC could not reallocate #{@filename} in #{@full_path}"
      puts
      exit(99)
   end

   puts
   puts "Operation successful ! :-)"
   puts
  
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


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
