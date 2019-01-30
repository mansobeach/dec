#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #MINARC_API class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# Git: MINARC_API.rb,v $Id$
#
# module MINARC
#
#########################################################################

module ARC
   API_URL_VERSION            = '/dec/arc/version'
   API_URL_STORE              = '/dec/arc/minArcStore'
   API_URL_RETRIEVE           = '/dec/arc/minArcRetrieve'
   API_URL_LIST_FILENAME      = '/dec/arc/minArcList/filename'
   API_URL_LIST_FILETYPE      = '/dec/arc/minArcList/filetype'
   API_URL_DELETE             = '/dec/arc/minArcDelete'
   API_URL_GET_FILETYPES      = '/dec/arc/filetypes'
   API_URL_STAT_FILENAME      = '/dec/arc/minArcStatFileName.json/filename'
   API_URL_STAT_FILETYPES     = '/dec/arc/minArcStatFileType.json'
   API_URL_STAT_GLOBAL        = '/dec/arc/minArcStatGlobal.json'
   API_RESOURCE_NOT_FOUND     = 404
   API_RESOURCE_FOUND         = 200
end
