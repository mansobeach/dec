#!/usr/bin/env ruby


#########################################################################
#
# Ruby source for #ROPSender class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Mission Management & Planning Facility
# 
# git:
#   RPF_Migrations.rb,v $Date$ $Id$  decdev Exp $
#
#########################################################################

require 'rubygems'

require 'active_record'


#=====================================================================

class CreateInventoryParams < ActiveRecord::Migration[5.1]
   def self.up
      create_table(:PARAMETERS_TB) do |t|
         t.column :KEYWORD,            :string,  :limit => 255
         t.column :VALUE,              :string,  :limit => 255
      end
   end

   def self.down
      drop_table :PARAMETERS_TB
   end
end

#=====================================================================

class CreateInventoryROP < ActiveRecord::Migration[5.1]
   def self.up
      create_table(:ROP_TB) do |t|
         t.column :ROP_ID,                      :integer
         t.column :TRANSFERABILITY,             :integer
         t.column :STATUS,                      :integer
      end
   end

   def self.down
      drop_table :ROP_TB
   end
end

#=====================================================================

#=====================================================================

class CreateInventoryFile < ActiveRecord::Migration[5.1]
   def self.up
      create_table(:FILE_TB) do |t|
         t.column :FILE_ID,            :integer
         t.column :FILENAME,           :string,  :limit => 255
      end
   end

   def self.down
      drop_table :FILE_TB
   end
end

#=====================================================================

#=====================================================================

class CreateInventoryROPFile < ActiveRecord::Migration[5.1]
   def self.up
      create_table(:FILE_ROP_TB) do |t|
         t.column :ROP_ID,                      :integer
         t.column :FILE_ID,                     :integer
      end
   end

   def self.down
      drop_table :FILE_ROP_TB
   end
end

#=====================================================================


#=====================================================================

class CreateInventoryROPFileView < ActiveRecord::Migration[5.1]
   def self.up
      create_table(:ROP_FILE_VW) do |t|
         t.column :CURRENT_ROP,              :integer
         t.column :FILE_ID,                  :integer
         t.column :TYPE_ID,                  :integer
         t.column :FILENAME,                 :string,  :limit => 255
         t.column :STATUS,                   :integer
      end
   end

   def self.down
      drop_table :ROP_FILE_VW
   end
end

#=====================================================================

