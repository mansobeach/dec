#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for remove_tracked_files.rb
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Data Collector Component
# 
# CVS:
#  $Id: remove_tracked_files.rb,v 1.2 2008/04/02 08:49:23 decdev Exp $
#
#########################################################################

require "dbm/DatabaseModel"

# Remove all tracked files without destroying the table
TrackedFile.delete_all
exit(0)
