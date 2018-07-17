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
   API_URL_VERSION            = '/dec/arc/version'
   API_URL_STORE              = '/dec/arc/minArcStore'
   API_URL_RETRIEVE           = '/dec/arc/minArcRetrieve'
   API_URL_LIST               = '/dec/arc/minArcList'
   API_URL_DELETE             = '/dec/arc/minArcDelete'
   API_RESOURCE_NOT_FOUND     = 404
   API_RESOURCE_FOUND         = 200
end
