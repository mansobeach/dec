#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #ODataClientDHUS class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: ODataClientBase.rb,v 1.25 bolf Exp $
###
### This class is an OData client
###
###
#########################################################################

require 'rubygems'
require 'getoptlong'
require 'net/http'
require 'date'
require 'nokogiri'
require 'json'
require 'filesize'

require 'cuc/Log4rLoggerFactory'

## Dirty thing regarding OpenHub download with uuid in single quote
require 'ctc/API_DHUS'

require 'dec/DEC_Environment'

module DEC

class ODataClientBase

   include CUC::DirUtils
   include DEC
   
   ## -------------------------------------------------------------
   
   def initialize(user, password, query, creationtime, datetime, sensingtime, full_path_dir, download, logger)
      @user          = user
      @password      = password      
      @query         = query.upcase
      @creationtime  = creationtime
      @datetime      = datetime
      @sensingtime   = sensingtime
      @full_path_dir = full_path_dir
      @download      = download
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

      nParams      = @query.split(":").length
      @system      = @query.split(":")[0]
      @mission     = @query.split(":")[1]
      @datatake    = @query.split(":")[2]
      @param       = nil
      begin
         @param       = @query.split(":")[3]
      rescue Exception => e
         @logger.error(e.to_s)
         raise e
      end
            
   end
   ## -----------------------------------------------------------
  
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      @logger.debug("ODataClient debug mode is on")
   end
   ## -----------------------------------------------------------


   ## -----------------------------------------------------------

   def exec_query

      ## --------------------------------------------
      if @isDebugMode == true then
         @logger.debug("exec_query => #{@system} : #{@mission} : #{@datatake} ; #{@param} ; #{@condition}")
      end
      ## --------------------------------------------

      ## query count of products
      
      ret = queryCount(@urlCount, @condition)
      
      if @isDebugMode == true then
         @logger.debug("Found #{@iTotal} items")
      end
      
      if @iTotal == -1 or ret == false then
         return false
      end
                  
      ## --------------------------------------------
      ##
      ## Product Select      
      ret = querySelect(@mission, @urlSelect, @urlPaging, @condition, @datatake)           
      return ret
      
   end

   ## -------------------------------------------------------------
 private
   
   ## -------------------------------------------------------------

   ## --------------------------------------------
   ##
   ## Product Select 

   def querySelect(dhus_instance, urlSelect, urlPage, condition, mission)
      
      uri  = URI.parse(urlSelect)  
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 600
      http.read_timeout = 600
      http.use_ssl      = true
      
      ###############################################
      ## THIS SHOULD BECOME A PARAMETER
      http.verify_mode  = OpenSSL::SSL::VERIFY_NONE
      ###############################################
      
      
      request  = Net::HTTP::Get.new(uri.request_uri)   
      request.basic_auth(@user, @password)
      
      iPending = @iTotal
      iSkip    = 0

      arrResponseBody = Array.new

      ## --------------------------------------------

      if @datetime != nil then
         if @bUseDateTime == true then
            urlSelect = "#{urlSelect.dup}#{condition} and #{@attributeDateAvailable} ge datetime'#{@datetime}'"
         else
            urlSelect = "#{urlSelect.dup}#{condition} and #{@attributeDateAvailable} ge #{@datetime}"
         end
      end

      if @sensingtime != nil then
         if @bUseDateTime == true then
            urlSelect = "#{urlSelect.dup}#{condition} and ContentDate/Start ge datetime'#{@sensingStart}' and ContentDate/Start lt datetime'#{@sensingEnd}'"
         else
            urlSelect = "#{urlSelect.dup}#{condition} and ContentDate/Start ge #{@sensingStart} and ContentDate/Start lt #{@sensingEnd}"
         end
      end

      if @creationtime != nil then
         if @bUseDateTime == true then
            urlSelect = "#{urlSelect.dup}#{condition} and #{@attributeDateAvailable} ge datetime'#{@creationStart}' and #{@attributeDateAvailable} lt datetime'#{@creationEnd}'"
         else
            urlSelect = "#{urlSelect.dup}#{condition} and #{@attributeDateAvailable} ge #{@creationStart} and #{@attributeDateAvailable} lt #{@creationEnd}"
         end
      end

      ## --------------------------------------------
   
      ## --------------------------------------------
   
      uri      = URI.parse(urlSelect)
      cmdCurl  = "curl -k -u #{@user}:#{@password} \'#{uri.scheme}://#{uri.host}:#{uri.port}/#{uri.request_uri}\'"

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
            @logger.error("[DEC_614] I/F #{@system}: Failed request #{uri.scheme}://#{uri.host}#{uri.request_uri}")
            @logger.error(e.to_s)
            iRetry   = iRetry + 1
            response = nil
            sleep(5.0)
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
      begin    
         createFileMetadata(dhus_instance, mission, response.body, iSkip)
      rescue Exception => e
         return false
      end
      
      if @download == true then
         downloadItems(response.body)
      end
         
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

         urlPaging   = "#{urlPage}#{iSkip}#{condition}"

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
            if @bUseDateTime == true then
               urlPaging = "#{urlPaging.dup} and #{@attributeDateAvailable} ge datetime'#{@datetime}'"
            else
               urlPaging = "#{urlPaging.dup} and #{@attributeDateAvailable} ge #{@datetime}"
            end
         end

         if @sensingtime != nil then
            if @bUseDateTime == true then
               urlPaging = "#{urlPaging.dup} and ContentDate/Start ge datetime'#{@sensingStart}' and ContentDate/Start lt datetime'#{@sensingEnd}'"
            else
               urlPaging = "#{urlPaging.dup} and ContentDate/Start ge #{@sensingStart} and ContentDate/Start lt #{@sensingEnd}"
            end
         end

         if @creationtime != nil then
            if @bUseDateTime == true then
               urlPaging = "#{urlPaging.dup} and #{@attributeDateAvailable} ge datetime'#{@creationStart}' and #{@attributeDateAvailable} lt datetime'#{@creationEnd}'"
            else
               urlPaging = "#{urlPaging.dup} and #{@attributeDateAvailable} ge #{@creationStart} and #{@attributeDateAvailable} lt #{@creationEnd}"
            end
         end

         ## -----------------------------------------
      
         uri         = URI.parse(urlPaging)    
         cmdCurl     = "curl -k -u #{@user}:#{@password} \'#{uri.scheme}://#{uri.host}:#{uri.port}/#{uri.request_uri}\'"
         
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
               @logger.error("[DEC_614] I/F #{@system}: Failed #{uri.scheme}://#{uri.host}#{uri.request_uri}")
               @logger.error(e.to_s)
               if @isDebugMode == true then
                  @logger.debug(e.backtrace)
               end               
               iRetry   = iRetry + 1
               response = nil
               @logger.warn("Retry [#{iRetry}] #{uri.scheme}://#{uri.host}#{uri.request_uri}")
               sleep(5.0)
            end
            
         end
         
         ## datatake is carrying the mission id
         createFileMetadata(dhus_instance, mission, response.body, iSkip)

         if @download == true then
            downloadItems(response.body)
         end

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
         if @bUseDateTime == true then
            urlCount = "#{urlCount}#{condition} and #{@attributeDateAvailable} ge datetime'#{@datetime}'"
         else
            urlCount = "#{urlCount}#{condition} and #{@attributeDateAvailable} ge #{@datetime}"
         end
      end

      if @sensingtime != nil then
         if @bUseDateTime == true then
            urlCount = "#{urlCount}#{condition} and ContentDate/Start ge datetime'#{@sensingStart}' and ContentDate/Start lt datetime'#{@sensingEnd}'"
         else
            urlCount = "#{urlCount}#{condition} and ContentDate/Start ge #{@sensingStart} and ContentDate/Start lt #{@sensingEnd}"
         end
      end

      if @creationtime != nil then
         if @bUseDateTime == true then
            urlCount = "#{urlCount}#{condition} and #{@attributeDateAvailable} ge datetime'#{@creationStart}' and #{@attributeDateAvailable} lt datetime'#{@creationEnd}'"
         else
            urlCount = "#{urlCount}#{condition} and #{@attributeDateAvailable} ge #{@creationStart} and #{@attributeDateAvailable} lt #{@creationEnd}"
         end
      end

      uri      = URI.parse(urlCount)
      cmdCurl  = "curl -k -u #{@user}:#{@password} \'#{uri.scheme}://#{uri.host}:#{uri.port}/#{uri.request_uri}\'"

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
      
      ###############################################
      ## THIS SHOULD BECOME A PARAMETER
      http.verify_mode  = OpenSSL::SSL::VERIFY_NONE
      ###############################################
      
      request              = Net::HTTP::Get.new(uri.request_uri)   
      request.basic_auth(@user, @password)
      
      response = nil   
      iRetry   = 0
      
      while response == nil and iRetry <= 5 do
      
         begin
            if iRetry != 0 then
               sleep(5.0)
               @logger.info("[DEC_255] I/F #{@system}: Retry [#{iRetry}] #{uri.scheme}://#{uri.host}#{uri.request_uri}")

            end
            response = http.request(request)
 
            if @isDebugMode == true then
               @logger.debug(response.code)
               @logger.debug(response.message)
               @logger.debug(response.body)
            end
         rescue Exception => e
            @logger.error("[DEC_614] I/F #{@system}: Failed request #{urlCount}")
            @logger.error("[DEC_614] I/F #{@system}: #{e.to_s}")
            if @isDebugMode == true then
               @logger.debug(e.backtrace)
            end
            iRetry   = iRetry + 1
            response = nil
         end
      end
            
      ## --------------------------------------------

      ## DHUS Openhub replies directly without any JSON or formatting

      if response == nil then 
         return false
      end
      
      @iTotal  = processCountReply(response.body)
      
      if @iTotal == -1 or response.code != DHUS::API_RESOURCE_FOUND then
         @logger.error("[DEC_614] I/F #{@system}: Error in request #{uri.request_uri} #{response.code} / #{response.message} / #{response.body}")
         return false
      end
                  
      ## --------------------------------------------
      
      return true

   end
   
   ## -------------------------------------------------------------

   ## create File with the query results
   def createFileMetadata(service_instance, mission, data, iSkip)
   
      prevDir = Dir.pwd
      
      begin
         Dir.chdir(@full_path_dir)
      rescue Exception => e
         @logger.error("[DEC_799] I/F #{@system}: #{e.to_s}")
         raise e
      end
      
      filename = ""
   
      if @datetime != nil then
         filename = "DEC_OPER_OP#{@system.slice(0,4)}_#{mission.ljust(3,"_")}_ADGS_#{@currentDate}_V#{@datetime.gsub("-","").gsub(":","").split(".")[0]}_#{@iTotal}_#{iSkip.to_s.rjust(@iTotal.to_s.length,'0')}.#{@format}"
      end

      if @creationtime != nil then
         if service_instance == "GNSS" then
            filename = "DEC_OPER_AGNSS_#{mission.ljust(3,"_")}_ADGS_#{@currentDate}_V#{@creationStart.gsub("-","").gsub(":","").split(".")[0]}_#{@creationEnd.gsub("-","").gsub(":","").split(".")[0]}_#{@iTotal}_#{iSkip.to_s.rjust(@iTotal.to_s.length,'0')}.#{@format}"
         else
            filename = "DEC_OPER_OP#{@system.slice(0,4)}_#{mission.ljust(3,"_")}_ADGS_#{@currentDate}_V#{@creationStart.gsub("-","").gsub(":","").split(".")[0]}_#{@creationEnd.gsub("-","").gsub(":","").split(".")[0]}_#{@iTotal}_#{iSkip.to_s.rjust(@iTotal.to_s.length,'0')}.#{@format}"
         end
      end
   
      if @sensingtime != nil then
         filename = "DEC_OPER_OP#{@system.slice(0,4)}_#{mission.ljust(3,"_")}_ADGS_#{@currentDate}_V#{@sensingStart.gsub("-","").gsub(":","").split(".")[0]}_#{@sensingEnd.gsub("-","").gsub(":","").split(".")[0]}_#{@iTotal}_#{iSkip.to_s.rjust(@iTotal.to_s.length,'0')}.#{@format}"
      end
   
      if @creationtime == nil and @sensingtime == nil and @datetime == nil then
         filename = "DEC_OPER_OP#{@system.slice(0,4)}_#{mission.ljust(3,"_")}_ADGS_#{@currentDate}_#{@iTotal}_#{iSkip.to_s.rjust(@iTotal.to_s.length,'0')}.#{@format}"
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
      @logger.info("[DEC_257] I/F #{@system}: created #{filename}")
      Dir.chdir(prevDir)
   end
   ## -------------------------------------------------------------

   ## process count reply from the http body
   def processCountReply(body)
      if body.include?("odata") == true then
         obj = JSON.parse(body)
         return obj["count"].to_i
      else
         return body.to_i   
      end      
   end
   ## -------------------------------------------------------------

   ## It gets the http body reply
   def downloadItems(body)
      if @isDebugMode == true then
         @logger.debug("ODataClient::downloadItems")
      end

      if body.include?("@odata") == true then
         obj = JSON.parse(body)
                  
         obj["value"].each{|item|
            if @isDebugMode == true then
               @logger.debug(item)
            end
            download(item["Id"], item["Name"], item["ContentLength"])
         }
         
         return obj["count"].to_i
      else
         doc = Nokogiri::XML(body)
         doc.css('m|properties').each{|item|
            if @isDebugMode == true then
               @logger.debug(item)
            end

            download(item.css('d|Id').text, item.css('d|Name').text, item.css('d|ContentLength').text.to_i)
         }
      end    
   end
   ## -------------------------------------------------------------

   ## cmd = "curl -k -L -J -O -v -u #{@user}:#{@password} \"https://90.84.179.7/odata/v1/Products(#{uuid})/\\$value\" "

   def download(uuid, name, size)
      if @isDebugMode == true then
         @logger.debug("ODataClient::download(#{uuid}, #{name}, #{size})")
      end

      @logger.info("[DEC_259] I/F #{@system}: downloading #{name} / #{Filesize.from("#{size/1000.0} KB").pretty}") #\""
      
      prevDir = Dir.pwd
      
      Dir.chdir(@full_path_dir)
   
      before = DateTime.now
   
      cmd = nil
      if @serviceRootUri.include?("dhus") == true then
         cmd = "curl --progress-bar -k -L -J -O -u #{@user}:#{@password} \"#{@serviceRootUri}/odata/v1/Products(\'#{uuid}\')/\\$value\""
      else
         cmd = "curl --progress-bar -k -L -J -O -u #{@user}:#{@password} \"#{@serviceRootUri}/odata/v1/Products(#{uuid})/\\$value\""
      end
   
      if @isDebugMode == true then
         @logger.debug(cmd)
      end
      
      ret      = system(cmd)
      
      after    = DateTime.now
      elapsed  = ((after - before) * 24 * 60 * 60).to_f
      rate     = ((size/1000000.0)/elapsed).to_f

      if ret == false then
         @logger.error("[DEC_667] I/F #{@system}: failed download #{name} / #{rate.round(2)} MiB/s") #\""
      else
         @logger.info("[DEC_260] I/F #{@system}: downloaded #{name} / #{Filesize.from("#{size/1000.0} KB").pretty} / #{rate.round(2)} MiB/s") #\""
      end
       

     
      Dir.chdir(prevDir)
      return ret
   end
   ## -------------------------------------------------------------

end # class

end # module


