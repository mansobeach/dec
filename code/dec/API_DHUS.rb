#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #MINARC_API class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: API_DHUS.rb,v $Id$
###
### module DHUS
###
#########################################################################

## https://scihub.copernicus.eu/userguide/ODataAPI
## > https://scihub.copernicus.eu/dhus/odata/v1/Products?$select=Name,CreationDate,IngestionDate,Online,ContentDate
##
## OData https://scihub.copernicus.eu/apihub/odata/v1

## URL Percent Encoding
## https://en.wikipedia.org/wiki/Percent-encoding
### %27 => '
### %24 => $ This one must be escaped with curl

module DHUS
   # API_URL_ODATA_PRODUCT_PAGING     = "https://scihub.copernicus.eu/dhus/odata/v1/Products?$skip=50&$top=50"
   # API_URL_ODATA_PRODUCT_PAGING     = "https://scihub.copernicus.eu/dhus/odata/v1/Products?$top=50&$skip="
   API_URL_ODATA_PRODUCT_PAGING     =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$select=Id,Online,ContentLength,CreationDate,IngestionDate,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="
   API_URL_ODATA_PRODUCT_SELECT_ID  =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$select=Id,Online,ContentLength,CreationDate,IngestionDate,EvictionDate,ContentDate,ContentGeometry"
   # API_URL_ODATA_PRODUCT_SELECT_ID  = "https://scihub.copernicus.eu/dhus/odata/v1/Products?$select=*"
   API_URL_ODATA_PRODUCT_COUNT      = "https://scihub.copernicus.eu/dhus/odata/v1/Products/$count?"
   API_ODATA_FILTER_SUBSTRINGOF     = "&$filter=substringof"
   API_ODATA_FILTER_ENDSWITH        = "&$filter=endswith"
   API_RESOURCE_FOUND               = "200"
   API_TOP_LIMIT_ITEMS              = 50
end
