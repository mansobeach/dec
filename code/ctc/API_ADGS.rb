#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #API_ADGS class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: API_ADGS.rb,v $Id$
###
### module ADGS
###
#########################################################################

## URL Percent Encoding
## https://en.wikipedia.org/wiki/Percent-encoding
### %27 => '
### %24 => $ This one must be escaped with curl

module ADGS
   
   API_SERVER                             = 'https://185.52.193.141:4567'    
   API_ROOT                               = 'https://185.52.193.141:4567/adgs'

   API_TEST_SERVER                        = 'https://localhost:4567'    
   API_TEST_ROOT                          = 'https://localhost:4567/adgs'
   
    
   API_URL_ODATA_PRODUCT_PAGING     =\
    "#{API_ROOT}/odata/v1/Products?$orderby=PublicationDate asc&$format=json&$select=Name,Id,IngestionDate,PublicationDate,Online,ContentLength,EvictionDate,ContentDate&$top=50&$skip="
    
   API_URL_ODATA_PRODUCT_SELECT_ID  =\
    "#{API_ROOT}/odata/v1/Products?$orderby=PublicationDate asc&$format=json&$select=Name,Id,IngestionDate,PublicationDate,Online,ContentLength,EvictionDate,ContentDate"

   API_URL_ODATA_PRODUCT_COUNT      = "#{API_ROOT}/odata/v1/Products?$count=true"


   API_URL_ODATA_PRODUCT_SELECT_BY_SENSING =\
    "#{API_ROOT}/odata/v1/Products?$orderby=ContentDate/Start asc&$format=json&$select=Name,Id,IngestionDate,PublicationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry"

   API_URL_ODATA_PRODUCT_PAGING_BY_SENSING =\
    "#{API_ROOT}/odata/v1/Products?$orderby=ContentDate/Start asc&$format=json&$select=Name,Id,IngestionDate,PublicationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="

   API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_CSV =\
    "#{API_ROOT}/odata/v1/Products?$orderby=ContentDate/Start asc&$format=text/csv&$select=Name,Id,IngestionDate,PublicationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry"
   API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_CSV =\
    "#{API_ROOT}/odata/v1/Products?$orderby=ContentDate/Start asc&$format=text/csv&$select=Name,Id,IngestionDate,PublicationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="

   API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_XML =\
    "#{API_ROOT}/odata/v1/Products?$orderby=ContentDate/Start asc&$format=xml&$select=Name,Id,IngestionDate,PublicationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry"
   API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_XML =\
    "#{API_ROOT}/odata/v1/Products?$orderby=ContentDate/Start asc&$format=xml&$select=Name,Id,IngestionDate,PublicationDate,Online,ContentLength,EvictionDate,ContentDate,ContentGeometry&$top=50&$skip="

   API_ODATA_ATTRIBUTE_DATE_AVAILABILITY = "PublicationDate"
  
   API_ODATA_FILTER_SUBSTRINGOF     = "&$filter=contains"
   API_ODATA_FILTER_ENDSWITH        = "&$filter=endswith"
   
   API_ODATA_ORDERBY_ASC            = "&$filter=IngestionDate gt datetime'2021-03-24T00:00:00.000'"
   
   API_ODATA_FILTER_INGESTIONDATE   = "&$filter=IngestionDate gt datetime'2021-03-24T00:00:00.000'"
   
   API_ODATA_FILTER_VALIDITY        = "&$filter=ContentDate/Start ge datetime '2021-03-24T00:00:00.000 and ContentDate/End le datetime'2021-03-25T00:00:00.000'"
   
   API_RESOURCE_FOUND               = "200"
   API_TOP_LIMIT_ITEMS              = 50
end
