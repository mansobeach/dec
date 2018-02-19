#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileArchiver class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: MINARC_Client.rb,v 1.12 2008/09/24 16:09:19 decdev Exp $
#
# module MINARC
#
#########################################################################

require 'benchmark'

require 'ctc/WrapperCURL'
require 'arc/MINARC_API'

module ARC

class MINARC_Client

   include Benchmark
   include CTC::WrapperCURL

   #------------------------------------------------  
   
   # Class contructor
   # debug: boolean. If true it shows debug info.
   def initialize(debugMode = false)
      @isDebugMode         = debugMode
      @isProfileMode       = false
      checkModuleIntegrity
   end
   #------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "MINARC_Client debug mode is on"
   end
   #------------------------------------------------

   # Set the flag for profiling execution time.
   def setProfileMode
      @isProfileMode = true
      puts "MINARC_Client profile mode is on"
      puts
   end
   #------------------------------------------------
   
   def getVersion
      return getURL("#{@minArcServer}#{API_URL_VERSION}", @isDebugMode)
   end
   #------------------------------------------------

   def storeFile(full_path_filename, fileType, bIsDelete)
      hParams = Hash.new
      
      hParams["--type"] = fileType
      
      if bIsDelete == true then
         hParams["--delete"] = ""
      end
      
      ret = postFile("#{@minArcServer}#{API_URL_STORE}", full_path_filename, hParams, @isDebugMode)
      
      if ret == false then
         puts
         puts "Failed to archive #{full_path_filename} :-("
         puts
      end
      
      return ret
   end
   #------------------------------------------------
   
   def retrieveFile(filename)
      url = "#{@minArcServer}#{API_URL_RETRIEVE}/#{filename}"
      if @isDebugMode == true then
         puts
         puts "MINARC_Client::retrieveFile => #{url}"
         puts
      end
      return getFile(url, filename)
   end
   #------------------------------------------------
   
private

   #-------------------------------------------------------------
   # Check that everything needed by the class is present.
   #-------------------------------------------------------------
   def checkModuleIntegrity
      
      if ENV['MINARC_SERVER'] then
         @minArcServer = ENV['MINARC_SERVER']
      else
         puts
         puts "MINARC_SERVER environment variable is not defined !\n"
         puts("MINARC_Client::checkModuleIntegrity FAILED !\n\n")
         exit(99)
      end

   end
   #--------------------------------------------------------
      
   
   
end # class

end # module
#=================================================
