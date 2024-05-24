#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #MINARC_API_OData class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Mini Archive Component (MinArc)
###
### Git: MINARC_API_OData.rb,v $Id$
###
### module MINARC
###
#########################################################################

### SPRs
## JSON status with backslash quotes
## HTTP HEAD to be tested
## curl -u test:test --head '185.52.193.141:4567/odata/v1/Products(60c4b746-711b-4f7d-81cd-51cf2330d19a)/$value'

### https://docs.oasis-open.org/odata/odata/v4.01/odata-v4.01-part1-protocol.html
### https://docs.oasis-open.org/odata/odata/v4.01/cos01/part2-url-conventions/odata-v4.01-cos01-part2-url-conventions.pdf


### Compliance to "Auxiliary Data Interface Delivery Point Specification"
###
### ESA-EOPG-EOPGC-IF-10 version 1.1
###

### Section 3.3 Query Products Catalogue

### Section 3.3.1 Query Products
## The main query possibilities are outlined below, filter conditions may be combined.

### Section 3.3.1.1 Query by Name / support of string functions contains, endswith, startswith
## https://<service-root-uri>/odata/v1/Products?$filter=startswith(Name,'S2') => OK
## https://<service-root-uri>/odata/v1/Products?$filter=contains(Name,'S2__OPER_AUX_UT1UTC') => OK
## https://<service-root-uri>/odata/v1/Products?$filter=endswith(Name,'21000101T000001') => OK

### Section 3.3.1.2 Query by Product Publication Date => OK
## https://<service-root-uri>/odata/v1/Products?$filter=PublicationDate gt 2020-05-15T00:00:00.000Z

### Section 3.3.1.3 Query by Validity Date => OK (currently only AND is supported)
## https://<service-root-uri>/odata/v1/Products?$filter=ContentDate/Start gt 2019-05-15T00:00:00.000Z AND ContentDate/End lt 2019-05-16T00:00:00.000Z

### Section 3.3.1.4 Query by Attributes => PENDING
##[AD-1], [AD-2], [AD-3], [AD-4] and [AD-5] provide the definition of the minimum metadata that shall be indexed for each product, and their origin within the product

## The list of products associated with a particular attribute Name value can be obtained as follows:
## https://<service-root-uri>/odata/v1/Products?$filter=Attributes/OData.CSC.ValueTypeAttribute/any(att:att/Name eq '[Attribute.Name]' and att/OData.CSC.ValueTypeAttribute/Value eq '[Attribute.Value]')
## Where the ValueTypeAttribute is the defined type for the Named attribute, e.g. StringAttribute, DateTimeOffsetAttribute, IntegerAttribute.


## https://<service-root-uri>/odata/v1/Products?$filter=Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'productType' and att/OData.CSC.StringAttribute/Value eq 'AUX_ECMWFD') and Attributes/OData.CSC.StringAttribute/any(att:att/Name eq 'platformShortName' and att/OData.CSC.StringAttribute/Value eq 'SENTINEL-2')



### Section 3.3.1.5 Additional Options => PARTIAL

### $orderby
## If asc or desc not specified, then the resources will be ordered in ascending order

## https://<service-root-uri>/odata/v1/Products?$orderby=PublicationDate desc



## pagination     => $top, $skip and $count

## https://<service-root-uri>/odata/v1/Products$top=2&$filter=startswith(Name,'S2') => OK
## https://<service-root-uri>/odata/v1/Products$filter=startswith(Name,'S2')&$top=1 => OK

## https://<service-root-uri>/odata/v1/Products?$orderby=PublicationDate desc
## sort results   => $orderby => PENDING


### Section 3.3.3 Catalogue Export
## {{service-root-uri}}/odata/v1/Products?$expand=Attributes&$format=json
## {{service-root-uri}}/odata/v1/Products?$expand=Attributes&$top=1

### The elements in the catalogue export are the product properties and attribute properties
## Products?$expand=Attributes&$format=json

### for each product entity within the Products entity set the value of all related Attributes will be represented inline
## Products?$expand=Attributes&$format=json

### Will return a list of products ordered by PublicationDate in descending order.
## https://<service-root-uri>/odata/v1/Products?$orderby=PublicationDate desc

### Need to report if the ICD is correct with the missing question mark
## https://<service-root-uri>/odata/v1/Products$top=1000&$filter=startswith(Name,'S2')

### Download => OK
## https://<service-root-uri>/odata/v1/Products(Id)/$value

### $count
## https://<service-root-uri>/odata/v1/Products?$count=true
## https://<service-root-uri>/odata/v1/Products?$count=true&$filter=startswith(Name,'S2')

