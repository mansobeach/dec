#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #SinatraControllerOData class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Mini Archive Component (MinArc)
### 
### Git: $Id: SinatraControllerOData,v 1.8 2008/11/26 12:40:47 bolf Exp $
###
### module ARC_ODATA
###
#########################################################################

require 'sinatra'

require 'cuc/Converters'

require 'arc/MINARC_API_OData'
require 'arc/MINARC_DatabaseModel'

module ARC_ODATA

## ===================================================================

class SinatraControllerOData

   include CUC::Converters
   ## ------------------------------------------------------
   
   ## Class contructor
   def initialize(sinatra_app, logger = nil, isDebug = false)
      @app           = sinatra_app
      @params        = sinatra_app.params
      @request       = sinatra_app.request
      @response      = sinatra_app.response
      @logger        = logger
      @isDebugMode   = isDebug
      if @isDebugMode == true then
         self.setDebugMode
      end
   end
   ## ------------------------------------------------------
   
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      if @logger != nil then
         @logger.debug("SinatraControllerOData debug mode is on")
      end
   end
   ## ------------------------------------------------------

private


end ## class

## ===================================================================

class ControllerODataProductDownload < SinatraControllerOData

  ## -------------------------------------------------------

  def initialize(sinatra_app, logger = nil, isDebug = false)
     @uuid     = nil
     @bValue   = false
     @property = nil
     super(sinatra_app, logger, isDebug)
  end
  ## -------------------------------------------------------
  ##
  def download
     if @logger != nil and @isDebugMode == true then
        @logger.debug("path_info    :   #{@request.path_info}")
        @logger.debug("query_string :   #{@request.query_string}")
        @logger.debug("url          :   #{@request.url}")
        @logger.debug("path         :   #{@request.path}")
     end
     
     parseQuery(@request.path_info)
     
     if @bValue == true then
          
        if @isDebugMode == true then
           @logger.debug("requested uuid : #{@uuid}")
        end
        
        aFile = ArchivedFile.where(uuid: @uuid).to_a[0]
        
        @logger.debug("aFile #{aFile} / #{@uuid}")
        
        if aFile == nil then
           @logger.info("[ARC_200] Requested: #{@uuid} / File not found") 
           @response.status = ARC_ODATA::API_RESOURCE_NOT_FOUND
           @response.headers['Message']  = "#{@uuid} not found"
        else
           @logger.info("[ARC_200] Requested: #{@uuid} / #{aFile.filename}") 
           full_path = "#{aFile.path}/#{aFile.filename}"
           @response.status = ARC_ODATA::API_RESOURCE_FOUND
           @response.headers['Message']  = "Woo-hoo ; I got my head checked ; By a jumbo jet ; It wasn't easy ; But nothing is ... No"
           @app.send_file(full_path, :filename => aFile.filename)
        end
     else
        @logger.error("[ARC_777] Query #{@request.query_string}: not valid / or badly managed: #{@request.path_info}") 
        @response.status = ARC_ODATA::API_BAD_REQUEST
        @response.headers['Message'] = "property #{@property} not supported"
     end
  end
  ## -------------------------------------------------------
  
private

   ## -------------------------------------------------------
   
   def parseQuery(path_info)
      @uuid       = path_info.split("(")[1].split(")")[0]
      @bValue     = path_info.split("$")[1].include?("value")
      @property   = "$#{path_info.split("$")[1]}"
   end
  
   ## -------------------------------------------------------
  
end ## class

## ===================================================================




## ===================================================================

class ControllerODataProductQuery < SinatraControllerOData

  ## -------------------------------------------------------

  def initialize(sinatra_app, logger = nil, isDebug = false)
     @expandEntity    = nil
     @filterParam     = nil
     @queryValue      = nil
     @property        = nil
     @function        = nil
     @option          = nil
     @skip            = 0
     ## results limit
     ## the page size configurable to support at least 1000 results per page
     @top             = 1000
     super(sinatra_app, logger, isDebug)
  end
  ## -------------------------------------------------------
  ##
  def query
     if @logger != nil and @isDebugMode == true then
        @logger.debug("path_info    :   #{@request.path_info}")
        @logger.debug("query_string :   #{URI.unescape(@request.query_string)}")
        @logger.debug("url          :   #{@request.url}")
        @logger.debug("path         :   #{@request.path}")
     end
     
     ret = parseQuery(@request.query_string)
     
     if ret == false then
        @logger.error("[ARC_777] Query #{URI.unescape(@request.query_string)}: not valid / or badly managed: #{@request.query_string}")
        @response.status = ARC_ODATA::API_BAD_REQUEST
        
        if @filterParam != nil then
           @response.headers['Message'] = "FilterParam #{@filterParam} not supported"
        end
        
        if @expandEntity != nil then
           @response.headers['Message'] = "EDM #{@expandEntity} not supported for $expand"
        end
        
        return
     end
          
