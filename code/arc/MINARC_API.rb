#!/usr/bin/env ruby

module ARC
   API_URL_VERSION               = '/dec/arc/version'
   API_URL_STORE_OLD             = '/OLD/dec/arc/minArcStore'
   
   ### -------------------------------------------
   ### Used by DEC Events:
   ### <Event Name="OnReceiveNewFilesOK" 
   ###   executeCmd="curl -u dec:dec https://185.52.193.141:4567/dec/arc/requestArchive/*"/>

   API_URL_REQUEST_ARCHIVE       = '/dec/arc/requestArchive/:name'
   ### -------------------------------------------
   
   API_URL_STORE                 = '/dec/arc/minArcStore'
   API_URL_RETRIEVE              = '/dec/arc/minArcRetrieve'
   API_URL_RETRIEVE_CONTENT      = '/dec/arc/file'
   API_URL_LIST_FILENAME         = '/dec/arc/minArcList/filename'
   API_URL_LIST_FILETYPE         = '/dec/arc/minArcList/filetype'
   API_URL_DELETE                = '/dec/arc/minArcDelete'
   API_URL_GET_FILETYPES         = '/dec/arc/filetypes'
   API_URL_STAT_FILENAME         = '/dec/arc/minArcStatFileName.json'
   API_URL_STAT_FILETYPES        = '/dec/arc/minArcStatFileType.json'
   API_URL_STAT_GLOBAL           = '/dec/arc/minArcStatGlobal.json'
   API_RESOURCE_NOT_FOUND        = 404
   API_RESOURCE_FOUND            = 200
   API_RESOURCE_CREATED          = 201
   API_RESOURCE_DELETED          = 200
   API_RESOURCE_ERROR            = 500
end

