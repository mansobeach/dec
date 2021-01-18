#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #DEC_FileSender class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: DEC_FileSender.rb,v 1.25 2014/10/14 08:49:08 algs Exp $
###
### This class performs the file(s) FTP/SFTP delivery to a given Entity.
### Its source directory is the OUTBOX/ftp directory.
###
###
#########################################################################

require 'cuc/DirUtils'
require 'cuc/Log4rLoggerFactory'
require 'cuc/EE_ReadFileName'
require 'ctc/ListWriterDelivery'
require 'dec/ReadConfigDEC'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigOutgoing'
require 'dec/DEC_Environment'
require 'dec/FileSender'

module DEC

class DEC_FileSender

   include CUC::DirUtils
   include DEC
   
   ## -------------------------------------------------------------
   
   attr_reader :listFileSent, :listFileError, :listFileToBeSent
   
   def initialize(entity, protocol, deliverOnce, isDebug = false, isNoDB=false)
      @entity      = entity
      @protocol    = protocol
      @isDebugMode = isDebug
      @deliverOnce = deliverOnce
      @isNoDB      = isNoDB

      checkModuleIntegrity
      
      configDir = nil

      if ENV['DEC_CONFIG'] then
         configDir         = %Q{#{ENV['DEC_CONFIG']}}
      else
         puts self.backtrace
         exit(99)
      end
            
      loggerFactory = CUC::Log4rLoggerFactory.new("push", "#{configDir}/dec_log_config.xml")
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

      if @isNoDB == false then
         require 'dec/DEC_DatabaseModel'
         
         # @interface   = Interface.where(name: @entity).to_a[0]
         
         @interface        = Interface.find_by_name(@entity)
         if @interface == nil then
@logger.error("[DEC_705] #{@entity} I/F: such is not a configured interface #{'1F480'.hex.chr('UTF-8')}")
            exit(99)
         end

      else
         @interface   = @entity
      end

#      @logger.debug("#{@interface}")

      @ftReadConf    = ReadInterfaceConfig.instance
      txparams       = @ftReadConf.getTXRXParams(@entity)
      @delay         = @ftReadConf.getLoopDelay(@entity).to_i
      @loops         = @ftReadConf.getLoopRetries(@entity).to_i
      @retries       = @ftReadConf.getImmediateRetries(@entity).to_i
      @parallelSlots = @ftReadConf.getTXRXParams(@entity)[:parallelDownload].to_i 
      @ftpserver     = @ftReadConf.getFTPServer4Send(@entity)
      @ftpserver[:uploadDir]  = ReadConfigOutgoing.instance.getUploadDir(@entity)
      @ftpserver[:uploadTemp] = ReadConfigOutgoing.instance.getUploadTemp(@entity)
      @protocol      = @ftpserver[:protocol]     
      @sender        = DEC::FileSender.new(@entity, @ftpserver, @protocol, @logger)
                 
      if isDebug == true then
         self.setDebugMode
      end
      
      @outboxDir     = ReadConfigOutgoing.instance.getOutgoingDir(@entity)            
      @outboxDir     = "#{@outboxDir.dup}/#{@protocol.downcase}"
      
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

      @listFileSent     = Array.new

   end
   ## -----------------------------------------------------------
  
   ## Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      @logger.debug("DEC_FileSender debug mode is on")
      @sender.setDebugMode
   end
   ## -----------------------------------------------------------
 
   ## Load the list of files to be sent from outbox directory
   ## If flag to deliver once is enabled, previously circulated file are removed
   def loadFileList
      
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
         
#            if file.downcase == "ftp" or file.downcase == "local" or file.downcase == "sftp" or file.downcase == "sftp" then
#               next
#            end
         
            if SentFile.hasAlreadyBeenSent?(file, @entity, @ftpserver[:protocol]) == true then
               @logger.warn("[DEC_401] I/F #{@entity}: #{file} previously uploaded discarded")
               File.delete(%Q{#{@outboxDir}/#{file}})
               if @isDebugMode then
                  @logger.debug("#{@entity} I/F: #{file} deleted from #{@outboxDir} to avoid circulation duplication")
               end
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
         if @isDebugMode == true then
            @logger.debug("#{@entity} I/F: No Files for push in #{@protocol} LocalOutbox #{@outboxDir}")
         end
      end

      @listFileToBeSent = @arrFiles
         
   end
   
   ## -----------------------------------------------------------
   
   def deliver(deliverOnce=false, hParams=nil)
      @deliverOnce = deliverOnce
           
      if @arrFiles.length == 0 then
         return true
      end
      
      listFiles = Array.new(@arrFiles)
      
      bSent = false
      iLoop = @loops - 1
      i     = 0
      
      ## -----------------------------------------
      ## Force at least one loop execution
      if iLoop < 0 then
         iLoop = 0
      end
      ## -----------------------------------------

      until bSent == true or iLoop < 0
         if @isDebugMode == true and iLoop != @loops and i != 0 then
            @logger.warn("RE-Sending Loop Retry(#{i}) files to #{@entity}")
         end 
         bSent = true
         loop do
            break if listFiles.empty?
            1.upto(@parallelSlots) {|i|
               break if listFiles.empty?
               file = listFiles.shift
               
               begin
                  size = File.size("#{@outboxDir}/#{File.basename(file)}")
               rescue Exception => e
                  @logger.error("[DEC_714] I/F #{@entity}: #{@outboxDir}/#{File.basename(file)} cannot be read to extract its size")
                  raise e
               end
               
               ### ---------------------------------------------------------
               ### 20201021 Super-dirty 
               ### adding a priori the files to be circulated as successful
               @listFileSent << File.basename(file)
               ### ---------------------------------------------------------
                  
               fork{
                  if @isDebugMode == true then
                     @logger.debug("Child process created to download #{File.basename(file)}")
            	   end
                  
                  bRet = sendFile(file, size, hParams)

                  if bRet == false then
                     if @isDebugMode == true then
                        @logger.debug("Child process failed to push #{File.basename(file)}")
                     end
                     exit(1)
                  else
                     exit(0)
                  end
               } 
            }  ## loop parallel slots
         
            arr = Process.waitall
            arr.each{|child|
               if child[1].exitstatus != 0 then
                  bSent = false
               end
            }
         end #loop

         if bSent == false then
            loadFileList
            listFiles = Array.new(@arrFiles)
         else
            return true
         end
     
         iLoop = iLoop - 1
         i     = i + 1
      
         if @isDebugMode == true and iLoop >= 0 then
            pid = Process.pid
            @logger.debug("Waiting #{@delay} seconds for sending files to #{@entity} (pid=#{pid}) ")
         end
         
         if iLoop >=0 then
            @logger.info("[DEC_205] I/F #{@entity}: Push retry waiting LoopDelay #{@delay}s")
            sleep(@delay)
         end
         
      end
      return bSent
   end
   
   ## -----------------------------------------------------------

   ## Main function of the class which performs the File delivery
   ## to the given entity
   def deliver_old_but_work(deliverOnce=false, hParams=nil)
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

            if @isDebugMode == true then
               @logger.debug("Sending #{file} to #{@entity} via #{@ftpserver[:protocol]}")
            end
            
            size = File.size("#{@outboxDir}/#{File.basename(file)}")
            
            bRet = sendFile(file, size, hParams)
            
            if bRet == false then
               @logger.error("[DEC_710] I/F #{@entity}: Failed sending #{file}")
               @listFileError << file
               @listFileError = @listFileError.uniq
               bSent = false
            else
               @logger.info("[DEC_210] I/F #{@entity}: #{file} UPLOADED / #{size} bytes")
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

      @listFileSent = @listFileSent.flatten.uniq

      @listFileSent.each{|aFilename|
         aFileType = CUC::EE_ReadFileName.new(aFilename).fileType
         if arrRepTypes.include?(aFileType) == false then
            arrListofFilesSent << aFilename
         end
      }

      if arrListofFilesSent.length == 0 then
         @logger.warn("[DEC_XXX] I/F #{@entity}: Failed to create report #{filename} / no files sent?!")
         return
      end

	   writer = CTC::ListWriterDelivery.new(directory, true, fileClass, fileType)
         
      if @isDebugMode == true then
		   writer.setDebugMode
      end
      
      writer.setup(@satPrefix, @prjName, @prjID, @mission)
      writer.writeData(@entity, time, arrListofFilesSent)
      
      filename = writer.getFilename
         
      @logger.info("[DEC_235] I/F #{@entity}: Created report #{filename}")
   
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
   
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   ## -----------------------------------------------------------

   def sendFile(file, size, hParams)

      @logger.info("[DEC_203] I/F #{@entity}: #{file} DELIVERY using #{@ftpserver[:protocol]}")

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

         if bRetVal == true then
            if @isNoDB == false then
               SentFile.setBeenSent(file, @interface, @ftpserver[:protocol], size, hParams)
            end
            @logger.info("[DEC_210] I/F #{@entity}: #{file} UPLOADED / size #{size} bytes")
            Dir.chdir(prevDir)
            return true
         else
            @logger.error("[DEC_710] I/F #{@entity}: Failed sending #{file}")
         end
         
         nRetries = nRetries - 1
         i        = i + 1
         
         @logger.info("[DEC_206] I/F #{@entity}: Push ImmediateRetries RE-Sending(#{i}) #{file}")
               
      end
      Dir.chdir(prevDir)
      return false     
   end   
   
   ## -----------------------------------------------------------
      
   def sendFile_old_but_working(file)

      prevDir           = Dir.pwd
      Dir.chdir(@outboxDir)
   
      nRetries = @retries - 1     
      retVal   = false
      i        = 0      
          
      until ((nRetries < 0) or (retVal == true))       
         

         # @logger.debug(file)

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
