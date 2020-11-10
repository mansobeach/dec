#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #MINARC_API class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: API_PRIP.rb,v $Id$
###
### module DHUS
###
#########################################################################

## OData https://scihub.copernicus.eu/apihub/odata/v1

## URL Percent Encoding
## https://en.wikipedia.org/wiki/Percent-encoding
### %27 => '
### %24 => $ This one must be escaped with curl

## Host is currently using self-signed certificates
## OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=error: certificate verify failed (self signed certificate)

module PRIP
   API_URL_ODATA_PRODUCT            = "https://90.84.179.7/odata/v1/Products?"
   API_ODATA_FILTER_CONTAINS        = "&$filter=contains"
   API_ODATA_FILTER_STARTSWITH      = "&$filter=startswith"
   API_ODATA_FILTER_ENDSWITH        = "&$filter=endswith"
   API_RESOURCE_FOUND               = "200"
end