#     if @property != "Name" then
#        @logger.error("[ARC_777] Property #{@property} not supported : #{@request.query_string}")
#        @response.status = ARC_ODATA::API_BAD_REQUEST
#        @response.headers['Message'] = "Property #{@property} not supported"
#        return     
#     end
     
     aFile = nil
     
     @logger.debug(@property)
     
     ## Query all when no property
     if @property == nil then
        aFile = ArchivedFile.all
     end
     
     ## Query by property Name
     if @property == 'Name' then
        @logger.debug("Property Name LIKE #{@queryValue}")
        aFile = ArchivedFile.where("name LIKE ?", @queryValue)
     end
               
     ## Query by any date property PublicationDate
     if @property == 'PublicationDate' or @property == 'ContentDate/Start' or @property == 'ContentDate/End' then
        @logger.debug(ARC_ODATA::oData2Model(@property))
        @logger.debug(self.str2date(@queryValue))
        @logger.debug(ARC_ODATA::filterOperations2Model(@function))
        aFile = ArchivedFile.where("#{ARC_ODATA::oData2Model(@property)} #{ARC_ODATA::filterOperations2Model(@function)} ?", self.str2date(@queryValue))
     end
         
     if aFile == nil then
        @logger.info("[ARC_210] Query #{URI.unescape(@request.query_string)}: #{@property} #{@function} #{@queryValue} / products not found") 
        @response.status = ARC_ODATA::API_RESOURCE_NOT_FOUND
        @response.headers['Message']  = "#{@queryValue} / products not found"
     else
        if @property != nil then
           @logger.info("[ARC_210] Query #{URI.unescape(@request.query_string)}: #{@property} #{@function} #{@queryValue} $skip = #{@skip} $top = #{@top} / #{aFile.to_a.length - @skip} product(s) found")
        else
           @logger.info("[ARC_210] Query #{URI.unescape(@request.query_string)}: #{@option} #{@queryValue} $skip = #{@skip} $top = #{@top} / #{aFile.to_a.length - @skip} product(s) found")
        end 
        response = ARC_ODATA::oDataQueryResponse(aFile.to_a, @option, @skip, @top)      
        #@response.body           = response
        @response.content_type   = :json
        @response.status         = ARC_ODATA::API_RESOURCE_FOUND
        if @property == nil and @option == 'count' then
           @response.headers['Message']  = "Hey girls ; Hey boys ; Superstar DJ's ; Here we go ..."
        else
           @response.headers['Message']  = "We're flying high ; We're watching the world pass us by ; Never want to come down ; Never want to put my feet back down on the ground "
        end
        
        return response
     end    
       
  end
  ## -------------------------------------------------------
  
