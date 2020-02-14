#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DEC_FileSender class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component
# 
# Git: $Id: DEC_FileSender.rb,v 1.25 2014/10/14 08:49:08 algs Exp $
#
# Module Data Distributor Component
# This class performs the file(s) FTP/SFTP delivery to a given Entity.
# Its source directory is the OUTBOX/ftp directory.
#
# This class makes use of FileSender & ReadInterfaceConfig. 
#
#########################################################################

require 'cuc/DirUtils'
require 'cuc/Log4rLoggerFactory'
require 'cuc/EE_ReadFileName'
require 'ctc/FileSender'
require 'ctc/ListWriterDelivery'
require 'dec/ReadConfigDEC'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigOutgoing'
require 'dec/DEC_Environment'

module DEC

class DEC_FileSender

   include CUC::DirUtils
   include DEC
   
   ## -------------------------------------------------------------
   
   attr_reader :listFileSent, :listFileError, :listFileToBeSent
   
   def initialize(entity, protocol, deliverOnce, isDebug=false, isNoDB=false)
      @entity      = entity
      @protocol    = protocol
      
      @deliverOnce = deliverOnce
      checkModuleIntegrity
      @isDebugMode = false
      @isNoDB      = isNoDB

      if @isNoDB == false then
         require 'dec/DEC_DatabaseModel'
         @interface   = Interface.where(name: @entity).to_a[0]
      else
         @interface   = @entity
      end
      
      configDir = nil

      if ENV['DEC_CONFIG'] then
         configDir         = %Q{#{ENV['DEC_CONFIG']}}
      else
         puts self.backtrace
         exit(99)
      end
            
      loggerFactory = CUC::Log4rLoggerFactory.new("DEC_FileSender", "#{configDir}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in DEC_FileSender::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{configDir}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end

      @ftReadConf    = ReadInterfaceConfig.instance
      txparams       = @ftReadConf.getTXRXParams(@entity)
      @delay         = @ftReadConf.getLoopDelay(@entity).to_i
      @loops         = @ftReadConf.getLoopRetries(@entity).to_i
      @retries       = @ftReadConf.getImmediateRetries(@entity).to_i
      @ftpserver     = @ftReadConf.getFTPServer4Send(@entity)
      @ftpserver[:uploadDir]  = ReadConfigOutgoing.instance.getUploadDir(@entity)
      @ftpserver[:uploadTemp] = ReadConfigOutgoing.instance.getUploadTemp(@entity)
      @protocol      = @ftpserver[:protocol]     
      @sender        = CTC::FileSender.new(@ftpserver, protocol, @logger)
      
      if isDebug == true then
         setDebugMode
      end
      
      @outboxDir   = ReadConfigOutgoing.instance.getOutgoingDir(@entity)
      @outboxDir   = "#{@outboxDir}/ftp"
      checkDirectory(@outboxDir)
      @decConfig   = DEC::ReadConfigDEC.instance
      @arrFilters  = @decConfig.getOutgoingFilters
      @arrFiles    = Array.new
      loadFileList
      @sender.setFileList(@arrFiles, @outboxDir)
                  
      @satPrefix   = DEC::ReadConfigDEC.instance.getSatPrefix
      @prjName     = DEC::ReadConfigDEC.instance.getProjectName
      @prjID       = DEC::ReadConfigDEC.instance.getProjectID
      @mission     = DEC::ReadConfigDEC.instance.getMission
      @sender.setUploadPrefix(DEC::ReadConfigDEC.instance.getUploadFilePrefix)

   end
   ## -----------------------------------------------------------
  
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      @logger.debug("DEC_FileSender debug mode is on")
      @sender.setDebugMode
   end
   ## -----------------------------------------------------------
 
   # Set the outbox directory where the files to be sent are placed.
   #
   def loadFileList
      @listFileSent     = Array.new
      @listFileError    = Array.new
      @listFileToBeSent = Array.new
      @arrFiles         = Array.new
      arrTmp            = Array.new
      prevDir           = Dir.pwd
      Dir.chdir(@outboxDir)

      if @isDebugMode then
         @logger.debug("Loading list of files to be Sent from:#{@outboxDir}")
      end

      @arrFilters.each{|filter|
         if @isDebugMode then
            @logger.debug("Filtering outgoing files by #{filter}")
         end
         arrTmp << Dir[filter].sort_by{ |f| File.mtime(f)}
      }
      arrTmp = arrTmp.flatten
      arrTmp = arrTmp.uniq
      Dir.chdir(prevDir)

      # If delivery once has been selected, check whether the file
      # has already been delivered
      if @deliverOnce then
         arrTmp.each { |file|
            if SentFile.hasAlreadyBeenSent?(file, @entity, @ftpserver[:protocol]) == true then
               if @isDebugMode then
                  @logger.debug("#{file} already sent to #{@entity} via #{@ftpserver[:protocol]}")
               end
               File.delete(%Q{#{@outboxDir}/#{file}})
            else
               @arrFiles << file
            end                   
         }
      else
         @arrFiles= arrTmp.clone
      end

      if @isDebugMode and !@arrFiles.empty? then
         @logger.debug("Files to be sent via #{@protocol} to #{@entity} are :")
         @arrFiles.each{|file|
            @logger.debug(file)
         }
      end
      
      if @arrFiles.empty? then
         @logger.debug("No Files to #{@entity} I/F in ftp outbox #{@outboxDir}")
      end

      @listFileToBeSent = @arrFiles      
   end
   
   ## -----------------------------------------------------------

   ## Main function of the class which performs the File delivery
   ## to the given entity
   def deliver(deliverOnce=false, hParams=nil)
      @deliverOnce = deliverOnce
           
      if @arrFiles.length == 0 then
         return true
      end
      
      bSent = false
      loop  = @loops - 1
      i     = 0
      
      # Force at least one loop execution
      if loop < 0 then
         loop = 0
      end

      until bSent == true or loop < 0
         if @isDebugMode == true and loop != @loops and i != 0 then
            @logger.debug("RE-Sending Loop Retry(#{i}) files to #{@entity}")
         end 
     
         bSent          = true   
         tmpFilesSent   = Array.new
                  
         @arrFiles.each{|file|

            @logger.info("Sending #{file} to #{@entity} via #{@ftpserver[:protocol]}")
            
            size = File.size("#{@outboxDir}/#{File.basename(file)}")
            
            bRet = sendFile(file)
            
            if bRet == false then
               @logger.error("[DEC_200] Failed sending #{file} to #{@entity}")
               @listFileError << file
               @listFileError = @listFileError.uniq
               bSent = false
            else
               @logger.info("#{file} sent to #{@entity} via #{@protocol}")
               tmpFilesSent  << file
               @listFileSent << file
               
               # Now we register the files sent even if we allow them to be re-send
               # (deliveryOnce equal to false)
               # Registry of Files sent
               SentFile.setBeenSent(file, @interface, @ftpserver[:protocol], size, hParams)
            end
            
         }
         
         tmpFilesSent.each{|file| 
            @arrFiles.delete(file)
            @listFileError.delete(file)
         }
         
         if bSent == true then
            break
         end
         
         loop = loop - 1
         i    = i + 1
      
         if @isDebugMode == true and loop >= 0 then
            pid = Process.pid
            @logger.debug("Waiting #{@delay} seconds for sending files to #{@entity} (pid=#{pid}) ")
         end
         
         if loop >=0 then
            @logger.warn("Waiting #{@delay}s to retry file delivery to #{@entity}")
            sleep(@delay)
         end
      end
      return bSent
   end
   
   ## -----------------------------------------------------------
   ##
   ##
   def createReportFile(directory, bDeliver = true, bForceCreation = false, bNominal = true)
	   bFound      = false
      bIsEnabled  = false
      fileClass   = ""
      fileType    = ""
      desc        = ""
      arrRepTypes = Array.new 
      time = Time.now
      now  = time.strftime("%Y%m%dT%H%M%S")
	   
      reportType = ""

      if bNominal == true then
         reportType = "DELIVEREDFILES"
      else
         reportType = "EMERGENCYDELIVEREDFILES"
      end

      arrReports = @decConfig.getReports

      arrReports.each{|aReport|
         if aReport[:name] == reportType then
            bFound      = true
            bIsEnabled  = aReport[:enabled]
            desc        = aReport[:desc]
            fileClass   = aReport[:fileClass]
            fileType    = aReport[:fileType]
         end
         arrRepTypes << aReport[:fileType]
      }

      if bForceCreation == true and bFound == false then
         @logger.warn("DEC_FileSender::createReportFile: DeliveredFiles Report is not configured in dec_config.xml :-|")
         return
      end

      if bFound == false or bIsEnabled == false then
         return
      end

      arrListofFilesSent = Array.new

      @listFileSent.each{|aFilename|
         aFileType = CUC::EE_ReadFileName.new(aFilename).fileType
         if arrRepTypes.include?(aFileType) == false then
            arrListofFilesSent << aFilename
         end
      }

      if arrListofFilesSent.length == 0 then
         return
      end

	   writer = CTC::ListWriterDelivery.new(directory, true, fileClass, fileType)
         
      if @isDebugMode == true then
		   writer.setDebugMode
      end
      
      writer.setup(@satPrefix, @prjName, @prjID, @mission)
      writer.writeData(@entity, time, arrListofFilesSent)
      
      filename = writer.getFilename
         
      @logger.info("#{@entity} - created Report File #{filename}")
   
      if filename == "" then
         @logger.error("Error in DEC_FileSender::createContentFile !!!! =:-O")
         exit(99)
      end
         
#       if bDeliver == true then
#          deliverer = DCC::FileDeliverer2InTrays.new
#    
#          if @isDebugMode == true then
#             deliverer.setDebugMode
#          end
#          deliverer.deliverFile(directory, filename)
#       end   
   end
   ## -----------------------------------------------------------

private
   
   ## -----------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   ## -----------------------------------------------------------
   
   def sendFile(file)

      prevDir           = Dir.pwd
      Dir.chdir(@outboxDir)
   
      nRetries = @retries - 1     
      retVal   = false
      i        = 0      
          
      until ((nRetries < 0) or (retVal == true))       
         

         if File.directory?(file) == true then
            bRetVal = @sender.sendDir(file)
         else
            bRetVal = @sender.sendFile(file)
         end

         if bRetVal then
            Dir.chdir(prevDir)
            return true
         end
         
         nRetries = nRetries - 1
         i        = i + 1
         
         @logger.info("RE-Sending(#{i}) #{file} to #{@entity}")
               
      end
      Dir.chdir(prevDir)
      return false     
   end
   ## -----------------------------------------------------------
   

end # class

end # module
