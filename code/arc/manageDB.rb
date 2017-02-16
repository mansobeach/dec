#!/usr/bin/env ruby

#
# == Usage
# manageDB.rb --create-tables | --drop-tables
#     --create-tables   create all minarc required tables
#     --drop-tables     drops all minarc tables
#     --help   shows this help
# 
# == Author
# DEIMOS-Space S.L.
#
# == Copyright
# Copyright (c) 2008 ESA - DEIMOS Space S.L.
#
require 'rubygems'
require 'active_record'

require 'getoptlong'
require 'rdoc'

require 'minarc/MINARC_Migrations'

dbAdapter   = ENV['MINARC_DB_ADAPTER']
dbName      = ENV['MINARC_DATABASE_NAME']
dbUser      = ENV['MINARC_DATABASE_USER']
dbPass      = ENV['MINARC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(:adapter => dbAdapter,
         :host => "localhost", :database => dbName,
         :username => dbUser, :password => dbPass)


# MAIN script function
def main

   bUp   = false
   bDown = false
   
   opts = GetoptLong.new(
     ["--drop-tables",   "-d",    GetoptLong::NO_ARGUMENT],
     ["--create-tables", "-c",    GetoptLong::NO_ARGUMENT],
     ["--help", "-h",             GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--create-tables"    then @bUp   = true
            when "--drop-tables"      then @bDown = true
			   when "--help"             then usage
         end
      end
   rescue Exception => e
      puts e.to_s
      exit(99)
   end

   if @bDown and @bUp then
      usage
   end

   if @bDown then
      CreateArchivedFiles.down
      exit(0)
   end

   if @bUp then
      CreateArchivedFiles.up
      exit(0)
   end
 
   exit(0)

end

#-------------------------------------------------------------

def usage
   fullpathFile = `which #{File.basename($0)}` 
   system("head -15 #{fullpathFile}")
   exit
end

#-------------------------------------------------------------


#=====================================================================
# Start of the main body
main
# End of the main body
#=====================================================================
