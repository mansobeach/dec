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


dbAdapter   = ENV['MINARC_DB_ADAPTER']
dbName      = ENV['MINARC_DATABASE_NAME']
dbUser      = ENV['MINARC_DATABASE_USER']
dbPass      = ENV['MINARC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(:adapter => dbAdapter,
         :host => "localhost", :database => dbName,
         :username => dbUser, :password => dbPass)

#=====================================================================

class CreateArchivedFiles < ActiveRecord::Migration
   def self.up
      create_table(:archived_files) do |t|
         t.column :filename,            :string,  :limit => 255
         t.column :filetype,            :string,  :limit => 20
         t.column :path,                :string,  :limit => 255
         t.column :detection_date,      :datetime
         t.column :validity_start,      :datetime
         t.column :validity_stop,       :datetime
         t.column :archive_date,        :datetime
         t.column :last_access_date,    :datetime
      end
   end

   def self.down
      drop_table :archived_files
   end
end

#=====================================================================
