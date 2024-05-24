#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #SinatraControllerOData class
###
### === Written by DEIMOS Space S.L.
###
### === Mini Archive Component (MinArc)
###
### Git: $Id: SinatraControllerODataProductQuery, Exp $
###
### module ARC_ODATA
###
#########################################################################

require 'arc/SinatraControllerBase'

module ARC_ODATA

class ControllerODataProductQuery < ARC::SinatraControllerBase

  ## -------------------------------------------------------

  def initialize(sinatra_app, logger = nil, isDebug = false)
     @expandEntity    = nil
     @filterParam     = nil
     @queryValue      = nil
     @property        = nil
     @function        = nil
     ## count supported as option
     @option          = nil
     @orderby         = nil
     @order           = "ASC"
     @skip            = 0
     ## results limit
     ## the page size configurable to support at least 100 results per page
     @top             = 100
     super(sinatra_app, logger, isDebug)
  end
  ## -------------------------------------------------------
  ##
  def query

     ret = true

     if @logger != nil and @isDebugMode == true then
        @logger.debug("ControllerODataProductQuery::query by #{@user}")
        @logger.debug("path_info    :   #{@request.path_info}")
        @logger.debug("query_string :   #{Addressable::URI.unencode(@request.query_string)}")
        @logger.debug("url          :   #{Addressable::URI.unencode(@request.url)}")
        @logger.debug("path         :   #{@request.path}")
     end

#     @logger.debug("xxxxxxxxxxxxxxxxx")
#     @logger.debug(@request.query_string)
#     @logger.debug(@request.path)
#     @logger.debug("xxxxxxxxxxxxxxxxx")

     ## ----------------------------------------------------
     ##
     ## This case is for the pure $count without query
     ## https://185.52.193.141:4567/adgs/odata/v1/Products/$count?
     ##
     if (@request.query_string.include?("$filter") == false and @request.query_string.include?("$count") == true) or \
      (@request.query_string.include?("$filter") == false and @request.path.include?("$count") == true) then
        @logger.info("[ARC_209] User #{@user} [#{@request.ip}]: Processing query: #{@request.query_string}")
        val = ArchivedFile.count
        @response.content_type         = "text/plain"
        @response.headers['Message']   = "The Count von Count counted #{val.to_s}"
        @logger.debug("$count result = #{val.to_s}")
        return val.to_s
     end
     ## ----------------------------------------------------

     ## query is currently mainly understood as $filter
     begin
        ret = parseQuery(Addressable::URI.unencode(@request.query_string))
     rescue Exception => e
        @logger.error(e.to_s)
        @logger.error("[ARC_777] Query #{Addressable::URI.unencode(@request.query_string)}: not valid / or badly managed")
        @response.status = ARC_ODATA::API_BAD_REQUEST
        @response.headers['Message'] = e.to_s
        return
     end

     if ret == false then
        @logger.error("[ARC_777.7] Query #{Addressable::URI.unencode(@request.query_string)}: not valid / or badly managed: #{@request.query_string}")
        @response.status = ARC_ODATA::API_BAD_REQUEST

        if @filterParam != nil then
           @response.headers['Message'] = "FilterParam #{@filterParam} not supported"
        end

        if @expandEntity != nil then
           @response.headers['Message'] = "EDM #{@expandEntity} not supported for $expand"
        end

        return
     end


     aFile = nil

     if @isDebugMode == true then
        @logger.debug(@property)
     end

     ## ------------------------------------------
     ## Query all when no property
     if @property == nil then
        @logger.debug("This is a query all / hopefully limited to #{@top}")
        ## aFile = ArchivedFile.all
        aFile = ArchivedFile.limit(@top)
     end
     ## ------------------------------------------

     ## ------------------------------------------
     ## Query by property Name
     if @property == 'Name' then
        if @isDebugMode == true then
           @logger.debug("Property Name LIKE #{@queryValue}")
        end
        aFile = ArchivedFile.where("name LIKE ?", @queryValue)
     end
     ## ------------------------------------------

     ## ------------------------------------------
     ## Query by any date property PublicationDate
     if @property == 'PublicationDate' or @property == 'ContentDate/Start' or @property == 'ContentDate/End' then
        if @isDebugMode == true then
           @logger.debug(ARC_ODATA::oData2Model(@property))
           @logger.debug(self.str2date(@queryValue))
           @logger.debug(ARC_ODATA::filterOperations2Model(@function))
        end

        aFile = ArchivedFile.where("#{ARC_ODATA::oData2Model(@property)} #{ARC_ODATA::filterOperations2Model(@function)} ?", self.str2date(@queryValue))
     end
     ## ------------------------------------------

