#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #SinatraControllerOData class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Mini Archive Component (MinArc)
### 
### Git: $Id: SinatraControllerOData,v  bolf Exp $
###
### module ARC_ODATA
###
#########################################################################

require 'sinatra'
require 'addressable'

require 'cuc/Converters'

require 'ctc/API_MINARC_OData'

require 'arc/MINARC_DatabaseModel'

## ===================================================================

module ARC

class SinatraControllerBase

   include CUC::Converters
   ## ------------------------------------------------------
   
   ## Class contructor
   def initialize(sinatra_app, logger = nil, isDebug = false)
      @app           = sinatra_app
      @params        = sinatra_app.params
      @request       = sinatra_app.request
      @response      = sinatra_app.response
      @user          = @request.env["REMOTE_USER"]
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

   def getQueryValueName(query)
      return "#{query.dup.split(",")[1].split(")")[0].gsub!("'","")}%"
   end
   ## ------------------------------------------------------

   def getQueryValueDate(query)
      return query.dup.split(" ")[2]
   end
   ## ------------------------------------------------------

   def getQueryOperator(query)
      return query.dup.split(" ")[1]
   end
   ## ------------------------------------------------------

   def getQueryProperty(query)
      return query.dup.split(" ")[0]
   end
   ## ------------------------------------------------------

end ## class

## ===================================================================

end ## module


