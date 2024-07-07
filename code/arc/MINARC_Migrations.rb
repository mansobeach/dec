#!/usr/bin/env ruby

require 'rubygems'
require 'active_record'

@dbAdapter   = ENV['MINARC_DB_ADAPTER']
@dbHost      = ENV['MINARC_DATABASE_HOST']
@dbPort      = ENV['MINARC_DATABASE_PORT']
@dbName      = ENV['MINARC_DATABASE_NAME']
@dbUser      = ENV['MINARC_DATABASE_USER']
@dbPass      = ENV['MINARC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(  
                                          :adapter    => @dbAdapter, \
                                          :host       => @dbHost, \
                                          :database   => @dbName, \
                                          :port       => @dbPort, \
                                          :username   => @dbUser, \
                                          :password   => @dbPass, \
                                          :timeout    => 100000, \
                                          :cast       => false, \
                                          :pool       => 10
                                          )

## =====================================================================

class CreateUsers < ActiveRecord::Migration[6.0]
   def self.up
      create_table(:users) do |t|
         t.column :name,                :string,  :limit => 255, :unique => true
         t.column :password_digest,     :string
         t.column :created_at,          :datetime
         t.column :updated_at,          :datetime
      end
   end

   def self.down
      drop_table :users
   end

end

## =====================================================================

class CreateServedFiles < ActiveRecord::Migration[6.0]
   def self.up
   
      create_table(:served_files) do |t|
         t.column :username,            :string,  :limit => 255
         t.index  :username
         t.column :filename,            :string,  :limit => 255
         t.column :file_id,             :uuid
         t.column :size,                :bigint
         t.column :ip,                  :string,  :limit => 64
         t.column :download_elapsed,    :float
         t.column :download_date,       :datetime
         t.index  :download_date
      end
   end

   def self.down
      drop_table :served_files
   end

end

## =====================================================================

class CreateArchivedFiles < ActiveRecord::Migration[6.0]     
   def self.up
   
      if ENV['MINARC_DB_ADAPTER'] == "postgresql" then
         enable_extension 'pgcrypto'
         enable_extension 'uuid-ossp'
      end

      create_table(:archived_files) do |t|
         t.column :uuid,                :uuid,  default: "uuid_generate_v4()", null: false, :unique => true
         t.index  :uuid,                 unique: true
         # filename includes the file extension
         t.column :filename,            :string,  :limit => 255, :unique => true
         t.index  :filename,             unique: true
         # name to be the filename without extension
         t.column :filename_original,   :string,  :limit => 255
         t.column :name,                :string,  :limit => 255, :unique => true
         t.index  :name,                 unique: true
         t.column :filetype,            :string,  :limit => 64
         t.column :path,                :string,  :limit => 255
         t.column :info,                :string,  :limit => 255
         t.column :size,                :bigint
         t.column :size_in_disk,        :bigint
         t.column :size_original,       :bigint
         t.column :md5,                 :string,  :limit => 32
         t.column :detection_date,      :datetime
         t.column :validity_start,      :datetime
         t.column :validity_stop,       :datetime
         t.column :archive_date,        :datetime
         t.column :last_access_date,    :datetime
         t.column :access_counter,      :bigint, default: 0, null: false
         t.column :json_metadata,       :jsonb, null: true
         # t.column :deleted              :boolean, default: false, null: false
      end
   end

   def self.down
      drop_table :archived_files
   end
end

## ===================================================================

class AddNewColumns < ActiveRecord::Migration[6.0]

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
  
  def change_20181216
     add_column :archived_files, :name, :string, {:limit=>255, :null=>true}
     add_index :archived_files, :name
  end
    
end

## ===================================================================

class AddIndexFilename < ActiveRecord::Migration[6.0]
   def change
      add_index :archived_files, :filename
   end
end

## ===================================================================

class AddIndexName < ActiveRecord::Migration[6.0]
   def change
      add_index :archived_files, :name
   end
end

## ===================================================================

class ModifySizeColumns < ActiveRecord::Migration[6.0]
   def change
      change_column :archived_files, :size,           :bigint
      change_column :archived_files, :size_in_disk,   :bigint
      change_column :archived_files, :size_original,  :bigint
      change_column :archived_files, :access_counter, :bigint
   end
end

## ===================================================================

class Add_version_1_1 < ActiveRecord::Migration[6.0]
  def change
     if ENV['MINARC_DB_ADAPTER'] == "postgresql" then
        enable_extension 'pgcrypto'
        enable_extension 'uuid-ossp'
     end
     ## ADD does not work since there is already a primary key
     ## execute "ALTER TABLE archived_files ADD PRIMARY KEY (uuid);"
     ## For the time being native ActiveRecord/Rails "id" PK is kept
     begin
        add_column :archived_files, :uuid, :uuid, default: "uuid_generate_v4()", null: false, :unique => true
        add_index  :archived_files, :uuid
     rescue Exception => e
        puts e.to_s
     end
     
     begin
        add_column :archived_files, :md5, :string, :limit => 32
     rescue Exception => e
        puts e.to_s
     end
  end

end

## ===================================================================

class Add_version_1_2 < ActiveRecord::Migration[6.0]
  def change
     begin
        add_column :archived_files, :filename_original, :string,  :limit => 255, null: true, :unique => false
     rescue Exception => e
        puts e.to_s
     end
  end
end

## ===================================================================

class Export2CSV
   ## -----------------------------------------------------------
   
   ## Class contructor
   def initialize
      checkModuleIntegrity
   end
   ## -----------------------------------------------------------

   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "Export2CSV debug mode is on"
   end
   ## -----------------------------------------------------------

private


   ## -----------------------------------------------------------
   
   ## Check that everything needed by the class is present.
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
   ## -----------------------------------------------------------


end

## ===================================================================