#     ## ------------------------------------------
#     ## Query is an array of properties
#
#     if @property.class.to_s.include?("Array") == true then
#        if @isDebugMode == true then
#           @logger.debug("Array of properties #{@property}")
#        end
#        strQuery = ""
#        idx      = 0
#        @property.each{|prop|
#           if idx == 0 then
#              strQuery = "#{ARC_ODATA::oData2Model(prop)} #{ARC_ODATA::filterOperations2Model(@function[idx])} ?"
#           else
#              strQuery = "#{strQuery.dup} AND #{ARC_ODATA::oData2Model(prop)} #{ARC_ODATA::filterOperations2Model(@function[idx])} ?"
#           end
#           idx += 1
#        }
#
#        query = Array.new
#        query << strQuery
#        query << @queryValue
#        query = query.dup.flatten
#
#        if @isDebugMode == true then
#           @logger.debug("Composed query => #{strQuery}")
#           @logger.debug("Composed query => #{query}")
#        end
#
#        aFile = ArchivedFile.where(query)
#
#     end
     ## ------------------------------------------

     ## $filter with multiple attributes
     if @request.query_string.include?("$filter") == true and @request.query_string.include?("and") == true then
        aFile = execQueryComplex(Addressable::URI.unencode(@request.query_string))
     end

     ## -------------------------------


     if aFile == nil then
        @logger.info("[ARC_210] User #{@user} [#{@request.ip}]: Query #{Addressable::URI.unencode(@request.query_string)}: #{@property} #{@function} #{@queryValue} / products not found")
        @response.status = ARC_ODATA::API_RESOURCE_NOT_FOUND
        @response.headers['Message']  = "#{@queryValue} / products not found"
     else

        if @property != nil then
           @logger.info("[ARC_210] User #{@user} [#{@request.ip}]: Query #{Addressable::URI.unencode(@request.query_string)}: #{@property} #{@function} #{@queryValue} $skip = #{@skip} $top = #{@top} / #{aFile.to_a.length - @skip} product(s) found")
        else
           @logger.info("[ARC_210] User #{@user} [#{@request.ip}]: Query #{Addressable::URI.unencode(@request.query_string)}: #{@option} #{@queryValue} $skip = #{@skip} $top = #{@top} / #{aFile.to_a.length - @skip} product(s) found")
        end

        if @orderby != nil then
           if ARC_ODATA::oData2Model(@orderby) == false then
              @logger.warn("$orderby #{@orderby} not supported")
              response = ARC_ODATA::oDataQueryResponse(aFile.to_a, @option, @skip, @top)
           else
              # @logger.info("Sorting results by #{ARC_ODATA::oData2Model(@orderby)} #{@order}")
              if @isDebugMode == true then
                 @logger.debug("Sorting results by #{ARC_ODATA::oData2Model(@orderby)} #{@order}")
              end
              response = ARC_ODATA::oDataQueryResponse(aFile.order("#{ARC_ODATA::oData2Model(@orderby)} #{@order}").to_a, @option, @skip, @top)
           end
        else
           if @isDebugMode == true then
              @logger.debug("results   => #{aFile}")
              @logger.debug("option    => #{@option}")
              @logger.debug("skip      => #{@skip}")
              @logger.debug("top       => #{@top}")
           end
           response = ARC_ODATA::oDataQueryResponse(aFile.to_a, @option, @skip, @top)
        end

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

     ## ------------------------------------------

   end

## -------------------------------------------------------

