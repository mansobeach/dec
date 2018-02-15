#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileArchiver class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: MINARC_API.rb,v 1.12 2008/09/24 16:09:19 decdev Exp $
#
# module MINARC
#
#########################################################################

module ARC
   def load_config_development
      ENV['MINARC_VERSION']         = "01.00.00"
      ENV['MINARC_BASE']            = "#{ENV['HOME']}/Projects/dec"
      ENV['MINARC_ARCHIVE_ROOT']    = "#{ENV['HOME']}/Sandbox/minarc/archive_root"
      ENV['MINARC_ARCHIVE_ERROR']   = "#{ENV['HOME']}/Sandbox/minarc/load"
      ENV['MINARC_DATABASE_NAME']   = "#{ENV['HOME']}/Sandbox/minarc/inv/minarc_inventory.db"
   end
end
