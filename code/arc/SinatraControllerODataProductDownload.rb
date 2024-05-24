#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #SinatraControllerOData class
###
### === Written by DEIMOS Space S.L.
###
### === Mini Archive Component (MinArc)
###
### Git: $Id: SinatraControllerODataProductDownload,v bolf Exp $
###
### module ARC_ODATA
###
#########################################################################

require 'json'
require 'arc/SinatraControllerBase'

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
           @logger.info("[ARC_200] User #{@user} [#{@request.ip}]: Requested #{@uuid} / File not found ")
           @response.status = ARC_ODATA::API_RESOURCE_NOT_FOUND
           @response.headers['Message']  = "#{@uuid} not found"
        else
           @logger.info("[ARC_200] User #{@user} [#{@request.ip}]: Requested #{@uuid} / #{aFile.filename}")
           full_path = "#{aFile.path}/#{aFile.filename}"
           @response.status = ARC_ODATA::API_RESOURCE_FOUND
           @response.headers['Message']  = "Woo-hoo ; I got my head checked ; By a jumbo jet ; It wasn't easy ; But nothing is ... No"
           before = nil
           begin
              before = DateTime.now
              @logger.info("before send_file")
              @app.send_file(full_path, :filename => aFile.filename)
              @logger.info("after send_file")
           ensure
              @logger.info("unsure block after send_file")
              aFile.last_access_date = Time.now
              aFile.access_counter   = aFile.access_counter + 1
              begin
                 aFile.save
              rescue Exception => e
                  @logger.error(e.to_s)
                  @logger.error("Could not update #{aFile.filename} last_access")
              end

              size     = File.size(full_path)
              after    = DateTime.now
              elapsed  = ((after - before) * 24 * 60 * 60).to_f
              rate     = ((size/1000000.0)/elapsed).to_f
              @logger.info("[ARC_201] User #{@user} [#{@request.ip}]: Served #{aFile.filename} ; #{rate.round(2)} MiB/s ")
              servedFile = ServedFile.new
              servedFile.ip               = @request.ip
              servedFile.username         = @user
              servedFile.filename         = aFile.filename
              servedFile.file_id          = @uuid
              servedFile.size             = size
              servedFile.download_elapsed = elapsed
              servedFile.download_date    = after
              servedFile.save
              # @logger.info("Download time #{elapsed} seconds")

              # snake convention
              hRequest = Hash.new
              hRequest["username"]                 = servedFile.username
              hRequest["ip"]                       = servedFile.ip
              hRequest["filename"]                 = servedFile.filename
              hRequest["uuid"]                     = servedFile.file_id
              hRequest["content_length"]           = servedFile.size
              hRequest["download_date"]            = servedFile.download_date
              hRequest["download_elapsed_time"]    = servedFile.download_elapsed
              hRequest["access_date"]              = aFile.last_access_date
              hRequest["access_counter"]           = aFile.access_counter

            reportName = "/data/adgs/auxip/report/auxip_download_report_#{Time.now.strftime("%Y%m%dT%H%M%S.%L")}_#{Thread.current.object_id}.json"

            begin
               File.write(reportName, hRequest.to_json)
               @logger.info("[ARC_XXX] User #{@user} [#{@request.ip}]: Generated download report #{reportName}")
            rescue Exception => e
               @logger.error("[ARC_XXX] User #{@user} [#{@request.ip}]: Cannot generate download report #{reportName}" )
            end

           end
        end
     else
        @logger.error("[ARC_778] User #{@user} [#{@request.ip}]: Query #{@request.query_string} not valid / or badly managed: #{@request.path_info} ")
        @response.status = ARC_ODATA::API_BAD_REQUEST
        @response.headers['Message'] = "property #{@property} not supported"
     end
  end
  ## -------------------------------------------------------

private

   ## -------------------------------------------------------

   def parseQuery(path_info)
      if @isDebugMode == true then
         @logger.debug("SinatraControllerODataProductDownload::parseQuery => #{path_info}")
      end
      @uuid       = path_info.split("(")[1].split(")")[0]
      @bValue     = path_info.split("$")[1].include?("value")
      @property   = "$#{path_info.split("$")[1]}"
   end

   ## -------------------------------------------------------

end ## class

## ===================================================================


end ## module