def generateReport(result, elapsedTime)

   json     = nil
   bSuccess = nil
   nResults = nil

   begin
      json     = JSON.parse(result)
      nResults = json["value"].length
      bSuccess = true
   rescue Exception => e
      nResults = 0
      bSuccess = false
   end

   # JSON snake convention
   hRequest = Hash.new
   hRequest["username"]                 = @user
   hRequest["ip"]                       = @request.ip
   hRequest["url"]                      = Addressable::URI.unencode(@request.url)
   hRequest["query"]                    = Addressable::URI.unencode(@request.query_string)
   hRequest["query_date"]               = DateTime.now
   hRequest["query_elapsed_time"]       = elapsedTime
   hRequest["result_values"]            = nResults
   hRequest["success"]                  = bSuccess

   reportName = "/data/adgs/auxip/report/auxip_query_report_#{Time.now.strftime("%Y%m%dT%H%M%S.%L")}_#{Thread.current.object_id}.json"

   begin
      File.write(reportName, hRequest.to_json)
      @logger.info("[ARC_XXX] User #{@user} [#{@request.ip}]: Generated query report #{reportName}")
   rescue Exception => e
      @logger.error("[ARC_XXX] User #{@user} [#{@request.ip}]: Cannot generate query report #{reportName}" )
   end

end
## -------------------------------------------------------

private

   ## -------------------------------------------------------

   ##  $orderby=PublicationDate asc&$format=json&
   ## $select=Name,Id,IngestionDate,PublicationDate,Online,ContentLength,EvictionDate,ContentDate&
   ## $filter=contains(Name,'S2A') and PublicationDate ge 2021-06-29T15:00:00.000
   def parseQuery(query_string)

      @logger.info("[ARC_209] User #{@user} [#{@request.ip}]: Processing query: #{query_string}")

      ## -------------------------------
      ##
      ## This case is for the pure $count without $filter query
      ## https://185.52.193.141:4567/adgs/odata/v1/Products/$count?

      if query_string.include?("$filter") == false and query_string.include?("$count") == true then
         @logger.debug("$count request")
         val = ArchivedFile.count
         @response.content_type         = "text/plain"
         @response.headers['Message']   = "The Count von Count counted #{val.to_s}"
         @logger.debug("$count result = #{val.to_s}")
         return val.to_s
      end

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
         if @isDebugMode == true then
            @logger.debug("skip => #{@skip}")
         end
      end

      ## $top
      if query_string.include?("$top") == true then
         @top   = "#{query_string.split("$top=")[1]}"
         if @top.include?("&") == true then
            @top = @top.dup.split("&")[0].to_i
         else
            @top = @top.dup.to_i
         end
         if @isDebugMode == true then
            @logger.debug("top => #{@top}")
         end
      end

      ## $orderby
      if query_string.include?("$orderby") == true then
         @orderby   = "#{query_string.split("$orderby=")[1]}"
         if @orderby.include?("&") == true then
            @orderby = @orderby.dup.split("&")[0]
         end
         if @orderby.include?(" ") == true then
            @order   = @orderby.dup.split(" ")[1]
            @orderby = @orderby.dup.split(" ")[0]
         end

         if @isDebugMode == true then
            @logger.debug("$orderby => #{@orderby} #{@order}")
         end

         if ARC_ODATA::EDM_AUXIP_PRODUCT_PROPERTY.include?(@orderby) == false then
            raise "$orderby property #{@orderby} not supported"
         end

         if @order.downcase != "desc" and @order.downcase != "asc" then
            raise "$orderby property #{@orderby} with sorting #{@order} not supported"
         end
      end

      ## $count
      if query_string.include?("$count") == true then
         @option    = 'count'

         if @isDebugMode == true then
            @logger.debug("$count => true")
         end
      end

      ## -------------------------------

      ## -------------------------------
      ##
      ## Process the query

      ## From most restrictive conditions to simpler ones

      ## query by expand alone
      if query_string.include?("$expand") == true and query_string.include?("&") == false then
         return parseQueryExpand(query_string)
      end

      ## query by count alone
      if query_string.include?("$count") == true and query_string.include?("&") == false then
         return parseQueryCount(query_string)
      end

      ## query by date / weak constrain
      if (query_string.include?("(") == false or \
         query_string.include?(")") == false) and \
         query_string.include?("$filter") == true then
         return parseQueryDate(query_string)
      end

