#!/usr/bin/env ruby

# == Synopsis
#
# This is a MINARC command line tool that checks the validity of MINARC configuration
# files according to XSD schemas. This tool should be run everytime a 
# configuration change is performed.
#
#
# -m flag:
#
# performs the validation of the minarc_config.xml file.
#
#
# == Usage
#  -m     Check minarc_config.xml
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
# CVS: $Id: checkMinarcConfigFiles.rb,v 1.1 2008/03/11 09:49:13 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'rdoc/usage'

# Global variables
@@dateLastModification = "$Date: 2008/03/11 09:49:13 $" 
                                    # to keep control of the last modification
                                    # of this script
@bGlobal        = false


# MAIN script function
def main

   opts = GetoptLong.new(     
     ["--minarc", "-m",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt
            when "--version" then
               print("\nESA - DEIMOS-Space S.L.  Data Collector Component ", File.basename($0), " $Revision: 1.1 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
            when "--help"     then RDoc::usage
	         when "--minarc"   then @bGlobal     = true
            when "--usage"    then RDoc::usage("usage")
         end
      end
   rescue Exception
     exit(99)
   end
 
   if @bGlobal == false then
      RDoc::usage
   end

   # Check MINARC's general configuration files minarc_config.xml
   
   if @bGlobal == true then
      puts "================================================"
      puts "Checking minarc_config.xml..."
      
      validate("minarc_config")

      puts "================================================"
   end

end
#-------------------------------------------------------------
# Check the given XML file using the corresponding XSD schema file
def validate (fileName)

   cmd = "#{ENV['MINARC_BASE']}/cots/xmlStarlet/xml val -e --xsd #{ENV['MINARC_BASE']}/schemas/#{fileName}.xsd #{ENV['MINARC_CONFIG']}/#{fileName}.xml"

   output = `#{cmd} 2>&1`

   if output.include?("#{fileName}.xml - valid") then
     print "XML Validity test : #{fileName}.xml has passed validation :-)\n"

   elsif output.include?("#{fileName}.xml - invalid") then
     print "XML Validity test : #{fileName}.xml has failed validation :-(\n"
     print "XmlStarlet says : \n#{output}\n"

   else
     print "XML Validity test : UNEXPECTED ERROR :-(\n"
     print "*** Environment was : ***\n"
     print "MINARC Config path : #{ENV['MINARC_CONFIG']}\n"
     print "XMLStarlet path : #{ENV['MINARC_BASE']}/cots/xmlStarlet/xml\n"
     print "***Command was : ***\n"
     print "#{cmd}\n"
     print "***Output is : ***\n"
     print "#{output}\n"
   end
end
#-------------------------------------------------------------

#-------------------------------------------------------------


#==========================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
