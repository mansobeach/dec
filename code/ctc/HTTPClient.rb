#!/usr/bin/env ruby

#########################################################################
#
# = Ruby source for #HTTPClient class
#
# = Written by DEIMOS Space S.L. (bolf)
#
# = Data Exchange Component -> Common Transfer Component
# 
# CVS:
#   
# = This class is an HTTP Client for sending the requests to the MUIS I/F EOLI.
# == This class wraps the ruby net:http library.
#
#########################################################################

# This module contains methods for performing HTTP Requests


require 'net/http'

module CTC

class HTTPClient

   #-------------------------------------------------------------
   
   # Class constructor.
   # IN Parameters:
   # * string Hostname
   # * integer port
   # * booleane debugmode
   def initialize(httpServer, port, debugMode = false)
      # see if proxy environment variable is set, and in case extract
      # address and port number
      proxy = ENV['http_proxy']
      if (proxy != nil) 
        uri = URI.parse(proxy)
        p_addr = uri.host
        p_port = uri.port
      else 
        p_addr = nil
        p_port = nil
      end

      @http = Net::HTTP.new(httpServer, port, p_addr, p_port)
      if debugMode == true then
         @http.set_debug_output $stderr
         setDebugMode
      end
      begin      
         @http.start
      rescue Exception => exception
         puts "HTTPClient::initialize FATAL ERROR"
         puts exception.message
         if debugMode == true then
            puts exception.backtrace
         end
         exit(99)
      end
      @headerParams = Hash.new
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "HTTPClient debug mode is on"
      @http.set_debug_output $stderr
   end
   #-------------------------------------------------------------

   # Unset the flag for debugging.
   def unsetDebugMode
      @isDebugMode = false
      puts "HTTPClient debug mode is off"
      @http.set_debug_output nil
   end
   #-------------------------------------------------------------

   def addHTTPHeaderParam(param, value)
      @headerParams[param] = value
   end
   #-------------------------------------------------------------
   
   def getHTTPHeaderParams
      return @headerParams
   end  
   #-------------------------------------------------------------
   
   def setHTTPHeaders(hashHeaders)
      @headerParams = hashHeaders
   end
   #-------------------------------------------------------------
   
   # Perform a HTTP GET request. 
   def requestGET(strPath, headerParams=nil)
      if @isDebugMode == true then
         puts "GET Request - #{strPath}"
	      if headerParams != nil then
	         headerParams.each{|key, value|
	            print "#{key} -> #{value} |"
	         }
         else
	         @headerParams.each{|key, value|
	            print "#{key} -> #{value} |"
	         }
         end
      end
      begin
         @response = @http.get(strPath, headerParams)
      rescue Exception => exception
         puts
         puts
         puts "Error in HTTP::GET operation !  :-("
         puts
         if @isDebugMode == true then
            puts "----------------------------"
            puts "Debug info:"
            puts exception.backtrace
            puts "----------------------------"
            puts
         end
         exit(99)
      end
      return @response
   end
   #-------------------------------------------------------------
   
   # Perform a HTTP POST request. 
   def requestPOST(strPath, strData, headerParams=nil)
      @reponse = ""
      if @isDebugMode == true then
         print "POST Request - Path -> #{strPath}  | Data -> #{strData}  "
         if headerParams != nil then
	         headerParams.each{|key, value|
	            print "#{key} -> #{value} |"
	         }
         else
	         @headerParams.each{|key, value|
	            print "#{key} -> #{value} |"
	         }
	      end
	      puts
      end
      
      begin
         if headerParams != nil then
            @response = @http.post(strPath, strData, headerParams, "")
         else
            @response = @http.post(strPath, strData, @headerParams, "")
         end
      rescue Exception => exception
         puts "Fatal Error in HTTPClient::requestPOST"
         puts exception.message
         puts
         if @isDebugMode == true then
            puts exception.backtrace
         end
         exit(99)
      end
      return @response
   end
   #-------------------------------------------------------------
   
   # send_request sends a HTTP Request
   # IN Parameters:
   # * string Oper  : HTTP Operation, GET or POST
   # * string Path  : path of the servlet
   # * string Data  : Arguments of the Operation
   # * hash hdrPars : HTTP Header Parameters 
   def send_request(strOper, strPath, strData=nil, headerParams=nil)
      @response  = ""
      hdrParams = nil
      if headerParams != nil then
         hdrParams = headerParams
      else
         hdrParams = @headerParams
      end
    
      case strOper.upcase
         when "GET"    then @response = requestGET(strPath, hdrParams)
         when "POST"   then @response = requestPOST(strPath, strData, hdrParams)
         else
	         puts "HTTP Operation #{strOper.upcase} not implemented !"
      end
          
      return @response
   end
   #-------------------------------------------------------------

private

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity                          
   end
   #-------------------------------------------------------------

end # class

end # module