#      ## query by count plus filter
#      if query_string.include?("$count") == true and query_string.include?("&") == true then
#         return parseQueryCountFilter(query_string)
#      end

      ## no $filter choice
      if query_string.include?("$filter") == false then
         return true
      end

      ## -------------------------------


      @filterParam   = "#{query_string.split("$filter=")[1]}"
      @queryValue    = @filterParam.split(",")[1].split(")")[0]
      @property      = @filterParam.split("(")[1].split(",")[0]

      if @filterParam.include?("startswith") == true then
         @function   = "startswith"
         @queryValue = "#{@queryValue.dup.gsub!("'","")}%"
         return true
      end

      if @filterParam.include?("endswith") == true then
         @function   = "endswith"
         @queryValue = "#{@queryValue.dup.gsub!("'","")}%"
         return true
      end

      if @filterParam.include?("contains") == true or @filterParam.include?("substringof") == true then
         @function   = "contains"
         @queryValue = "#{@queryValue.dup.gsub!("'","")}%"
         return true
      end
      @logger.error("[ARC_XXX] FilterParam #{@filterParam} not supported")
      return false
   end

   ## -------------------------------------------------------

   ## $filter=contains(Name,'S2A') and PublicationDate ge 2021-06-29T15:00:00.000
   def execQueryComplex(query_string)
      if @isDebugMode == true then
         @logger.debug("execQueryComplex #{query_string}")
      end
      query    = query_string.split("$filter=")[1]
      query    = query.dup.split(" and ")
      results  = nil

      query.each{|condition|

         if condition.include?("Name") == true then
            value   = getQueryValueName(condition)
            if results == nil then
               results = ArchivedFile.where("name LIKE ?", value)
            else
               results = results.where("name LIKE ?", value)
            end
            puts "#{condition} => #{results}"
         end

         if condition.include?('PublicationDate') == true or condition.include?('ContentDate/Start') == true or \
            condition.include?('ContentDate/End') == true then
            value    = getQueryValueDate(condition)
            operator = getQueryOperator(condition)
            property = getQueryProperty(condition)
            if @isDebugMode == true then
               @logger.debug(self.str2date(value))
               @logger.debug(ARC_ODATA::filterOperations2Model(operator))
               @logger.debug(ARC_ODATA::oData2Model(property))
            end

            if results == nil then
               results = ArchivedFile.where("#{ARC_ODATA::oData2Model(property)} #{ARC_ODATA::filterOperations2Model(operator)} ?", self.str2date(value))
            else
               results = results.where("#{ARC_ODATA::oData2Model(property)} #{ARC_ODATA::filterOperations2Model(operator)} ?", self.str2date(value))
            end

            if @isDebugMode == true then
               @logger.debug("#{condition} => #{results}")
            end
         end
      }
      return results
   end
   ## -------------------------------------------------------

   ## /odata/v1/Products?$filter=PublicationDate%20gt%202020-05-15T00:00:00.000Z
   ## /odata/v1/Products?$count=true&$filter=PublicationDate%20gt%202020-05-15T00:00:00.000Z
   ## /odata/v1/Products?$filter=ContentDate/Start gt 2019-05-15T00:00:00.000Z
   ## /odata/v1/Products?$filter=ContentDate/Start gt 2019-05-15T00:00:00.000Z and ContentDate/End lt 2019-05-16T00:00:00.000Z
   def parseQueryDate(query_string)
      if @isDebugMode == true then
         @logger.debug("parseQueryDate #{query_string}")
      end

      bRet = false

      @filterParam   = "#{Addressable::URI.unencode(query_string).split("$filter=")[1]}"

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

      ## OBSOLETE CODE
##       if @filterParam.include?("ContentDate/Start") == true and @filterParam.include?("ContentDate/End") == true then
##          @property   = Array.new
##          @function   = Array.new
##          @queryValue = Array.new
##
##          @property   << "ContentDate/Start"
##          @function   << @filterParam.split("ContentDate/Start ")[1].split(" ")[0]
##          @queryValue << @filterParam.split("ContentDate/Start ")[1].split(" ")[1]
##
##          @property   << "ContentDate/End"
##          @function   << @filterParam.split("ContentDate/End ")[1].split(" ")[0]
##          @queryValue << @filterParam.split("ContentDate/End ")[1].split(" ")[1]
##
##       end

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
      @queryValue    = "#{Addressable::URI.unencode(query_string).split("$count")[1]}"

      if @isDebugMode == true then
         @logger.debug("parseQueryCount #{@option} #{@queryValue}")
      end

      return true

   end
   ## -------------------------------------------------------


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
         if @isDebugMode == true then
            @logger.debug("parseQueryExpand => expand => #{@expandEntity} not supported")
         end
         return false
      end

      if @isDebugMode == true then
         @logger.debug("parseQueryExpand => expand => #{@expandEntity}")
      end
      return bRet
   end
   ## -------------------------------------------------------

end ## class

## ===================================================================


end ## module
