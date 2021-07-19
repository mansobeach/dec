#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #ODataClientTEST_ADGS class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: ODataClientADGS.rb,v 1.25 2014/10/14 08:49:08 bolf Exp $
###
### This class is an OData client adapted to the ADGS Test for DEV
###
###
#########################################################################

require 'rubygems'

require 'ctc/API_TEST_ADGS'

require 'dec/ODataClientBase'

module DEC

class ODataClientTEST_ADGS < ODataClientBase

   include CUC::DirUtils
   include DEC
   
   ## -------------------------------------------------------------
   
   def initialize(user, password, query, creationtime, datetime, sensingtime, full_path_dir, download, logger)
     
      super(user, password, query, creationtime, datetime, sensingtime, full_path_dir, download, logger)
     
      ## Default URI
      @urlCount    = TEST_ADGS::API_URL_ODATA_PRODUCT_COUNT
      @urlSelect   = TEST_ADGS::API_URL_ODATA_PRODUCT_SELECT_ID
      @urlPaging   = TEST_ADGS::API_URL_ODATA_PRODUCT_PAGING

      if @sensingtime != nil then
         @urlSelect   = TEST_ADGS::API_URL_ODATA_PRODUCT_SELECT_BY_SENSING
         @urlPaging   = TEST_ADGS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING
      
         if @format == "json" then
            @urlSelect   = TEST_ADGS::API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_JSON
            @urlPaging   = TEST_ADGS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_JSON 
         end

         if @format == "csv" then
            @urlSelect   = TEST_ADGS::API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_CSV
            @urlPaging   = TEST_ADGS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_CSV
         end
      end
      
      if @datetime != nil or @creationtime != nil then
         if @format == "json" then
            urlSelect   = TEST_ADGS::API_URL_ODATA_PRODUCT_SELECT_ID_S1_JSON
            urlPaging   = TEST_ADGS::API_URL_ODATA_PRODUCT_PAGING_S1_JSON   
         end

         if @format == "csv" then
            @urlSelect   = TEST_ADGS::API_URL_ODATA_PRODUCT_SELECT_ID_S1_CSV
            @urlPaging   = TEST_ADGS::API_URL_ODATA_PRODUCT_PAGING_S1_CSV  
         end
      end

      @condition   = "#{TEST_ADGS::API_ODATA_FILTER_SUBSTRINGOF}(Name,%27#{@datatake}%27)"

      if @param != nil then
         @condition   = "#{@condition.dup} and substringof(%27#{@param}%27,Name)"
         @urlCount    = "#{@urlCount.dup}#{@condition}"
      end   
      
      @serviceRootUri         = TEST_ADGS::API_ROOT
      @format                 = "json" 
      @attributeDateAvailable = TEST_ADGS::API_ODATA_ATTRIBUTE_DATE_AVAILABILITY
      @bUseDateTime           = false
       
   end
   ## -----------------------------------------------------------
  
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      @logger.debug("ODataClientTEST_ADGS debug mode is on")
   end
   ## -----------------------------------------------------------

   private   
   ## -------------------------------------------------------------

end # class

end # module


