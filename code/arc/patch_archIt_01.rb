#!/usr/bin/env ruby

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
require 'active_record'
require 'arc/MINARC_DatabaseModel'

dbAdapter   = ENV['MINARC_DB_ADAPTER']
dbName      = ENV['MINARC_DATABASE_NAME']
dbUser      = ENV['MINARC_DATABASE_USER']
dbPass      = ENV['MINARC_DATABASE_PASSWORD']
archRoot    = ENV['MINARC_ARCHIVE_ROOT']

ActiveRecord::Base.establish_connection(:adapter => dbAdapter,
         :host => "localhost", :database => dbName,
         :username => dbUser, :password => dbPass)


arrFiles = ArchivedFile.find(:all)

arrFiles.each{|aFile|

#    puts aFile.filename
#    puts aFile.path
#    exit
   aPath = "#{archRoot}/#{aFile.path}"
   aFile.path = aPath
   aFile.save

}
