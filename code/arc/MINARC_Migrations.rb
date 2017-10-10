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
         t.column :filetype,            :string,  :limit => 64
         t.column :path,                :string,  :limit => 255
         t.column :info,                :string,  :limit => 255
         t.column :size,                :integer
         t.column :size_in_disk,        :integer
         t.column :size_original,       :integer
         t.column :detection_date,      :datetime
         t.column :validity_start,      :datetime
         t.column :validity_stop,       :datetime
         t.column :archive_date,        :datetime
         t.column :last_access_date,    :datetime
         t.column :access_counter,      :integer, default: 0, null: false
         # t.column :deleted              :boolean, default: false, null: false
      end

#        change_column :archived_files, :filetype, :string, :limit => 64

   end

   def self.down
      drop_table :archived_files
   end
end

#=====================================================================

class AddNewColumns < ActiveRecord::Migration

  def change
     # size_original of the file before archive in bytes
     add_column :archived_files, :size_original, :integer, {:default=>0, :null=>true}
  end


  def change_20170301
     # size of the file in bytes
     add_column :archived_files, :size, :integer, {:default=>0, :null=>true}
     add_column :archived_files, :size_in_disk, :integer, {:default=>0, :null=>true}
     add_column :archived_files, :access_counter, :integer, {:default=>0, :null=>true}
  end
end

#=====================================================================

class Export2CSV
   #-------------------------------------------------------------   
   
   # Class contructor
   def initialize
      checkModuleIntegrity
   end
   #-------------------------------------------------------------

   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "Export2CSV debug mode is on"
   end
   #-------------------------------------------------------------

private


   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      
      if !ENV['MINARC_ARCHIVE_ROOT'] then
         puts
         puts "MINARC_ARCHIVE_ROOT environment variable is not defined !\n"
         bDefined = false
      end

      if bCheckOK == false or bDefined == false then
         puts("FileRetriever::checkModuleIntegrity FAILED !\n\n")
         exit(99)
      end

      @archiveRoot = ENV['MINARC_ARCHIVE_ROOT']
      return
   end
   #-------------------------------------------------------------


end

#=====================================================================
