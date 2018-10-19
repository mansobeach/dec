#!/usr/bin/env ruby

# == Synopsis
#
# This is an DDC command line tool that ***DELETES ALL QUEUES*** !
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
# purgeDDC.rb [-Y]
#     --YES        Confirmation required to delete all ddc tables
#     --INT        Confirmation required to delete interface dec tables
#
#
# == Author
# DEIMOS-Space S.L.  (ALGK)
#
# == Copyright
# Copyright (c) 2008 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# === MDS-LEGOS (DDC)
#
# CVS: $Id: purgeDDC.rb,v 1.4 2009/06/04 10:41:04 algs Exp $
#
#########################################################################

require 'getoptlong'

require "dbm/DatabaseModel"
require 'ddc/ReadConfigDDC'


# MAIN script function

def main

   @bConfirmed  = false

   opts = GetoptLong.new(
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--YES",   "-Y",           GetoptLong::NO_ARGUMENT],
     ["--INT",   "-I",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT]
     )

   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"             then @isDebugMode = true
            when "--YES"               then @bConfirmed  = true
            when "--INT"               then @bInterface  = true
            when "--version" then
               projectName = DDC::ReadConfigDDC.instance
               version = File.new("#{ENV["DECDIR"]}/version.txt").readline
               print("\nESA - DEIMOS-Space S.L.  DEC   ", version," \n[",projectName.getProjectName,"]\n\n\n")
               exit (0)
			   when "--help"              then usage
	         when "--usage"             then usage
         end
      end
   rescue Exception
      exit(99)
   end

   if @bConfirmed == false then
      usage
   end


   #------------------------------------------------------------------
   puts
   puts "Clean up of DDC tables"
   puts

   if SentFile.table_exists?() == true then
      SentFile.delete_all
   end

   if Interface.table_exists?() == true and @bInterface == true then
      puts
      puts "Clean up of Interface table"
      puts
      begin
         Interface.delete_all
      rescue Exception => e
         puts "Cant delete Interfaces, check that there are no constrains affecting the table"
         puts
      end
   end
   
   exit(0)

end 
#-------------------------------------------------------------

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -26 #{fullpathFile}"}`
      
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
