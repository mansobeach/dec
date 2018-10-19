#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DDC_FileSender class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# CVS: $Id: DDC_FileSender.rb,v 1.25 2014/10/14 08:49:08 algs Exp $
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
require 'ctc/ReadInterfaceConfig'
require 'ctc/FileSender'
require 'ctc/ListWriterDelivery'
require 'ddc/ReadConfigDDC'
require 'dec/DEC_Environment'

module DDC

class DDC_FileSender

   include CUC::DirUtils
   include DDC
   include DEC
   #-------------------------------------------------------------
   
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
#         puts @interface
#         puts @interface.to_a[0].name
#         puts @interface.to_a[0].description
#         puts
      else
         @interface   = @entity
      end


      # initialize logger
      
      configDir = nil

      if ENV['DEC_CONFIG'] then
         configDir         = %Q{#{ENV['DEC_CONFIG']}}  
      else
         configDir         = %Q{#{ENV['DCC_CONFIG']}}  
      end
      
      
      loggerFactory = CUC::Log4rLoggerFactory.new("DDC_FileSender", "#{configDir}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in DDC_FileSender::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{configDir}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end

      @ftReadConf  = CTC::ReadInterfaceConfig.instance
      @ftpserver    = @ftReadConf.getFTPServer4Send(@entity)
      txparams     = @ftReadConf.getTXRXParams(@entity)
      @delay       = @ftReadConf.getLoopDelay(@entity).to_i
      @loops       = @ftReadConf.getLoopRetries(@entity).to_i
      @retries     = @ftReadConf.getImmediateRetries(@entity).to_i
      @sender      = CTC::FileSender.new(@ftpserver, protocol)
      if isDebug == true then
         setDebugMode
      end
      @outboxDir   = @ftReadConf.getOutgoingDir(@entity)
      @outboxDir   = "#{@outboxDir}/ftp"
      checkDirectory(@outboxDir)
      @ddcConfig   = DDC::ReadConfigDDC.instance
      @arrFilters  = @ddcConfig.getOutgoingFilters
      @arrFiles    = Array.new
      loadFileList
      @sender.setFileList(@arrFiles, @outboxDir)
                  
      @satPrefix   = DDC::ReadConfigDDC.instance.getSatPrefix
      @prjName     = DDC::ReadConfigDDC.instance.getProjectName
      @prjID       = DDC::ReadConfigDDC.instance.getProjectID
      @mission     = DDC::ReadConfigDDC.instance.getMission
      @sender.setUploadPrefix(DDC::ReadConfigDDC.instance.getUploadFilePrefix)

   end
   #-------------------------------------------------------------
  
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "DDC_FileSender debug mode is on"
      @sender.setDebugMode
   end
   #-------------------------------------------------------------
 
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
         puts "\nLoading list of files to be Sent from:#{@outboxDir}"
      end

      @arrFilters.each{|filter|
         if @isDebugMode then
            puts "Filtering outgoing files by #{filter}"
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
            if SentFile.hasAlreadyBeenSent?(file, @entity, "ftp") == true then
               if @isDebugMode then
                  puts "#{file} already sent to #{@entity} via ftp"
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
         puts "-------------------------------------------------------"
         print("Files to be sent via #{@protocol} to #{@entity} are :\n")
         puts @arrFiles
         puts "-------------------------------------------------------"
      end
      
      if @arrFiles.empty? then
         @logger.debug("No Files to #{@entity} I/F in ftp outbox #{@outboxDir}")
      end

      @listFileToBeSent = @arrFiles      
   end
   #-------------------------------------------------------------

   # Main function of the class which performs the File delivery
   # to the given entity
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
            puts "\nRE-Sending Loop Retry(#{i}) files to #{@entity}\n\n"
         end 
     
         bSent          = true   
         tmpFilesSent   = Array.new
         
         puts         
         @arrFiles.each{|file|

            puts "Sending #{file} to #{@entity} via #{@protocol}"
            
            bRet = sendFile(file)
            
            if bRet == false then
               @logger.error("[DEC_200] Failed sending #{file} to #{@entity}")
               puts "Error sending #{file} to #{@entity}"
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
               SentFile.setBeenSent(file, @interface, "ftp", hParams)
            end
            
         }
         puts
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
            puts "Waiting #{@delay} seconds for sending files to #{@entity} (pid=#{pid}) "
         end
         
         if loop >=0 then
            puts "\nWaiting #{@delay}s to retry file delivery to #{@entity}"
            @logger.warn("Waiting #{@delay}s to retry file delivery to #{@entity}")
            sleep(@delay)
         end
      end
      return bSent
   end
   #-------------------------------------------------------------
   
   def createReportFile(directory, bDeliver = true, bForceCreation = false, bNominal = true)
	   bFound      = false
      bIsEnabled  = false
      fileClass    = ""
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

      arrReports = @ddcConfig.getReports

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
         puts "Explicit Request creation of RetrievedFiles Report"
         puts "Warning: DeliveredFiles Report is not configured in ddc_config.xml :-|"
         puts
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

	   writer = CTC::DeliveryListWriter.new(directory, true, fileClass, fileType)
         
      if @isDebugMode == true then
		   writer.setDebugMode
      end
      
      writer.setup(@satPrefix, @prjName, @prjID, @mission)
      writer.writeData(@entity, time, arrListofFilesSent)
      
      filename = writer.getFilename
         
      puts "Created Report File #{filename} for #{@entity}"
      @logger.info("#{@entity} - created Report File #{filename}")
   
      if filename == "" then
         puts "Error in DDC_FileSender::createContentFile !!!! =:-O \n\n"
         exit(99)
      end
         
#       if bDeliver == true then
#          deliverer = DCC::FileDeliverer2InTrays.new
#    
#          if @isDebugMode == true then
#             deliverer.setDebugMode
#          end
#          puts "Creating and Deliver Report File"
#          deliverer.deliverFile(directory, filename)
#          puts
#       end   
   end
   #-------------------------------------------------------------

private
   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   #-------------------------------------------------------------
   
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

#         if !bRetVal and @ftpserver[:FTPServerMirror] != nil then
#            puts "Warning: Main host did not respond ( #{@ftpserver[:hostname]} ). Trying to use the Mirror server"
#            @logger.warn("Main host did not respond ( #{@ftpserver[:hostname]} ). Trying to use the Mirror server")         
#            if File.directory?(file) then
#               bRetVal = @sender.useMirrorServer(file, false)
#            else
#               bRetVal = @sender.useMirrorServer(file)
#            end
#            if !bRetVal then
#               puts "Error: Mirror host did not respond neither ( #{@ftpserver[:FTPServerMirror][:hostname]} )"
#               @logger.error("[DEC_201] Mirror host did not respond neither ( #{@ftpserver[:FTPServerMirror][:hostname]} )")
#            end
#         end

         if bRetVal then
            Dir.chdir(prevDir)
            return true
         end
         
         nRetries = nRetries - 1
         i        = i + 1
         
         puts "RE-Sending(#{i}) #{file} to #{@entity}"
         @logger.info("RE-Sending(#{i}) #{file} to #{@entity}")
               
      end
      Dir.chdir(prevDir)
      return false     
   end
   #-------------------------------------------------------------
   

end # class

end # module
