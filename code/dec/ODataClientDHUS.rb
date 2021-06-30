#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #ODataClientDHUS class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: ODataClientDHUS.rb,v 1.25 2014/10/14 08:49:08 bolf Exp $
###
### This class is an OData client adapted to the DHUS DIAS OpenHub
###
###
#########################################################################

require 'rubygems'
require 'dec/ODataClient'

module DEC

class ODataClientDHUS < ODataClient
   
   ## -------------------------------------------------------------
   
   def initialize(user, password, query, creationtime, datetime, sensingtime, full_path_dir, logger)
      
      super(user, password, query, creationtime, datetime, sensingtime, full_path_dir, logger)
      
      if @mission == "GNSS" then
         @urlCount    = DHUS::API_URL_ODATA_PRODUCT_COUNT_GNSS
         @urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_ID_GNSS
         @urlPaging   = DHUS::API_URL_ODATA_PRODUCT_PAGING_GNSS
      else
         @urlCount    = DHUS::API_URL_ODATA_PRODUCT_COUNT
         @urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_ID_S1
         @urlPaging   = DHUS::API_URL_ODATA_PRODUCT_PAGING_S1
      end

      if @sensingtime != nil then
         @urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_BY_SENSING
         @urlPaging   = DHUS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING
      
         if @format == "json" then
            @urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_JSON
            @urlPaging   = DHUS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_JSON 
         end

         if @format == "csv" then
            @urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_CSV
            @urlPaging   = DHUS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_CSV
         end
      end
      
      if @datetime != nil or @creationtime != nil then
         if @format == "json" then
            urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_ID_S1_JSON
            urlPaging   = DHUS::API_URL_ODATA_PRODUCT_PAGING_S1_JSON   
         end

         if @format == "csv" then
            @urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_ID_S1_CSV
            @urlPaging   = DHUS::API_URL_ODATA_PRODUCT_PAGING_S1_CSV  
         end
      end

      @condition   = "#{DHUS::API_ODATA_FILTER_SUBSTRINGOF}(%27#{@datatake}%27,Name)"

      if @param != nil then
         @condition   = "#{@condition.dup} and substringof(%27#{@param}%27,Name)"
         @urlCount    = "#{@urlCount.dup}#{@condition}"
      end   
      
      @attributeDateAvailable = DHUS::API_ODATA_ATTRIBUTE_DATE_AVAILABILITY
      @bUseDateTime           = true 
   end
   ## -----------------------------------------------------------
  
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      @logger.debug("ODataClientDHUS debug mode is on")
   end
   ## -----------------------------------------------------------

end # class

end # module


