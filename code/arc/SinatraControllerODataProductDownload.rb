#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #SinatraControllerOData class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Mini Archive Component (MinArc)
### 
### Git: $Id: SinatraControllerODataProductDownload,v 1.8 2008/11/26 12:40:47 bolf Exp $
###
### module ARC_ODATA
###
#########################################################################

require 'sinatra'

require 'cuc/Converters'

require 'arc/SinatraControllerBase'
require 'arc/MINARC_API_OData'
require 'arc/MINARC_DatabaseModel'

module ARC_ODATA

## ===================================================================


## ===================================================================

class ControllerODataProductDownload < ARC::SinatraControllerBase

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
        
        if @isDebugMode == true then
           @logger.debug("aFile #{aFile} / #{@uuid}")
        end
        
        if aFile == nil then
           @logger.info("[ARC_200] User #{@user}: Requested #{@uuid} / File not found ; [#{@request.ip}]") 
           @response.status = ARC_ODATA::API_RESOURCE_NOT_FOUND
           @response.headers['Message']  = "#{@uuid} not found"
        else
           @logger.info("[ARC_200] User #{@user}: Requested #{@uuid} / #{aFile.filename} ; [#{@request.ip}]") 
           full_path = "#{aFile.path}/#{aFile.filename}"
           @response.status = ARC_ODATA::API_RESOURCE_FOUND
           @response.headers['Message']  = "Woo-hoo ; I got my head checked ; By a jumbo jet ; It wasn't easy ; But nothing is ... No"
           @app.send_file(full_path, :filename => aFile.filename)
        end
     else
        @logger.error("[ARC_778] User #{@user}: Query #{@request.query_string} not valid / or badly managed: #{@request.path_info} ; [#{@request.ip}]") 
        @response.status = ARC_ODATA::API_BAD_REQUEST
        @response.headers['Message'] = "property #{@property} not supported"
     end
  end
  ## -------------------------------------------------------
  
private

   ## -------------------------------------------------------
   
   def parseQuery(path_info)
      @logger.debug("SinatraControllerOData::parseQuery => #{path_info}")
      @uuid       = path_info.split("(")[1].split(")")[0]
      @bValue     = path_info.split("$")[1].include?("value")
      @property   = "$#{path_info.split("$")[1]}"
   end
  
   ## -------------------------------------------------------
  
end ## class

## ===================================================================
## ===================================================================


end ## module



