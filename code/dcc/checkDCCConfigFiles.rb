#!/usr/bin/env ruby

# == Synopsis
#
# This is a DCC command line tool that checks the validity of DCC configuration
# files according to DCC's XSD schemas. This tool should be run everytime a 
# configuration change is performed.
#
# -e flag:
#
# With this option the Interfaces (Entities) configuration file (interfaces.xml)
# is validated using the schema interfaces.xsd
#
# -g flag:
#
# With the main DCC configuration file (dcc_config.xml)
# is validated using the schema dcc_config.xsd
#
# -i flag:
#
# With this option the Incoming file-types configuration file (ft_incoming_files.xml)
# is validated using the schema ft_incoming_files.xsd
#
# -m flag:
#
# With this option the DCC Mail configuration file (ft_mail_config.xml) is
# validated using the schema ft_mail_config.xsd
#
#
# -t flag:
#
# With this option the (DIM)In-Trays configuration file (files2InTrays.xml) is
# validated using the schema files2InTrays.xsd
#
# -a flag:
#
# This is the all flag, which performs all the checks described before.
#
#
# == Usage
#  -a     Check all DCC configuration files
#  -g     Check DCC's general configuration files dcc_config.xml
#  -e     Check the Entities Configuration file interfaces.xml
#  -m     Check the mail configuration file ft_mail_config.xml
#  -i     Check the incoming file-types configuration file ft_incoming_files.xml
#  -t     Check the In-Trays configuration file files2InTrays.xml
#  -h     shows this help
#  -v     shows version number
#    
# 
# == Author
# DEIMOS-Space S.L. (rell)
#
# == Copyright
# Copyright (c) 2007 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# Data Collector Component
# 
# CVS: $Id: checkDCCConfigFiles.rb,v 1.6 2007/11/30 10:11:39 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc'

# Global variables
@@dateLastModification = "$Date: 2007/11/30 10:11:39 $" 
                                    # to keep control of the last modification
                                    # of this script
@bIncoming        = false
@bEntities        = false
@bMail            = false
@bGeneral         = false
@bAll             = false
@bTrays           = false

# MAIN script function
def main

   opts = GetoptLong.new(     
     ["--all", "-a",            GetoptLong::NO_ARGUMENT],
     ["--incoming", "-i",       GetoptLong::NO_ARGUMENT],
     ["--tray", "-t",           GetoptLong::NO_ARGUMENT],
     ["--entities", "-e",       GetoptLong::NO_ARGUMENT],
     ["--mail", "-m",           GetoptLong::NO_ARGUMENT],
     ["--general", "-g",        GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt
            when "--version" then
               print("\nESA - DEIMOS-Space S.L.  Data Collector Component ", File.basename($0), " $Revision: 1.6 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
            when "--help"     then RDoc::usage
            when "--incoming" then @bIncoming = true
            when "--entities" then @bEntities = true
	         when "--mail"     then @bMail     = true
	         when "--general"  then @bGeneral  = true
            when "--all"      then @bAll      = true
            when "--tray"     then @bTrays    = true
            when "--usage"    then RDoc::usage("usage")
         end
      end
   rescue Exception
     exit(99)
   end
 
   if @bIncoming == false and @bEntities == false and @bAll == false and @bMail == false and @bTrays == false and @bGeneral == false then
      RDoc::usage
   end

   # Check DCC's general configuration files dcc_config.xml
   
   if @bGeneral == true or @bAll == true then
      puts "================================================"
      puts "Checking dcc_config.xml..."
      
      validate("dcc_config")

      puts "================================================"
   end

   # Check the Entities Configuration file interfaces.xml
   
   if @bEntities == true or @bAll == true then
      puts "================================================"
      puts "Checking interfaces.xml..."
      
      validate("interfaces")

      puts "================================================"
   end

   # Check the incoming file-types configuration file ft_incoming_files.xml
   
   if @bIncoming == true or @bAll == true then
      puts
      puts "================================================"
      puts "Checking ft_incoming_files.xml..."
      puts
      
      validate("ft_incoming_files")

      puts "================================================"
   end

   # Check the In-Trays configuration file files2InTrays.xml

   if @bAll == true or @bTrays == true then
      puts "================================================"
      puts "Checking files2InTrays.xml..."
      puts
      
      validate("files2InTrays")
      
      puts "================================================"            
   end

   # Check the mail configuration file ft_mail_config.xml

   if @bAll == true or @bMail == true then
      puts "================================================"
      puts "Checking ft_mail_config.xml..."
      puts
 
      validate("ft_mail_config")

      puts "================================================"         
   end
   
end
#-------------------------------------------------------------
# Check the given XML file using the corresponding XSD schema file
def validate (fileName)

   cmd = "#{ENV['DECDIR']}/cots/xmlStarlet/xml val -e --xsd #{ENV['DECDIR']}/schemas/#{fileName}.xsd #{ENV['DCC_CONFIG']}/#{fileName}.xml"

   output = `#{cmd} 2>&1`

   if output.include?("#{fileName}.xml - valid") then
     print "XML Validity test : #{fileName}.xml has passed validation :-)\n"

   elsif output.include?("#{fileName}.xml - invalid") then
     print "XML Validity test : #{fileName}.xml has failed validation :-(\n"
     print "XmlStarlet says : \n#{output}\n"

   else
     print "XML Validity test : UNEXPECTED ERROR :-(\n"
     print "*** Environment was : ***\n"
     print "DCC Config path : #{ENV['DCC_CONFIG']}\n"
     print "XMLStarlet path : #{ENV['DECDIR']}/cots/xmlStarlet/xml\n"
     print "***Command was : ***\n"
     print "#{cmd}\n"
     print "***Output is : ***\n"
     print "#{output}\n"
   end
end
#-------------------------------------------------------------

#-------------------------------------------------------------

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -70 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
   exit   
end
#-------------------------------------------------------------


#==========================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
