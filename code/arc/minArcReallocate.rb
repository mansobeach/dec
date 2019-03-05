#!/usr/bin/env ruby

# == Synopsis
#
# This is a MINARC command line tool that reallocates a given file previosuly archived. 
# Archive reallocation is meant by changing the directory location
# If reallocated file is not already archived in the system, an error will be raised.
# 
# 
# -f flag:
#
# Mandatory flag, stands for "--file".
# This option is used to specify the file to be archived. 
# File must be specified with the full path location of the new storage directory.
#
# -d flag:
#
# Mandatory flag, stands for "--directory".
#
#
# == Usage
# minArcReallocate.rb -f <full_path_file> [-R]
#     --file <full_path_file>    it specifies the file to be archived
#     --directory <full_path>    it specifies the directory containing files
#     --Recursive                recursivity through directory
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

require 'arc/FileArchiver'
require 'arc/MINARC_DatabaseModel'

# Global variables
@dateLastModification = "$Date$"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info


# MAIN script function
def main

   @full_path_filename     = ""
   @full_path_dir          = ""
   @filename               = ""
   @filetype               = ""
   @isDebugMode            = false
   @bDelete                = false
   @bMove                  = false
   @bUnpack                = false
   bShowFileTypes          = false
   showVersion             = false
   @arrAddFields           = Array.new
   @bRecursive             = true
   @bUpdate                = false
   
   opts = GetoptLong.new(
     ["--file", "-f",               GetoptLong::REQUIRED_ARGUMENT],
     ["--directory", "-d",          GetoptLong::REQUIRED_ARGUMENT],
     ["--type", "-t",               GetoptLong::REQUIRED_ARGUMENT],
     ["--additional-fields", "-a",  GetoptLong::REQUIRED_ARGUMENT],
     ["--Recursive", "-R",          GetoptLong::NO_ARGUMENT],
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
            when "--directory"         then @full_path_dir      = arg.to_s
	         when "--type"              then @filetype           = arg.to_s
            when "--additional-fields" then @arrAddFields       = arg.to_s.split(":")
			   when "--help"              then usage
	         when "--usage"             then usage
            when "--Recursive"         then @bRecursive  = true
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
 

   if @full_path_filename == "" and @full_path_dir == "" then
      usage
   end
   
   if @full_path_filename != "" and @full_path_dir != "" then
      usage
   end

   if @full_path_dir != "" then
      reallocateDir(@full_path_dir)
      exit(0)
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

   archiver  = ARC::FileArchiver.new
   
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

def reallocateDir(directory)
   pwd = Dir.pwd

   archiver  = ARC::FileArchiver.new
   
   if @isDebugMode then
      archiver.setDebugMode
   end

   Dir.chdir(directory)

   fp  = Dir.pwd

   arrFiles = Dir["*"]

   arrFiles.each{|aFile|
      
      if File.directory?(aFile) == true and @bRecursive == true then
         reallocateDir(aFile)
      end
      
      strFile = "#{fp}/#{aFile}"
   
      puts strFile
   
      ret = archiver.reallocate(strFile)
   
      if ret == false then
         puts "MINARC could not reallocate #{aFile} in #{strFile}"
         next
      end
   }

   Dir.chdir(pwd)

end

#-------------------------------------------------------------

def usage
   fullpathFile = `which #{File.basename($0)}` 
   system("head -36 #{fullpathFile}")
   exit
end

#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
