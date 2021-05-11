#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #FileArchiver class
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === Mini Archive Component (MinArc)
## 
## Git: $Id: MINARC_Client.rb,v 1.12 2008/09/24 16:09:19 decdev Exp $
##
## module MINARC
##
#########################################################################

require 'benchmark'
require 'json'

require 'ctc/WrapperCURL'
require 'arc/MINARC_API'
require 'arc/ReadMinarcConfig'

module ARC

class MINARC_Client

   include Benchmark
   include CTC::WrapperCURL

   ## ------------------------------------------------  
   
   ## Class contructor
   ## debug: boolean. If true it shows debug info.
   def initialize(logger = nil, debugMode = false)
      @user                = nil
      @pass                = nil
      @logger              = logger
      @isDebugMode         = debugMode
      @isProfileMode       = false
      checkModuleIntegrity
      config               = ReadMinarcConfig.instance
      @user                = config.getClientUser
      @pass                = config.getClientPassword
      @verifyPeerSSL       = config.getClientVerifyPeerSSL
   end
   ## ------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "MINARC_Client debug mode is on"
      puts "MINARC_Server is #{@minArcServer}"
   end
   # ------------------------------------------------

   # Set the flag for profiling execution time.
   def setProfileMode
      @isProfileMode = true
      puts "MINARC_Client profile mode is on"
      puts
   end
   # ------------------------------------------------
   
   def getVersion
      return getURL("#{@minArcServer}#{API_URL_VERSION}", @verifyPeerSSL, @user, @pass, @isDebugMode)
   end
   ## -------------------------------------------------

   def storeFile(full_path_filename, fileType, bIsDelete, destination = nil)
      hParams = Hash.new
      
      hParams["--type"] = fileType
      
      if bIsDelete == true then
         hParams["--delete"] = ""
      end
      
      if destination != nil then
         hParams["--Location"] = destination
      end
      
      newVal = full_path_filename.dup
            
      # ret = postFile("#{@minArcServer}#{API_URL_STORE}", full_path_filename, hParams, @isDebugMode)
      ret = postFile("#{@minArcServer}#{API_URL_STORE}", @verifyPeerSSL, @user, @pass, newVal, hParams, @isDebugMode)
      
      if ret == false then
         puts
         puts "Failed to archive #{full_path_filename} :-("
         puts
      else
         full_path_filename.replace(newVal)
      end
      
      return ret
   end
   ## -------------------------------------------------
   
   def listFile_By_Filetype(filetype)
      url = "#{@minArcServer}#{API_URL_LIST_FILETYPE}/#{filetype}"
      if @isDebugMode == true then
         puts
         puts "MINARC_Client::listFile_By_Filetype => #{url}"
         puts
      end
      return getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode)   
   end
   # ------------------------------------------------
   
   def listFile_By_Name(filename)
      url = "#{@minArcServer}#{API_URL_LIST_FILENAME}/#{filename}"
      if @isDebugMode == true then
         puts
         puts "MINARC_Client::listFile_By_Name => #{url}"
         puts
      end
      return getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode)
   end
   ## -------------------------------------------------
   
   def retrieveFile(filename)
      url = "#{@minArcServer}#{API_URL_RETRIEVE}/#{filename}"
      if @isDebugMode == true then
         puts
         puts "MINARC_Client::retrieveFile => #{url}"
         puts
      end
      # return getDirtyFile_obsoleteCurl(url, filename, @isDebugMode)
      return getFile(url, @verifyPeerSSL, @user, @pass, filename, @isDebugMode)
   end
   ## -------------------------------------------------
   
   def deleteFile(filename)
      url = "#{@minArcServer}#{API_URL_DELETE}/#{filename}"
      if @isDebugMode == true then
         puts
         puts "MINARC_Client::deleteFile => #{url}"
         puts
      end
      return getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode)
   end
   # ------------------------------------------------
   
   def getAllFileTypes
      url = "#{@minArcServer}#{API_URL_GET_FILETYPES}"
      if @isDebugMode == true then
         puts
         puts "MINARC_Client::getAllFileTypes => #{url}"
         puts
      end
      return getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode)
   end
   # ------------------------------------------------
   
   def statusFileType(filetype)
      url = "#{@minArcServer}#{API_URL_STAT_FILETYPES}/#{filetype}"
      if @isDebugMode == true then
         puts
         puts "MINARC_Client::statusFileType => #{url}"
         puts
      end
      return getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode)   
   end
   ## ------------------------------------------------------

   def statusGlobal
      url = "#{@minArcServer}#{API_URL_STAT_GLOBAL}"
      if @isDebugMode == true then
         puts
         puts "MINARC_Client::statusGlobal => #{url}"
         puts
      end
      return JSON.parse(getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode))
   end
   ## ------------------------------------------------------
   
   def statusFileName(filename)
      url = "#{@minArcServer}#{API_URL_STAT_FILENAME}/#{filename}"
      if @isDebugMode == true then
         puts
         puts "MINARC_Client::statusFileName => #{url}"
         puts
      end
      # return JSON.parse(getURL(url, @isDebugMode))
      return getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode) 
   end
   # ------------------------------------------------
   
private

   # -------------------------------------------------------------
   # Check that everything needed by the class is present.
   # -------------------------------------------------------------
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
   # --------------------------------------------------------
      
end # class

end # module
# =================================================
