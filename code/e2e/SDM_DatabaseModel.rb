#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #SDM_DatabaseModel class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === E2E
# 
# CVS: $Id: SDM_DatabaseModel.rb,v 1.12 2008/10/10 16:18:30 decdev Exp $
#
# module E2E
#
#########################################################################

# $> psql -d sdmdb -U sdm_db_e2espm
# psql 
# select * from information_schema.tables ;

require 'rubygems'
require 'active_record'
require 'activerecord-import'

dbAdapter   = ENV['SDM_DB_ADAPTER']
dbName      = ENV['SDM_DATABASE_NAME']
dbUser      = ENV['SDM_DATABASE_USER']
dbPass      = ENV['SDM_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(
                                          :adapter    => dbAdapter,
                                          :host       => "localhost", 
                                          :database   => dbName,
                                          :username   => dbUser, 
                                          :password   => dbPass, 
                                          :timeout    => 10000,
                                          :cast       => false
                                          )


#=====================================================================

class DimSignatureTB < ActiveRecord::Base
   self.table_name = "dim_signature_tb"
   validates_uniqueness_of :dim_signature
   validates_presence_of   :active_flag, :dim_exec_name
end

#=====================================================================

class AnnotGroupConfTB < ActiveRecord::Base
   self.table_name = "annot_group_cnf_tb"
   validates_uniqueness_of :group_id
   validates_presence_of   :name
end

#=====================================================================

#=====================================================================

class AnnotConfTB < ActiveRecord::Base
   self.table_name = "annot_cnf_tb"
   validates_uniqueness_of :annotation_id
   validates_presence_of   :name, :dim_signature, :value_type, :expl_ref_cnf_id, :group_id
end

#=====================================================================

#=====================================================================

class ExplicitReferenceConfTB < ActiveRecord::Base
   self.table_name = "explicit_ref_cnf_tb"
   validates_uniqueness_of :expl_ref_cnf_id
   validates_presence_of   :name, :dim_signature
end

#=====================================================================

#-----------------------------------------------------------


