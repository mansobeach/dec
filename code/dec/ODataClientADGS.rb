#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #ODataClientDHUS class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: ODataClientADGS.rb,v 1.25 2014/10/14 08:49:08 bolf Exp $
###
### This class is an OData client adapted to the DHUS DIAS OpenHub
###
###
#########################################################################

require 'rubygems'
require 'dec/ODataClient'

module DEC

class ODataClientADGS < ODataClient

   include CUC::DirUtils
   include DEC
   
   ## -------------------------------------------------------------
   
   def initialize(user, password, query, creationtime, datetime, sensingtime, full_path_dir, download, logger)
      
      super(user, password, query, creationtime, datetime, sensingtime, full_path_dir, download, logger)
      
      ## Default URI
      @urlCount    = ADGS::API_URL_ODATA_PRODUCT_COUNT
      @urlSelect   = ADGS::API_URL_ODATA_PRODUCT_SELECT_ID
      @urlPaging   = ADGS::API_URL_ODATA_PRODUCT_PAGING

      if @sensingtime != nil then
         @urlSelect   = ADGS::API_URL_ODATA_PRODUCT_SELECT_BY_SENSING
         @urlPaging   = ADGS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING
      
         if @format == "json" then
            @urlSelect   = ADGS::API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_JSON
            @urlPaging   = ADGS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_JSON 
         end

         if @format == "csv" then
            @urlSelect   = ADGS::API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_CSV
            @urlPaging   = ADGS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_CSV
         end
      end
      
      if @datetime != nil or @creationtime != nil then
         if @format == "json" then
            urlSelect   = ADGS::API_URL_ODATA_PRODUCT_SELECT_ID_S1_JSON
            urlPaging   = ADGS::API_URL_ODATA_PRODUCT_PAGING_S1_JSON   
         end

         if @format == "csv" then
            @urlSelect   = ADGS::API_URL_ODATA_PRODUCT_SELECT_ID_S1_CSV
            @urlPaging   = ADGS::API_URL_ODATA_PRODUCT_PAGING_S1_CSV  
         end
      end

      @condition   = "#{ADGS::API_ODATA_FILTER_SUBSTRINGOF}(Name,%27#{@datatake}%27)"

      if @param != nil then
         @condition   = "#{@condition.dup} and substringof(%27#{@param}%27,Name)"
         @urlCount    = "#{@urlCount.dup}#{@condition}"
      end   
      
      @serviceRootUri         = ADGS::API_ROOT
      @format                 = "json" 
      @attributeDateAvailable = ADGS::API_ODATA_ATTRIBUTE_DATE_AVAILABILITY
      @bUseDateTime           = false
       
   end
   ## -----------------------------------------------------------
  
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      @logger.debug("ODataClientADGS debug mode is on")
   end
   ## -----------------------------------------------------------

   private   
   ## -------------------------------------------------------------

end # class

end # module


