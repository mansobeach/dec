#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #remove_dec_tables executable
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Data Distributor Component
# 
# CVS:
#  $Id: remove_tables_dec.rb,v 1.1 2007/12/17 15:40:34 decdev Exp $
#
#########################################################################

decuser = ENV['DCC_DATABASE_USER']
decpass = ENV['DCC_DATABASE_PASSWORD']

# DCC Tables

cmd = "sqlplus #{decuser}/#{decpass} @ ../deletion/dcc/delete_received_files_seq.sql"
system(cmd)

cmd = "sqlplus #{decuser}/#{decpass} @ ../deletion/dcc/delete_received_files.sql"
system(cmd)

cmd = "sqlplus #{decuser}/#{decpass} @ ../deletion/dcc/delete_tracked_files_seq.sql"
system(cmd)

cmd = "sqlplus #{decuser}/#{decpass} @ ../deletion/dcc/delete_tracked_files.sql"
system(cmd)

# DDC Tables

cmd = "sqlplus #{decuser}/#{decpass} @ ../deletion/ddc/delete_sent_files_seq.sql"
system(cmd)

cmd = "sqlplus #{decuser}/#{decpass} @ ../deletion/ddc/delete_sent_files.sql"
system(cmd)

# Common Tables

cmd = "sqlplus #{decuser}/#{decpass} @ ../deletion/common/delete_interfaces_seq.sql"
system(cmd)

cmd = "sqlplus #{decuser}/#{decpass} @ ../deletion/common/delete_interfaces.sql"
system(cmd)

