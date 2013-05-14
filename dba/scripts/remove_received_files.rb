#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for remove_received_file.rb
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Data Collector Component
# 
# CVS:
#  $Id: remove_received_files.rb,v 1.2 2008/04/02 08:49:23 decdev Exp $
#
#########################################################################

require "dbm/DatabaseModel"

# Remove all received files without destroying the table
ReceivedFile.delete_all
exit(0)