private

   ## -------------------------------------------------------
   
   def parseQuery(query_string)

      ## -------------------------------
      ##
      ## Common system query options
      ##
      ## $skip
      if query_string.include?("$skip") == true then
         @skip   = "#{query_string.split("$skip=")[1]}"
         if @skip.include?("&") == true then
            @skip = @skip.dup.split("&")[0].to_i
         else
            @skip = @skip.dup.to_i
         end
         @logger.debug("skip => #{@skip}")
      end

      ## $top
      if query_string.include?("$top") == true then
         @top   = "#{query_string.split("$top=")[1]}"
         if @top.include?("&") == true then
            @top = @top.dup.split("&")[0].to_i
         else
            @top = @top.dup.to_i
         end
         @logger.debug("top => #{@top}")
      end

      ## -------------------------------
      ##
      ## Process the query
   
      ## From most restrictive conditions to simpler ones
      
      ## query by count alone
      if query_string.include?("$expand") == true and query_string.include?("&") == false then
         return parseQueryExpand(query_string)
      end
      
      ## query by count alone
      if query_string.include?("$count") == true and query_string.include?("&") == false then
         return parseQueryCount(query_string)
      end

      ## query by count plus filter
      if query_string.include?("$count") == true and query_string.include?("&") == true then
         return parseQueryCountFilter(query_string)
      end
   
      ## query by date / weak constrain
      if query_string.include?("(") == false or query_string.include?(")") == false then
         return parseQueryDate(query_string)
      end
   
      ## -------------------------------
   
      @filterParam   = "#{query_string.split("$filter=")[1]}"
      @queryValue    = @filterParam.split(",")[1].split(")")[0]
      @property      = @filterParam.split("(")[1].split(",")[0]
      
      if @filterParam.include?("startswith") == true then 
         @function   = "startswith"
         @queryValue = "#{@queryValue.dup}%"
         return true
      end
      
      if @filterParam.include?("endswith") == true then
         @function   = "endswith"
         @queryValue = "%#{@queryValue.dup}"
         return true
      end
      
      if @filterParam.include?("contains") == true then
         @function   = "contains"
         @queryValue = "%#{@queryValue.dup}%"
         return true
      end
      @logger.error("[ARC_XXX] FilterParam #{@filterParam} not supported")
      return false      
   end
  
   ## -------------------------------------------------------
  
   ## -------------------------------------------------------
  
   ## https://<service-root-uri>/odata/v1/Products?$filter=PublicationDate%20gt%202020-05-15T00:00:00.000Z
   
   ## https://<service-root-uri>/odata/v1/Products?$filter=ContentDate/Start gt 2019-05-15T00:00:00.000Z   
   
   ## https://<service-root-uri>/odata/v1/Products?$filter=ContentDate/Start gt 2019-05-15T00:00:00.000Z and ContentDate/End lt 2019-05-16T00:00:00.000Z
   def parseQueryDate(query_string)
           
      bRet = false
      
      @filterParam   = "#{URI.unescape(query_string).split("$filter=")[1]}"
      
      if @filterParam.include?("PublicationDate") == true then
         @property   = "PublicationDate"
         @function   = @filterParam.split(" ")[1]
         @queryValue = @filterParam.split(" ")[2]
         if @queryValue.include?("&") == true then
            @queryValue = @queryValue.dup.split("&")[0]
         end
         bRet        = true
      end

      if @filterParam.include?("ContentDate/Start") == true then
         @property   = "ContentDate/Start"
         @function   = @filterParam.split(" ")[1]
         @queryValue = @filterParam.split(" ")[2]
         if @queryValue.include?("&") == true then
            @queryValue = @queryValue.dup.split("&")[0]
         end
         bRet        = true
      end

      if @filterParam.include?("ContentDate/End") == true then
         @property   = "ContentDate/End"
         @function   = @filterParam.split(" ")[1]
         @queryValue = @filterParam.split(" ")[2]
         if @queryValue.include?("&") == true then
            @queryValue = @queryValue.dup.split("&")[0]
         end
         bRet        = true
      end

      if @isDebugMode == true then
         @logger.debug("parseQueryDate #{@property} #{@function} #{@queryValue}")
      end

      return bRet
      
   end
   ## -------------------------------------------------------  

   ## System query $count alone
   ## https://<service-root-uri>/odata/v1/Products?$count=true
   def parseQueryCount(query_string)
      bRet = false
      
      @option        = 'count'
      @queryValue    = "#{URI.unescape(query_string).split("$count")[1]}"
      
      if @isDebugMode == true then
         @logger.debug("parseQueryCount #{@option} #{@queryValue}")
      end

      return true
      
   end
   ## -------------------------------------------------------  

   ## System query $count alone
   ## https://<service-root-uri>/odata/v1/Products$count=true&$filter=startswith(Name,'S2B')
   def parseQueryCountFilter(query_string)
      bRet = false
      
      @filterParam   = "#{query_string.split("$filter=")[1]}"
      @queryValue    = @filterParam.split(",")[1].split(")")[0]
      @property      = @filterParam.split("(")[1].split(",")[0]      
      @option        = 'count'
      @queryValue    = @filterParam.split(",")[1].split(")")[0]
      
      if @filterParam.include?("startswith") == true then 
         @function   = "startswith"
         @queryValue = "#{@queryValue.dup}%"
         bRet        = true
      end
      
      if @filterParam.include?("endswith") == true then
         @function   = "endswith"
         @queryValue = "%#{@queryValue.dup}"
         bRet        = true
      end
      
      if @filterParam.include?("contains") == true then
         @function   = "contains"
         @queryValue = "%#{@queryValue.dup}%"
         bRet        = true
      end
      
      if @isDebugMode == true then
         @logger.debug("parseQueryCountFilter @filterParam => #{@filterParam} ; @function => #{@function}; @property => #{@property} ; @queryValue => #{@queryValue} ; @option => #{@option} ")
      end

      return bRet
      
   end
   ## -------------------------------------------------------  
  
   ## {{service-root-uri}}/odata/v1/Products?$expand=Attributes&$format=json
   ## {{service-root-uri}}/odata/v1/Products?$expand=Attributes&$top=1

   def parseQueryExpand(query_string)
      bRet = true
      
      @expandEntity = "#{query_string.split("$expand=")[1]}"
      
      if @expandEntity.include?("&") == true then
         @expandEntity = @expandEntity.dup.split("&")[0]
      end
      
      if @expandEntity != "Attributes" then
         @logger.debug("parseQueryExpand => expand => #{@expandEntity} not supported")
         return false
      end
      
      @logger.debug("parseQueryExpand => expand => #{@expandEntity}")
      return bRet
   end
   ## -------------------------------------------------------
  
end ## class

## ===================================================================


end ## module



