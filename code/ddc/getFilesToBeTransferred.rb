#!/usr/bin/env ruby

# == Synopsis
#
# This is a DDC command line tool that retrieves files to be transfer
# from a the Project source Archive.
# 
#
# == Usage
# getFilesToBeTransferred.rb
#   --list      list only
#   --help      shows this help
#   --usage     shows the usage
#   --Debug     shows Debug info during the execution
#   --version   shows version number
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2006 ESA - Deimos Space S.L.
#

#########################################################################
#
# === Ruby script getFilesToBeTransferred for sending all files to an Entity
# 
# === Written by DEIMOS Space S.L.   (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# CVS: $Id: getFilesToBeTransferred.rb,v 1.4 2007/12/05 17:49:11 decdev Exp $
#
#########################################################################

require 'getoptlong'

require 'ddc/RetrieverFromArchive'
require 'ctc/ReadInterfaceConfig'
require 'cuc/Logger.rb'
require 'cuc/DirUtils'


# Global variables
@@dateLastModification = "$Date: 2007/12/05 17:49:11 $"     # to keep control of the last modification
                                                            # of this script
                                                            # execution showing Debug Info
@isDebugMode      = false
@bList            = false

# MAIN script function
def main


   include           DDC
   include           CUC::DirUtils
   
   opts = GetoptLong.new(
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--list", "-l",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt      
            when "--Debug"   then @isDebugMode = true
            when "--version" then
               print("\nESA - Deimos-Space S.L.  DEC ", File.basename($0), " $Revision: 1.4 $  [", @@dateLastModification, "]\n\n\n")
               exit (0)
            when "--list" then
               @bList = true
            when "--help"    then usage
            when "--usage"   then usage
         end
      end
   rescue Exception
      exit(99)
   end   
    
   @archiveRetriever = RetrieverFromArchive.new
   if @isDebugMode == true then
      @archiveRetriever.setDebugMode
   end
   @archiveRetriever.retrieve(@bList)
   @archiveRetriever.deliver(@bList)
   puts
   
end

#---------------------------------------------------------------------

#---------------------------------------------------------------------
#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -25 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
   exit   
end
#-------------------------------------------------------------


#---------------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
