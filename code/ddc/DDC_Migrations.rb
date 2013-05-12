#!/usr/bin/env ruby

# === Written by Casale-Beach

require "rubygems"
require "active_record"
#require "migration_helper"

dbAdapter   = ENV['DEC_DB_ADAPTER']
dbName      = ENV['DCC_DATABASE_NAME']
dbUser      = ENV['DCC_DATABASE_USER']
dbPass      = ENV['DCC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(:adapter => dbAdapter,
         :host => "localhost", :database => dbName,
         :username => dbUser, :password => dbPass)

#=====================================================================

class CreateInterfaces < ActiveRecord::Migration
   def self.up
      create_table(:interfaces) do |t|
         t.column :name,                :string,  :limit => 100
      end
   end

   def self.down
      drop_table :interfaces
   end
end

#=====================================================================

class CreateSentFiles < ActiveRecord::Migration

   def self.up
      create_table(:sent_files) do |t|
         t.column :filename,         :string,  :limit => 255
         t.column :interface,        :string,  :limit => 100
         t.column :delivered_using,  :string,  :limit => 100
         t.column :delivery_date,    :datetime
      end
   end

   def self.down
      drop_table :sent_files
   end
end

#=====================================================================
