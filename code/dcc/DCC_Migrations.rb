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


dbAdapter   = ENV['DCC_DB_ADAPTER']
dbName      = ENV['DCC_DATABASE_NAME']
dbUser      = ENV['DCC_DATABASE_USER']
dbPass      = ENV['DCC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(:adapter => dbAdapter,
         :host => "localhost", :database => dbName,
         :username => dbUser, :password => dbPass)

#=====================================================================

class CreateTrackedFiles < ActiveRecord::Migration
   def self.up
      create_table(:tracked_files) do |t|
         t.column :filename,            :string,  :limit => 255
         t.column :interface_id,        :integer
         t.column :tracking_date,       :datetime
      end
   end

   def self.down
      drop_table :tracked_files
   end
end

#=====================================================================

class CreateReceivedFiles < ActiveRecord::Migration
   def self.up
      create_table(:received_files) do |t|
         t.column :filename,            :string,  :limit => 255
         t.column :interface_id,        :integer
         t.column :reception_date,       :datetime
         t.column :delivered_using,     :string,  :limit => 64
      end
   end

   def self.down
      drop_table :received_files
   end
end


#=====================================================================

class CreateInterfaces < ActiveRecord::Migration
   def self.up
      create_table(:interfaces) do |t|
         t.column :name,                :string,  :limit => 255
         t.column :description,         :string,  :limit => 255
      end
   end

   def self.down
      drop_table :interfaces
   end
end

#=====================================================================
