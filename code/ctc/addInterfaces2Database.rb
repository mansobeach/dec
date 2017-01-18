#!/usr/bin/env ruby

# == Synopsis
#
# This is a Data Exchange Component command line tool that synchronizes the Entities configuration file
# with DEC Inventory. It extracts all the I/Fs from the interfaces.xml file and 
# inserts them in the DEC Inventory.
#
# As well it allows to specify a new I/F mnemonic to be loaded into the DEC Inventory with 
# the "--add" command line option.
#
# == Usage
# addInterfaces2Database.rb --add <MNEMONIC> | --process EXTERNAL
#   --add <MNEMONIC>     (mnemonic is case sensitive) add the specified Entity  
#   --process EXTERNAL   process $DCC_CONFIG/interfaces.xml
#   --Show               it shows all I/Fs already loaded in the DCC Inventory
#   --Verbose            execution in verbose mode
#   --version            shows version number
#   --help      shows this help
#   --usage     shows the usage
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2006 ESA - Deimos Space S.L.
#

#########################################################################
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: addInterfaces2Database.rb,v 1.5 2007/02/06 13:38:56 decdev Exp $
#
#########################################################################

require 'rubygems'
require 'getoptlong'
require 'rdoc'

require 'ctc/ReadInterfaceConfig'

# Global variables
@dateLastModification = "$Date: 2007/02/06 13:38:56 $"   # to keep control of the last modification
                                     # of this script
@verboseMode      = 0                # execution in verbose mode
@mnemonic         = ""
@bShowMnemonics   = false

# MAIN script function
def main   
   add      = 0
   process  = 0
   
   opts = GetoptLong.new(
     ["--add", "-a",            GetoptLong::REQUIRED_ARGUMENT],
     ["--Show", "-S",           GetoptLong::NO_ARGUMENT],
     ["--Verbose", "-V",        GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--process", "-p",        GetoptLong::REQUIRED_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Verbose"       then @verboseMode = 1
   
            when "--version" then
               print("\nESA - Deimos-Space S.L.  DEC ", File.basename($0), " $Revision: 1.5 $  [", @dateLastModification, "]\n\n\n")
               exit (0)
   
            when "--add" then
               add = 1
               @mnemonic = arg         
   
            when "--process" then
               process = 1
               @process = arg
   
            when "--help"          then   usage
                                
            when "--usage"         then   usage
            
            when "--Show"          then @bShowMnemonics = true
         end
      end
   rescue Exception
      exit(99)
   end

   begin
      require 'dbm/DatabaseModel'
    rescue Exception => e
      puts e.to_s
      exit(99)
   end
  
   begin
      arrInterfaces = Interface.all
   rescue ActiveRecord::RecordNotFound => e
      arrInterfaces = Array.new
      puts e.to_s
   end
 
   if @bShowMnemonics == true then
      puts
      puts "=== DEC Inventory Registered I/Fs ==="
      
      if arrInterfaces.empty? == true then
         puts "no interfaces declared in the database"
      end
      
      arrInterfaces.each{|interface|
         puts interface.name
      }
      puts
      exit(0)
   end
 
   if add==1 and process==1 then usage end

   if process==0 and add==0 then usage end
   
   if process==1 and @process!="EXTERNAL" then
      RDoc::usage
   end
  
   
   # add command line mnemonic to the database
   if add==1 and @mnemonic != "" then
      print "\nAdding ", @mnemonic, " to the DEC Inventory/Interfaces ...\n"
      
      anInterface = Interface.new
      anInterface.name = @mnemonic
      res = anInterface.save

      if res == true then
         print "\n", @mnemonic, " added succesfully !\n\n"
         exit(0) 
      else
         print "\n", @mnemonic, " was already present in the DEC Inventory/Interfaces !\n\n"
         exit(99)
      end
   end
   
   # process External|Internal Entities
	arrEnt = nil
   if process==1 then
      cnf    = CTC::ReadInterfaceConfig.instance     
      if @process=="EXTERNAL" then
         arrEnt = cnf.getAllExternalMnemonics
      else
         arrEnt = cnf.getAllInternalMnemonics
      end     
      
		arrEnt.each{|entity|
		   print "\nAdding ", entity, " to the DEC Inventory/Interfaces ..."
         anInterface = Interface.new
         anInterface.name = entity
         anInterface.description = cnf.getDescription(entity)
         res = anInterface.save
         if res == true then
            print "\n", entity, " added succesfully !\n"
         else
            print "\n", entity, " was already present in the DEC Inventory/Entities !\n"
         end
		}
		puts
   end
   
end

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -27 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
   exit   
end
#-------------------------------------------------------------


# Print command line help
def usage_old
   print "\nUsage:\n\t", File.basename($0),    "  --add <mnemonic> | --process EXTERNAL \n\n"
   print "\t--add <mnemonic>     (mnemonic is case sensitive) add the specified Entity\n"  
   print "\t--help               shows this help\n"
   print "\t--process EXTERNAL   process $DCC_CONFIG/interfaces.xml\n"
   print "\t--Verbose            execution in verbose mode\n"
   print "\t--version            shows version number\n"
   print "\n\n"      
   exit
end


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
