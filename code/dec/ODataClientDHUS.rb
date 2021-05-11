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
require 'getoptlong'
require 'net/http'
require 'date'
require 'nokogiri'
require 'json'

require 'cuc/Log4rLoggerFactory'

require 'dec/DEC_Environment'
require 'dec/API_DHUS'
require 'dec/API_PRIP'

module DEC

class ODataClientDHUS

   include CUC::DirUtils
   include DEC
   
   ## -------------------------------------------------------------
   
   def initialize(user, password, query, creationtime, datetime, sensingtime, full_path_dir, logger)
      @user          = user
      @password      = password
      @query         = query
      @creationtime  = creationtime
      @datetime      = datetime
      @sensingtime   = sensingtime
      @full_path_dir = full_path_dir
      @logger        = logger
      @format        = "xml"
      @currentDate   = DateTime.now.strftime("%Y%m%dT%H%M%S")
      
      if @sensingtime != nil then
         @sensingStart = @sensingtime.split(",")[0]
         @sensingEnd   = @sensingtime.split(",")[1]
      end

      if @creationtime != nil then
         @creationStart = @creationtime.split(",")[0]
         @creationEnd   = @creationtime.split(",")[1]
      end
      
   end
   ## -----------------------------------------------------------
  
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      @logger.debug("ODataClientDHUS debug mode is on")
   end
   ## -----------------------------------------------------------


   ## -----------------------------------------------------------

   ## https://scihub.copernicus.eu/dhus/odata/v1/Products?$filter=CreationDate gt datetime'2017-05-15T00:00:00.000'

   def exec_query
      urlCount    = DHUS::API_URL_ODATA_PRODUCT_COUNT
      urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_ID_S1
      urlPaging   = nil
   
      if @sensingtime != nil then
         urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_BY_SENSING
         urlPaging   = DHUS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING
      
         if @format == "json" then
            urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_JSON
            urlPaging   = DHUS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_JSON 
         end

         if @format == "csv" then
            urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_BY_SENSING_CSV
            urlPaging   = DHUS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_CSV
         end
      end
      
      if @datetime != nil or @creationtime != nil then
         if @format == "json" then
            urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_ID_S1_JSON
            urlPaging   = DHUS::API_URL_ODATA_PRODUCT_PAGING_S1_JSON   
         end

         if @format == "csv" then
            urlSelect   = DHUS::API_URL_ODATA_PRODUCT_SELECT_ID_S1_CSV
            urlPaging   = DHUS::API_URL_ODATA_PRODUCT_PAGING_S1_CSV  
         end
      end
   
      nParams     = @query.split(":").length
      system      = @query.split(":")[0]
      mission     = @query.split(":")[1]
      datatake    = @query.split(":")[2]
      param       = nil
      begin
         param       = @query.split(":")[3]
      rescue Exception => e
      end

      condition   = "#{DHUS::API_ODATA_FILTER_SUBSTRINGOF}(%27#{datatake}%27,Name)"
   
      if param != nil then
         condition   = "#{condition.dup} and substringof(%27#{param}%27,Name)"
         urlCount    = "#{urlCount.dup}#{condition}"
      end   
      ## --------------------------------------------
   
      if @isDebugMode == true then
         @logger.debug("#{system} : #{mission} : #{datatake} ; #{param} ; #{condition}")
      end
   
      ## --------------------------------------------

      ## query count of products
      
      ret = queryCount(urlCount, condition)
      
      if @isDebugMode == true then
         @logger.debug("Found #{@iTotal} items")
      end
      
      if @iTotal == -1 or ret == false then
         return false
      end
                  
      ## --------------------------------------------
      ##
      ## Product Select 
      
      ret = querySelect(urlSelect, condition, datatake)
            
      return ret
      
   end

   ## -------------------------------------------------------------
 private
   
   ## -------------------------------------------------------------

   ## --------------------------------------------
   ##
   ## Product Select 

   def querySelect(urlSelect, condition, mission)
      
      uri  = URI.parse(urlSelect)  
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 600
      http.read_timeout = 600
      http.use_ssl = true
      request  = Net::HTTP::Get.new(uri.request_uri)   
      request.basic_auth(@user, @password)
      
      iPending = @iTotal
      iSkip    = 0

      arrResponseBody = Array.new

      ## --------------------------------------------

      if @datetime != nil then
         urlSelect = "#{urlSelect.dup}#{condition} and CreationDate ge datetime'#{@datetime}'"
      end

      if @sensingtime != nil then
         urlSelect = "#{urlSelect.dup}#{condition} and ContentDate/Start ge datetime'#{@sensingStart}' and ContentDate/Start lt datetime'#{@sensingEnd}'"
      end

      if @creationtime != nil then
         urlSelect = "#{urlSelect.dup}#{condition} and CreationDate ge datetime'#{@creationStart}' and CreationDate lt datetime'#{@creationEnd}'"
      end


      ## --------------------------------------------
   
      ## --------------------------------------------
   
      uri      = URI.parse(urlSelect)
      cmdCurl  = "curl -k -u #{@user}:#{@password} \'#{uri.scheme}://#{uri.host}#{uri.request_uri}\'"

      ## -------------------------------------------- 
      if @isDebugMode == true then
         @logger.debug(cmdCurl)
      end
      ## --------------------------------------------
          
      request  = Net::HTTP::Get.new(uri.request_uri)   

      request.basic_auth(@user, @password)
      response    = nil
      iRetry      = 1
      exception   = nil
      
      ## ---------------------
      ## loop to http request

      response = nil
      
      while response == nil and iRetry <= 5 do
         begin
            response = http.request(request)
            
            if @isDebugMode == true then
               @logger.debug("#{uri.scheme}://#{uri.host}#{uri.request_uri}")
               @logger.debug(response.code)
               @logger.debug(response.message)
            end

            if response.code != DHUS::API_RESOURCE_FOUND then
               raise "Error in request #{response.code} / #{response.message}"
            end

         rescue Exception => e
            exception = e
            @logger.error("Failed request #{uri.scheme}://#{uri.host}#{uri.request_uri}")
            @logger.error(e.to_s)
            iRetry   = iRetry + 1
            response = nil
            sleep(30.0)
         end
      end
      ## ---------------------
      
      if response == nil then
         if @isDebugMode == true then
            @logger.debug(e.backtrace)
         end
         return false
         # raise exception
      end
      ## ---------------------
      
      ## datatake is carrying the mission id    
      createFileMetadata(mission, response.body, iSkip)
         
      iPending = iPending - DHUS::API_TOP_LIMIT_ITEMS
      iSkip    = iSkip    + DHUS::API_TOP_LIMIT_ITEMS
   
      ## --------------------------------------------
   
      if iPending <= 0 then
         return true
      end
   
      ## --------------------------------------------
   
      ##
      ## Product Paging 

      while iPending > 0 do

         urlPaging   = "#{DHUS::API_URL_ODATA_PRODUCT_PAGING_S1}#{iSkip}#{condition}"

         if @sensingtime != nil then
            urlPaging   = "#{DHUS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING}#{iSkip}#{condition}"

            if @format == "csv" then
               urlPaging   = "#{DHUS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_CSV}#{iSkip}#{condition}"
            end

            if @format == "json" then
               urlPaging   = "#{DHUS::API_URL_ODATA_PRODUCT_PAGING_BY_SENSING_JSON}#{iSkip}#{condition}"
            end        
         
         end

         ## -----------------------------------------
      
         if @datetime != nil then
            urlPaging = "#{urlPaging.dup} and CreationDate ge datetime'#{@datetime}'"
         end

         if @sensingtime != nil then
            urlPaging = "#{urlPaging.dup} and ContentDate/Start ge datetime'#{@sensingStart}' and ContentDate/Start lt datetime'#{@sensingEnd}'"
         end

         if @creationtime != nil then
            urlPaging = "#{urlPaging.dup} and CreationDate ge datetime'#{@creationStart}' and CreationDate lt datetime'#{@creationEnd}'"
         end

         ## -----------------------------------------
      
         uri         = URI.parse(urlPaging)    
         cmdCurl     = "curl -k -u #{@user}:#{@password} \'#{uri.scheme}://#{uri.host}#{uri.request_uri}\'"
         
         ## -------------------------------------------- 
         if @isDebugMode == true then
            @logger.debug(cmdCurl)
         end
         ## --------------------------------------------
         
         request     = Net::HTTP::Get.new(uri.request_uri)   
         request.basic_auth(@user, @password)
         response    = nil
         iRetry      = 1
      
         while response == nil and iRetry <= 5 do

            begin
               response    = http.request(request)
 
               if response.code != DHUS::API_RESOURCE_FOUND then
                  raise "Error in request #{response.code} / #{response.message}"
               end            
            
            rescue Exception => e
               @logger.error("Failed #{uri.scheme}://#{uri.host}#{uri.request_uri}")
               @logger.error(e.to_s)
               if @isDebugMode == true then
                  @logger.debug(e.backtrace)
               end               
               iRetry   = iRetry + 1
               response = nil
               @logger.warn("Retry #{uri.scheme}://#{uri.host}#{uri.request_uri}")
               sleep(30.0)
            end
            
         end
         
         ## datatake is carrying the mission id
         createFileMetadata(mission, response.body, iSkip)

         iPending = iPending - DHUS::API_TOP_LIMIT_ITEMS
         iSkip    = iSkip    + DHUS::API_TOP_LIMIT_ITEMS
         
      end
      
      return true
   
   end

   ## --------------------------------------------
   ##
   ## Product Count 
   ##
   
   def queryCount(urlCount, condition)
      
      if @datetime != nil then
         urlCount = "#{urlCount}#{condition} and CreationDate ge datetime'#{@datetime}'"
      end

      if @sensingtime != nil then
         urlCount = "#{urlCount}#{condition} and ContentDate/Start ge datetime'#{@sensingStart}' and ContentDate/Start lt datetime'#{@sensingEnd}'"
      end

      if @creationtime != nil then
         urlCount = "#{urlCount}#{condition} and CreationDate ge datetime'#{@creationStart}' and CreationDate lt datetime'#{@creationEnd}'"
      end

      uri      = URI.parse(urlCount)
      cmdCurl  = "curl -k -u #{@user}:#{@password} \'#{uri.scheme}://#{uri.host}#{uri.request_uri}\'"

      ## --------------------------------------------
      if @isDebugMode == true then
         @logger.debug(cmdCurl)
      end
      ## --------------------------------------------

      uri  = URI.parse(urlCount)        
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 600
      http.read_timeout = 600
      http.use_ssl      = true
      request              = Net::HTTP::Get.new(uri.request_uri)   
      request.basic_auth(@user, @password)
      
      response = nil   
      iRetry   = 1
      
      while response == nil and iRetry <= 5 do
      
         begin
            response = http.request(request)
 
            if @isDebugMode == true then
               @logger.debug(response.code)
               @logger.debug(response.message)
               @logger.debug(response.body)
            end
         rescue Exception => e
            @logger.error("Failed request #{urlCount}")
            @logger.error(e.to_s)
            if @isDebugMode == true then
               @logger.debug(e.backtrace)
            end
            iRetry   = iRetry + 1
            response = nil
            @logger.warn("Retry #{uri.scheme}://#{uri.host}#{uri.request_uri}")
            sleep(30.0)
         end
      end
            
      ## --------------------------------------------

      iPending = response.body.to_i   
      @iTotal  = iPending
      
      if @iTotal == -1 or response.code != DHUS::API_RESOURCE_FOUND then
         @logger.error("Error in request #{response.code} / #{response.message} / #{response.body}")
         return false
      end
                  
      ## --------------------------------------------
      
      return true

   end
   
   ## -------------------------------------------------------------

   ## create File with the query results
   def createFileMetadata(mission, data, iSkip)
      prevDir = Dir.pwd
      Dir.chdir(@full_path_dir)
      filename = ""
   
      if @datetime != nil then
         filename = "DEC_OPER_OPDHUS_#{mission}_AUIP_#{@currentDate}_V#{@datetime.gsub("-","").gsub(":","").split(".")[0]}_#{@iTotal}_#{iSkip.to_s.rjust(@iTotal.to_s.length,'0')}.#{@format}"
      end

      if @creationtime != nil then
         filename = "DEC_OPER_AVDHUS_#{mission}_AUIP_#{@currentDate}_V#{@creationStart.gsub("-","").gsub(":","").split(".")[0]}_#{@creationEnd.gsub("-","").gsub(":","").split(".")[0]}_#{@iTotal}_#{iSkip.to_s.rjust(@iTotal.to_s.length,'0')}.#{@format}"
      end
   
      if @sensingtime != nil then
         filename = "DEC_OPER_OPDHUS_#{mission}_AUIP_#{@currentDate}_V#{@sensingStart.gsub("-","").gsub(":","").split(".")[0]}_#{@sensingEnd.gsub("-","").gsub(":","").split(".")[0]}_#{@iTotal}_#{iSkip.to_s.rjust(@iTotal.to_s.length,'0')}.#{@format}"
      end
   
      if @creationtime ==nil and @sensingtime == nil and @datetime == "" then
         filename = "DEC_OPER_OPDHUS_#{mission}_AUIP_#{@currentDate}_#{@iTotal}_#{iSkip.to_s.rjust(@iTotal.to_s.length,'0')}.#{@format}"
      end
   
      filenameTemp = ".TEMP_#{filename}"
      aFile = File.new(filenameTemp, File::CREAT|File::WRONLY) 
      aFile.write(data)   
      aFile.flush
      aFile.close
      begin
         File.rename(filenameTemp, filename)
      rescue Exception => e
         @logger.error("Could not rename #{filenameTemp} to #{filename}")
         @logger.error(e.to_s)
      end
      @logger.info("DHUS created #{filename}")
      Dir.chdir(prevDir)
   end
   ## -------------------------------------------------------------

end # class

end # module


