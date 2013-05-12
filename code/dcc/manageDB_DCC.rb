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
# Copyright (c) 2013 Casale & Beach
#

require 'getoptlong'
require 'rdoc/usage'

require "rubygems"
require "active_record"

require 'dcc/DCC_Migrations'

dbAdapter   = ENV['DCC_DB_ADAPTER']
dbName      = ENV['DCC_DATABASE_NAME']
dbUser      = ENV['DCC_DATABASE_USER']
dbPass      = ENV['DCC_DATABASE_PASSWORD']

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
			   when "--help"             then RDoc::usage
         end
      end
   rescue Exception => e
      puts e.to_s
      exit(99)
   end

   if @bDown and @bUp then
      RDoc::usage("usage")
   end

   if @bDown then
      CreateTrackedFiles.down
      CreateInterfaces.down
      exit(0)
   end

   if @bUp then
      CreateInterfaces.up
      CreateTrackedFiles.up
      exit(0)
   end

   RDoc::usage("usage")
 
   exit(0)

end

#=====================================================================
# Start of the main body
main
# End of the main body
#=====================================================================
