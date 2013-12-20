#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DDC_FileSender class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# CVS: $Id: DDC_FileSender.rb,v 1.15 2008/07/03 11:38:26 decdev Exp $
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
require 'ctc/DeliveryListWriter'
# require 'dbm/DatabaseModel'
require 'ddc/ReadConfigDDC'


module DDC

class DDC_FileSender

   include CUC::DirUtils
   include DDC
   #-------------------------------------------------------------
   
   attr_reader :listFileSent, :listFileError, :listFileToBeSent
   
   def initialize(entity, isDebug=false, isNoDB=false)
      @entity      = entity
      checkModuleIntegrity
      @isDebugMode = false
      @isNoDB      = isNoDB
      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("DDC_FileSender", "#{ENV['DCC_CONFIG']}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in DDC_FileSender::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{ENV['DCC_CONFIG']}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end

      @ftReadConf  = CTC::ReadInterfaceConfig.instance
      ftpserver    = @ftReadConf.getFTPServer4Send(@entity)
      txparams     = @ftReadConf.getTXRXParams(@entity)
      @delay       = @ftReadConf.getLoopDelay(@entity).to_i
      @loops       = @ftReadConf.getLoopRetries(@entity).to_i
      @retries     = @ftReadConf.getImmediateRetries(@entity).to_i
      @sender      = CTC::FileSender.new(ftpserver)
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

      if @isNoDB == false then
         require 'dbm/DatabaseModel'
         @interface   = Interface.find_by_name(@entity)
      else
         @interface   = @entity
      end

      @satPrefix   = DDC::ReadConfigDDC.instance.getSatPrefix
      @prjName     = DDC::ReadConfigDDC.instance.getProjectName
      @prjID       = DDC::ReadConfigDDC.instance.getProjectID
      @mission     = DDC::ReadConfigDDC.instance.getMission
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
      if @isDebugMode == true then
         puts
      end
      @arrFilters.each{|filter|
         if @isDebugMode == true then
            puts "Filtering outgoing files by #{filter}"
         end
         arrTmp << Dir[filter]
         arrTmp = arrTmp.flatten
         arrTmp.each{|element|
            if File.directory?(element) == true then
              # next
            end
            @arrFiles << element
         }
      }
      @arrFiles = @arrFiles.flatten
      @arrFiles = @arrFiles.uniq
      Dir.chdir(prevDir)
      
      if @isDebugMode == true and (@arrFiles.length > 0) then
         puts "-------------------------------------------------------"
         print("Files to be sent to #{@entity} are :\n")
         puts @arrFiles
         puts "-------------------------------------------------------"
      end
      
      @listFileToBeSent = @arrFiles
      
      if @arrFiles.length == 0 then
         message = "No Files to #{@entity} I/F in ftp outbox #{@outboxDir}"
         @logger.debug(message)
      end
      
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
         if @isDebugMode == true and loop != @@loops and i != 0 then
            puts "\nRE-Sending Loop Retry(#{i}) files to #{@entity}\n\n"
         end 
     
         bSent          = true   
         tmpFilesSent   = Array.new
         
         puts         
         @arrFiles.each{|file|
            
            # If delivery once has been selected, check whether the file
            # has already been delivered
            if @deliverOnce == true then
               if SentFile.hasAlreadyBeenSent?(file, @entity, "ftp") == true then
                  puts "#{file} already sent to #{@entity} via (s)ftp"
                  File.delete(%Q{#{@outboxDir}/#{file}})
                  next
               end
            end            

            puts "Sending #{file} to #{@entity} via (s)ftp"
            
            bRet = sendFile(file)
            
            if bRet == false then
               @logger.error("Failed sending #{file} to #{@entity}")
               puts "Error sending #{file} to #{@entity}"
               @listFileError << file
               @listFileError = @listFileError.uniq
               bSent = false
            else
               @logger.info("#{file} sent to #{@entity} via (s)ftp")
               tmpFilesSent  << file
               @listFileSent << file
               
               # Now we register the files sent even if we allow them to be re-send
               # (deliveryOnce equal to false)
               # Registry of Files sent

#               if @deliverOnce == true then

               if @isNoDB == false then
                  SentFile.setBeenSent(file, @interface, "ftp", hParams)
               end

#               end
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
            puts "Waiting #{@@delay} seconds for sending files to #{@entity} (pid=#{pid}) "
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
            fileType    = aReport[:fileType]
            desc        = aReport[:desc]
            bIsEnabled  = aReport[:enabled]
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

	   writer = CTC::DeliveryListWriter.new(directory, true, fileType)
         
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

         if bRetVal == true then
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
