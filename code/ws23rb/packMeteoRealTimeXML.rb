#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to generate the daily meteo files
#
# == Usage
#  packMeteoRealTimeXML.rb
#     --station <meteo-station>
#     --date YYYYMMDD
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --Force               force mode
#     --version             shows version number      
# 

# == Author
# Borja Lopez Fernandez
#
# == Copyright
# Casale Beach


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

require 'getoptlong'
require 'rdoc/usage'

require 'cuc/PackageUtils'

require 'minarc/MINARC_DatabaseModel'


# MAIN script function
def main

   include CUC::PackageUtils

   @locker        = nil
   @isDebugMode   = false
   @isForceMode   = false
   @stationName   = ""
   @date          = ""

   opts = GetoptLong.new(
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",          GetoptLong::NO_ARGUMENT],
     ["--station", "-s",        GetoptLong::REQUIRED_ARGUMENT],
     ["--date", "-d",           GetoptLong::REQUIRED_ARGUMENT],       
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt
            when "--station" then @stationName = arg.to_s
            when "--date"    then @date   = arg.to_s 
            when "--Debug"   then @isDebugMode = true
            when "--Force"   then @isForceMode = true
            when "--version" then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--usage"   then RDoc::usage("usage")
            when "--help"    then RDoc::usage                         
         end
      end
   rescue Exception
      exit(99)
   end

   if @stationName == "" or @date == "" then
      RDoc::usage("usage")
   end
   
   # ArchivedFile.new

# ActiveRecord::Base.establish_connection

#   ret = ActiveRecord::Base.connection.execute("SELECT distinct filetype FROM archived_files")


   minArcDir   = ENV['MINARC_ARCHIVE_ROOT']
   prevDir     = Dir.pwd
   dir_path    = "#{minArcDir}/REALTIME_XML/#{@stationName}/#{@date.slice(0,4)}/#{@date.slice(4,2)}/" 

   # {@date.slice(6,2)}"

   Dir.chdir(dir_path)

   arrDirs = Dir["*"].sort

   arrDirs.each{|aDir|

      filename = "#{prevDir}/DAILY_REALTIME_#{@stationName}_#{@date.slice(0,6)}#{aDir}.7z"
      retVal   = pack7z(aDir, filename, false, true)

      # Archive new file

      if retVal == true then
         cmd = "minArcStore2.rb -f #{filename} -d -u -t DAILY_REALTIME_7Z"
         if @isDebugMode == true then
#            cmd = "#{cmd} -D"
            puts cmd
            puts
         end
         system(cmd)
      end

   }

   # Delete from inventory

   puts "Files records deletion from inventory"
   sql = "SELECT filename FROM archived_files where filetype='REALTIME_XML_#{@stationName}' AND filename like 'REALTIME_#{@stationName}_#{@date.slice(0,6)}%'"

   sql = "DELETE FROM archived_files where filetype='REALTIME_XML_#{@stationName}' AND filename like 'REALTIME_#{@stationName}_#{@date.slice(0,6)}%'"

   puts sql

   ret = ActiveRecord::Base.connection.execute(sql)

   ret.check
   puts ret.cmd_status
   number_of_records = ret.cmd_tuples
   puts number_of_records

   Dir.chdir(dir_path)

   puts "Files delete from archive"
   cmd = "rm -rf *"
   system(cmd)


   Dir.chdir(prevDir)

   exit(0)

end
#---------------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================

