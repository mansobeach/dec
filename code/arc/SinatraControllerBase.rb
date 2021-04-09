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


end ## class

## ===================================================================

end ## module


