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

sql = "update ARCHIVED_FILES set filetype='MONTHLY_STATS_TEMPERATURE-OUTDOOR_XLS_CASALE' where filetype='MONTHLY_STATS_TEMPER' and filename like '%.xls'"


ActiveRecord::Base.connection.execute(sql)

