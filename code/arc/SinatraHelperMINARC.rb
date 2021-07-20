#!/usr/bin/env ruby

require 'rack/ssl'
require 'sinatra'


require 'arc/MINARC_DatabaseModel'

module ARC

   module ApplicationHelper

      ## ------------------------------------------------------

      def authenticate
         @auth ||= Rack::Auth::Basic::Request.new(request.env)
         username,password = @auth.credentials
         
         env['REMOTE_USER'] = username
         
         theUser = User.find_by name: username 
         
         if theUser != nil then
            return theUser.authenticate(password)
         else
            return false
         end
      end
      
      ## ------------------------------------------------------
      
   end
   

end
