#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #InterfaceHandlerAbstract class
###
### === Written by DEIMOS Space S.L.
###
### === Data Exchange Component -> Data Collector Component
###
### Git: $Id: InterfaceHandlerAbstract.rb,v
###
### Module Interface
### This is an abstract class that defines the interface handler methods
###
#########################################################################

## http://morningcoffee.io/interfaces-in-ruby.html

module DEC

require 'cuc/DirUtils'
require 'dec/ReadConfigDEC'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigIncoming'
require 'dec/EventManager'

class InterfaceHandlerCustom

   attr_reader :isDebugMode, :listOnly, :usage

   include CUC::DirUtils

   ## -----------------------------------------------------------
   ##
   ## Class constructor.
   ## * entity (IN):  Entity textual name (i.e. FOS)
   def initialize(entity, log, isNoDB = false)
      @entity     = entity
      @logger     = log
      @isNoDB     = isNoDB

      if ENV.include?('DEC_DEBUG_MODE') == true then
         @isDebugMode = true
      else
         @isDebugMode = false
      end

      if ENV.include?("DEC_LIST_MODE_#{@entity}") == false then
         print_usage
         raise "missing environment variable DEC_LIST_MODE_#{@entity}"
      end

      if ENV["DEC_LIST_MODE_#{@entity}"].downcase == "true" then
         @listOnly = true
      else
         @listOnly = false
      end

      if ENV.include?("DEC_USAGE_#{@entity}") == true then
         @usage = true
      else
         @usage = false
      end

      if @isNoDB == false then
         require 'dec/DEC_DatabaseModel'
         @interface        = Interface.find_by_name(@entity)
         if @interface == nil then
            raise "#{@entity} is not registered in the db"
         end
      end

      @protocol            = DEC::ReadInterfaceConfig.instance.getProtocol(@entity)
      @dirIncoming         = DEC::ReadConfigIncoming.instance.getIncomingDir(@entity)
      @bDeleteUnknown      = DEC::ReadConfigIncoming.instance.deleteUnknown?(@entity)
      @bDeleteDuplicated   = DEC::ReadConfigIncoming.instance.deleteDuplicated?(@entity)
      @bDeleteDownloaded   = DEC::ReadConfigIncoming.instance.deleteDownloaded?(@entity)
      @bLogDuplicated      = DEC::ReadConfigIncoming.instance.logDuplicated?(@entity)
      @bLogUnknown         = DEC::ReadConfigIncoming.instance.logUnknown?(@entity)
      @bMD5                = DEC::ReadConfigIncoming.instance.md5?(@entity)

      checkDirectory(@dirIncoming)

      @dimConfig        = ReadConfigIncoming.instance
      @finalDir         = @dimConfig.getIncomingDir(@entity)
      checkDirectory(@finalDir)

   end
   ## -----------------------------------------------------------
   ##
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   ## -----------------------------------------------------------

   ##
   def print_usage
      @logger.info("[DEC_A00] I/F #{@entity}: usage")
      @logger.info("[DEC_A00] I/F #{@entity}: env variable DEC_LIST_MODE_#{@entity}=true|false")
      @logger.info("[DEC_A00] I/F #{@entity}: env variable DEC_DEBUG_MODE=true|false")
   end
   ## -----------------------------------------------

	## -----------------------------------------------
   def previouslyReceived?(filename, md5 = false)
      if @isDebugMode == true then
         @logger.debug("checking previous reception of #{filename} from #{@entity} => | md5 flag #{md5}")
      end
      arrFiles = ReceivedFile.where(filename: filename)

      if arrFiles == nil then
         @logger.debug("not prev received #{filename}")
         return false
      end

      arrFiles.to_a.each{|file|

         if @isDebugMode == true then
            @logger.debug("#{filename} #{file.md5}")
         end

         if file.interface_id == @interface.id then

            if md5 == false and @bMD5 == true then
               if @isDebugMode == true then
                  @logger.debug("#{filename} with md5 #{file.md5} / download is required")
               end
               next
            end

            if md5 != false and md5 != true and @bMD5 == true then
               if file.md5 == md5 then
                  if @isDebugMode == true then
                     @logger.debug("[DEC_914] I/F #{@entity}: #{filename} found in database / same md5 was previously received ")
                  end
                  return true
               end
            else
               if @isDebugMode == true then
                  @logger.debug("[DEC_914] I/F #{@entity}: #{filename} found in database / it was previously received ")
               end
               return true
            end
         end
      }
      return false
   end
   ## -----------------------------------------------------------

   def setReceivedFromEntity(filename, size = nil, md5 = nil)
      if @isNoDB == true then
         return
      end

      # ------------------------------------------
      # 20170917 patch to avoid updating the database when received file is empty
      # to allow retransfer from originator
      if size.to_i == 0 then
         @logger.error("abort setReceivedFromEntity for #{filename} with size #{size} bytes")
         return
      end
      # ------------------------------------------

      receivedFile                = ReceivedFile.new
      receivedFile.filename       = filename
      receivedFile.size           = size
      receivedFile.interface      = @interface
      receivedFile.protocol       = @protocol
      receivedFile.reception_date = Time.now

      if md5 != nil then
         receivedFile.md5 = md5
      end

      begin
         receivedFile.save!
      rescue Exception => e
         @logger.error(e.to_s)
         @logger.error("InterfaceHandlerCustom::setReceivedFromEntity when updating database")
         @logger.error("[DEC_799] I/F #{@entity}: Fatal error when updating database RECEIVED_FILES for #{filename}")
         if @isDebugMode == true then
            @logger.debug(e.backtrace)
         end
         exit(99)
      end
   end
   #-------------------------------------------------------------

   def triggerEventPullOK
      event  = DEC::EventManager.new
      if @isDebugMode == true then
         event.setDebugMode
      end
      event.trigger(@entity, "ONRECEIVEOK", nil, @logger)
   end

   #-------------------------------------------------------------

   def triggerEventPullOKNewFiles
      event  = DEC::EventManager.new
      if @isDebugMode == true then
         event.setDebugMode
      end
      event.trigger(@entity, "ONRECEIVENEWFILESOK", nil, @logger)
   end

   #-------------------------------------------------------------

   def triggerEventNewFile(filename)
      event  = DEC::EventManager.new

      if @isDebugMode == true then
         event.setDebugMode
      end

      hParams              = Hash.new
      hParams["filename"]  = File.basename(filename)
      hParams["directory"] = @finalDir

      if @isDebugMode == true then
         @logger.debug("[DEC_XXX] Event ONRECEIVENEWFILE #{File.basename(filename)} => #{@dirIncoming}")
         @logger.debug(hParams)
      end
      event.trigger(@entity, "ONRECEIVENEWFILE", hParams, @logger)
   end

   #-------------------------------------------------------------

   ## DEC - Pull

   def getPullList
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end

   ## -----------------------------------------------------------
   ## to inspect object

   def to_s
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------

   def checkConfig(entity, pull, push)
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------

   def pushFile(sourceFile, targetFile, targetTemp)
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------

   def getUploadDirList(bTemp = false)
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------

   def checkRemoteDirectory(directory)
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------

   def getDirList(directory)
      raise NotImplementedError.new("#{self.class}::#{__method__.to_s} needs to be implemented")
   end
   ## -----------------------------------------------------------


	## -----------------------------------------------------------

   ## Download a file from the I/F
   def downloadDir(directory)
      raise NotImplementedError.new("#{__method__.to_s} needs to be implemented")
	end
   ## -----------------------------------------------------------

   ## Download a file from the I/F
   def deleteFromEntity(filename)
      raise NotImplementedError.new("#{__method__.to_s} needs to be implemented")
	end

   ## -------------------------------------------------------------

end # class

end # module
