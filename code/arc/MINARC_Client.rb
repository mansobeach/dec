#!/usr/bin/env ruby

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
      @logger.debug("MINARC_Client debug mode is on")
      @logger.debug("MINARC_Server is #{@minArcServer}")
   end
   # ------------------------------------------------

   # Set the flag for profiling execution time.
   def setProfileMode
      @isProfileMode = true
      @logger.debug("MINARC_Client profile mode is on")
   end
   # ------------------------------------------------
   
   def getVersion
      return getURL("#{@minArcServer}#{API_URL_VERSION}", @verifyPeerSSL, @user, @pass, @isDebugMode, @logger)
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
         @logger.debug("Failed to archive #{full_path_filename} :-(")
      else
         full_path_filename.replace(newVal)
      end
      
      return ret
   end
   ## -------------------------------------------------
   
   def listFile_By_Filetype(filetype)
      url = "#{@minArcServer}#{API_URL_LIST_FILETYPE}/#{filetype}"
      if @isDebugMode == true then
         @logger.debug("MINARC_Client::listFile_By_Filetype => #{url}")
      end
      return getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode, @logger)   
   end
   # ------------------------------------------------
   
   def listFile_By_Name(filename)
      url = "#{@minArcServer}#{API_URL_LIST_FILENAME}/#{filename}"
      if @isDebugMode == true then
         @logger.debug("MINARC_Client::listFile_By_Name => #{url}")
      end
      return getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode, @logger)
   end
   ## -------------------------------------------------
   
   def retrieveFile(filename)
      url = "#{@minArcServer}#{API_URL_RETRIEVE}/#{filename}"
      if @isDebugMode == true then
         @logger.debug("MINARC_Client::retrieveFile => #{url}")
      end
      # return getDirtyFile_obsoleteCurl(url, filename, @isDebugMode)
      return getFile(url, @verifyPeerSSL, @user, @pass, filename, @isDebugMode)
   end
   ## -------------------------------------------------
   
   def deleteFile(filename)
      url = "#{@minArcServer}#{API_URL_DELETE}/#{filename}"
      if @isDebugMode == true then
         @logger.debug("MINARC_Client::deleteFile => #{url}")
      end
      return getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode, @logger)
   end
   # ------------------------------------------------
   
   def getAllFileTypes
      url = "#{@minArcServer}#{API_URL_GET_FILETYPES}"
      if @isDebugMode == true then
         @logger.debug("MINARC_Client::getAllFileTypes => #{url}")
      end
      return getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode, @logger)
   end
   # ------------------------------------------------
   
   def statusFileType(filetype)
      url = "#{@minArcServer}#{API_URL_STAT_FILETYPES}/#{filetype}"
      if @isDebugMode == true then
         @logger.debug("MINARC_Client::statusFileType => #{url}")
         puts
      end
      return getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode, @logger)   
   end
   ## ------------------------------------------------------

   def statusGlobal
      url = "#{@minArcServer}#{API_URL_STAT_GLOBAL}"
      if @isDebugMode == true then
         @logger.debug("MINARC_Client::statusGlobal => #{url}")
      end
      return JSON.parse(getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode, @logger))
   end
   ## ------------------------------------------------------
   
   def statusFileName(filename)
      url = "#{@minArcServer}#{API_URL_STAT_FILENAME}/#{filename}"
      if @isDebugMode == true then
         @logger.debug("MINARC_Client::statusFileName => #{url}")
      end
      # return JSON.parse(getURL(url, @isDebugMode))
      return getURL(url, @verifyPeerSSL, @user, @pass, @isDebugMode, @logger) 
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
