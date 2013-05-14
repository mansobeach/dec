#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for remove_sent_files.rb
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Data Distributor Component
# 
# CVS:
#  $Id: remove_sent_files.rb,v 1.1 2008/04/02 08:49:23 decdev Exp $
#
#########################################################################

require "dbm/DatabaseModel"

# Remove all sent files without destroying the table
SentFile.delete_all
exit(0)