### $skip
## /odata/v1/Products?$skip=100&$filter=startswith(Name,'S2')
## /odata/v1/Products?$filter=startswith(Name,'S2')&$skip=100

### The AUXIP supports single unit downloads only. No component downloads of, for example, metadata, are assumed

### In the case where the query is accepted but no products are found
### (for example if nothing is found in the date range of the query)
### then the 200 OK code is returned with an empty response body, instead of returning the 404 Not Found code.

###$top and $skip are often applied together;
### in this case $skip is always applied first regardless of the order in which they appear in the query.

### $expand

###11.2.5 Specifying Properties to Return
###
### The $select and $expand system query options enable the client to specify the set of structural properties and navigation properties to include in a response. The service MAY include additional properties not specified in $select and $expand, including properties not defined in the metadata document.

require 'json'

module ARC_ODATA

   API_ROOT                            = '/adgs'

   API_URL_PRODUCT                     = "#{API_ROOT}/odata/v1/Products"
   API_URL_PRODUCT_QUERY               = "#{API_ROOT}/odata/v1/Products?"
   API_URL_PRODUCT_QUERY_COUNT         = "#{API_ROOT}/odata/v1/Products?/$count*"
   API_URL_PRODUCT_DOWNLOAD            = "#{API_ROOT}/odata/v1/Products\(*)"
   API_RESOURCE_FOUND                  = 200
   API_BAD_REQUEST                     = 400
   API_RESOURCE_NOT_FOUND              = 404

   ## ------------------------------------------------------

   EDM_AUXIP_PRODUCT_PROPERTY = [ "Id", \
                              "Name", \
                              "ContentType", \
                              "ContentLength", \
                              "PublicationDate", \
                              "EvictionDate", \
                              "Checksum/Algorithm", \
                              "Checksum/Value", \
                              "Checksum/ChecksumDate", \
                              "ContentDate/Start", \
                              "ContentDate/End" \
                              ]

   ## ------------------------------------------------------


   ## ------------------------------------------------------

   EDM_AUXIP_ATTRIBUTE_PROPERTY = []

   ## ------------------------------------------------------

   ## option can be : count
   def oDataQueryResponse(arrFiles, option, skip = 0, top = 0, total = 0)
      hProducts   = Hash.new
      arrProducts = Array.new
      count       = 0
      arrFiles.each{|product|
         if skip > 0 then
            skip -= 1
            next
         end
         if count >= top then
            break
         end
         arrProducts << oDataAUXIP_ArchivedFile(product)
         count += 1
      }
      hResponse = Hash.new

      hResponse["@odata.context"]   = "$metadata#Products"

      if option == 'count' then
         # hResponse["count"]  = "#{count}"
         hResponse["count"]  = "#{arrFiles.length - skip}"
      end

      hResponse["value"]            = arrProducts

      return hResponse.to_json
   end

   ## ------------------------------------------------------

   ## ------------------------------------------------------

   def oDataAUXIP_ArchivedFile(aFile)
      hFile    = Hash.new
      hFile["@odata.mediaContentType"] = "application/octet-stream"
      hFile["Id"]                      = aFile.uuid
      hFile["Name"]                    = aFile.filename
      hFile["ContentType"]             = "application/octet-stream"
      hFile["ContentLength"]           = aFile.size
      hFile["EvictionDate"]            = nil
      hFile["PublicationDate"]         = aFile.archive_date
      hFile["Checksum"]                = { "Algorithm" => "MD5", "Value" => "#{aFile.md5}", "ChecksumDate" => aFile.archive_date}
      hFile["ContentDate"]             = { "Start" => "#{aFile.validity_start}" , "End" => "#{aFile.validity_stop}"}
      return hFile
   end
   ## ------------------------------------------------------

   def oData2Model(property)

      if property == "ContentLength" then
         return "size"
      end

      if property == "Name" then
         return "name"
      end

      if property == "PublicationDate" then
         return "archive_date"
      end

      if property == "ChecksumDate" then
         return "archive_date"
      end

      if property == "Start" or property.include?("Start") == true then
         return "validity_start"
      end

      if property == "End" or property.include?("End") == true then
         return "validity_stop"
      end

      return false

   end
   ## ------------------------------------------------------

   ## Built-in filter operations
   ## https://docs.oasis-open.org/odata/odata/v4.01/odata-v4.01-part1-protocol.html#sec_BuiltinFilterOperations

   def filterOperations2Model(operation)

      if operation == "eq" then
         return "=="
      end

      if operation == "gt" then
         return ">"
      end

      if operation == "ge" then
         return ">="
      end

      if operation == "lt" then
         return "<"
      end

      if operation == "le" then
         return "<="
      end

#      if operation == "ne" then
#         return "=="
#      end

      return false

   end
   ## ------------------------------------------------------

end
