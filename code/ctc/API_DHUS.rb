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

   API_ROOT = "https://scihub.copernicus.eu/dhus"

   API_URL_ODATA_PRODUCT_PAGING     =\
    "#{API_ROOT}/odata/v1/Products?$format=xml&$select=Id,Online,ContentLength,CreationDate,IngestionDate,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="
   API_URL_ODATA_PRODUCT_SELECT_ID  =\
    "#{API_ROOT}/odata/v1/Products?$format=xml&$select=Id,Online,ContentLength,CreationDate,IngestionDate,EvictionDate,ContentDate,ContentGeometry"
    
   API_URL_ODATA_PRODUCT_PAGING_S1     =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$orderby=CreationDate asc&$format=xml&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="

   API_URL_ODATA_PRODUCT_PAGING_GNSS   =\
    "https://scihub.copernicus.eu/gnss/odata/v1/Products?$orderby=CreationDate asc&$format=xml&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="
    
   API_URL_ODATA_PRODUCT_SELECT_ID_S1  =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$orderby=CreationDate asc&$format=xml&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry"

   API_URL_ODATA_PRODUCT_SELECT_ID_GNSS  =\
    "https://scihub.copernicus.eu/gnss/odata/v1/Products?$orderby=CreationDate asc&$format=xml&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry"


   API_URL_ODATA_PRODUCT_PAGING_S1_CSV    =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$orderby=CreationDate asc&$format=text/csv&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="
   API_URL_ODATA_PRODUCT_SELECT_ID_S1_CSV  =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$orderby=CreationDate asc&$format=text/csv&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry"
   API_URL_ODATA_PRODUCT_PAGING_S1_JSON    =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$orderby=CreationDate asc&$format=json&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="
   API_URL_ODATA_PRODUCT_SELECT_ID_S1_JSON  =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$orderby=CreationDate asc&$format=json&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry"

   API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_NOT_SORT  =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$format=json&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry"

   API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_NOT_SORT     =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$format=json&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="

   API_URL_ODATA_PRODUCT_SELECT_BY_SENSING =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$orderby=ContentDate/Start asc&$format=xml&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry"

   API_URL_ODATA_PRODUCT_PAGING_BY_SENSING =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$orderby=ContentDate/Start asc&$format=xml&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="

   API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_CSV =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$orderby=ContentDate/Start asc&$format=text/csv&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry"
   API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_CSV =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$orderby=ContentDate/Start asc&$format=text/csv&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="

   API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_JSON =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$orderby=ContentDate/Start asc&$format=json&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry"
   API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_JSON =\
    "https://scihub.copernicus.eu/dhus/odata/v1/Products?$orderby=ContentDate/Start asc&$format=json&$select=Name,Id,IngestionDate,CreationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="

   API_ODATA_ATTRIBUTE_DATE_AVAILABILITY = "CreationDate"


   # API_URL_ODATA_PRODUCT_SELECT_ID  = "https://scihub.copernicus.eu/dhus/odata/v1/Products?$select=*"
   API_URL_ODATA_PRODUCT_COUNT      = "https://scihub.copernicus.eu/dhus/odata/v1/Products/$count?"

   API_URL_ODATA_PRODUCT_COUNT_GNSS = "https://scihub.copernicus.eu/gnss/odata/v1/Products/$count?"
   
   API_ODATA_FILTER_SUBSTRINGOF     = "&$filter=substringof"
   
   API_ODATA_FILTER_ENDSWITH        = "&$filter=endswith"
   
   API_ODATA_ORDERBY_ASC            = "&$filter=IngestionDate gt datetime'2021-03-24T00:00:00.000'"
   
   API_ODATA_FILTER_INGESTIONDATE   = "&$filter=IngestionDate gt datetime'2021-03-24T00:00:00.000'"

   ## https://scihub.copernicus.eu/dhus/odata/v1/Products?$filter=year(IngestionDate) eq 2017 and month(IngestionDate) eq 12
   
   API_ODATA_FILTER_VALIDITY        = "&$filter=ContentDate/Start ge datetime '2021-03-24T00:00:00.000 and ContentDate/End le datetime'2021-03-25T00:00:00.000'"
   
   API_RESOURCE_FOUND               = "200"
   API_TOP_LIMIT_ITEMS              = 50
end
