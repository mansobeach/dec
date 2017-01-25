#!/usr/bin/env ruby

#
# == Usage
# manageDB.rb --create-tables | --drop-tables
#     --create-tables   create all minarc required tables
#     --drop-tables     drops all minarc tables
#     --Debug     shows Debug info during the execution
#     --help   shows this help
# 
# == Author
# Borja Lopez Fernandez
#
# == Copyright
# Copyleft (c) 2013 Casale & Beach
#

require 'getoptlong'
# require 'rdoc/usage'

require 'rubygems'
require 'active_record'

require 'dcc/DCC_Migrations'

@isDebugMode = false

dbAdapter   = ENV['DCC_DB_ADAPTER']
dbName      = ENV['DCC_DATABASE_NAME']
dbUser      = ENV['DCC_DATABASE_USER']
dbPass      = ENV['DCC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(:adapter => dbAdapter,
         :host => "localhost", :database => dbName,
         :username => dbUser, :password => dbPass)


# MAIN script function
def main

   dbAdapter   = ENV['DCC_DB_ADAPTER']
   dbName      = ENV['DCC_DATABASE_NAME']
   dbUser      = ENV['DCC_DATABASE_USER']
   dbPass      = ENV['DCC_DATABASE_PASSWORD']

   bUp            = false
   bDown          = false
   @bUpdate       = false
   
   opts = GetoptLong.new(
     ["--drop-tables",   "-d",    GetoptLong::NO_ARGUMENT],
     ["--create-tables", "-c",    GetoptLong::NO_ARGUMENT],
     ["--update-tables", "-u",    GetoptLong::NO_ARGUMENT],
     ["--Debug", "-D",            GetoptLong::NO_ARGUMENT],
     ["--help", "-h",             GetoptLong::NO_ARGUMENT]
     )
    
   begin
      opts.each do |opt, arg|
         case opt
            when "--Debug"             then @isDebugMode = true      
            when "--create-tables"     then @bUp         = true
            when "--drop-tables"       then @bDown       = true
            when "--update-tables"     then @bUpdate     = true
			   when "--help"              then usage
         end
      end
   rescue Exception => e
      puts e.to_s
      exit(99)
   end

   if @bDown and @bUp then
      usage
   end

   if @isDebugMode == true then
      puts "----------------"
      puts dbAdapter
      puts dbName
      puts dbUser
      puts dbPass
      puts "----------------"
   end

   if @bUpdate then
      migration = AddSizeToReceivedFiles.new
      migration.change
      exit(0)
   end

   if @bDown then
      CreateReceivedFiles.down
      CreateTrackedFiles.down
      CreateInterfaces.down
      exit(0)
   end

   if @bUp then
      CreateInterfaces.up
      CreateTrackedFiles.up
      CreateReceivedFiles.up
      exit(0)
   end

   usage
 
   exit(0)

end

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -15 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
   exit   
end
#-------------------------------------------------------------


#=====================================================================
# Start of the main body
main
# End of the main body
#=====================================================================
