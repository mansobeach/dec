#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #OrchestratorIngester class
#
# === Written by DEIMOS Space S.L. (algk)
#
# === MDS-LEGOS => ORC Component
# 
# CVS: $Id: OrchestratorIngester.rb,v 1.3 2009/01/26 19:51:06 decdev Exp $
#
# module ORC
#
#########################################################################

require 'cuc/DirUtils'
require 'cuc/Log4rLoggerFactory'
require 'cuc/EE_ReadFileName'
require 'orc/ReadOrchestratorConfig'
require 'orc/ORC_DataModel'


module ORC


class OrchestratorIngester
   
   include CUC::DirUtils
   #-------------------------------------------------------------
  
   # Class constructor

   def initialize(pollDir, interval, debugMode, log, pid)
      checkModuleIntegrity
      @orcBaseDir = ENV['ORC_BASE']
      @pollingDir = pollDir
      @intervalSeconds = interval
      @isDebugMode = debugMode            
      @logger = log
      @observerPID = pid
      @newFile = false
      @ftReadConf = ORC::ReadOrchestratorConfig.instance
      if @isDebugMode == true then
         @ftReadConf.setDebugMode
      end
   end
   #-------------------------------------------------------------

   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "OrchestratorIngester debug mode is on"
   end
   #-------------------------------------------------------------


   # Public Class Methods
   #-------------------------------------------------------------

   #method that checks on the given array of files wich one is a 
   #valid type and stores or delete it accordingly to the result
   def ingest(d)

      d.each{|polledFile|
         
         if @isDebugMode == true then
            @logger.debug(%Q{Found #{polledFile}})
         end

         decoder = CUC::EE_ReadFileName.new(polledFile)
         type = decoder.getFileType 

         # Store new file on MINARC
         
         bIngested = false
        
         if @ftReadConf.isValidFileType?(type) then
            if @isDebugMode == true then
               @logger.debug("Archiving #{polledFile}")
            end

            command ="minArcStore.rb -m -f #{@pollingDir}/#{polledFile}"
            
            if @isDebugMode == true then
               @logger.debug(%Q{\n#{command}})
            end

            retVal = system(command)      
            
            if retVal == true then
               
               bIngested = true

               @logger.info("#{polledFile} archived on MINARC")

               # If Trigger file, add it to Pending2QueueFiles        
               if @ftReadConf.isFileTypeTrigger?(type) then
                  begin                                 
                     line = Pending2QueueFile.new                                   
                     line.filename = polledFile
                     line.filetype = type                
                     line.detection_date = Time.now
                     line.save!
                     @newFile = true
                  rescue Exception => e
                     @logger.error("Could not inventory #{polledFile} ! :-(")
                  end           
               end

            else
               bIngested = false
               @logger.error("Could not Archive #{polledFile} File")
            end  
         else
            bIngested = false
            if @isDebugMode == true then
               @logger.debug(%Q{File-type not configured})
            end
         end

         
         #deleting file from directory
         if bIngested == false then
          
            command ="mv #{@pollingDir}/#{polledFile} #{@orcTmpDir}/_ingestionError"
      
            if @isDebugMode == true then
               @logger.debug(%Q{\n#{command}})
            end

            retVal = system(command)    
      
            if retVal == true then
               if @isDebugMode == true then
                  @logger.debug("File #{polledFile} moved to #{@orcTmpDir}/_ingestionError")
               end
            else
               @logger.error("Failed to move #{polledFile} to #{@orcTmpDir}/_ingestionError")
            end               
         end
   
      } # end block d.each    

      # Notify scheduler if a new trigger file has been detected
      if (@observerPID != nil) and (@newFile == true) then
         if @isDebugMode == true then
            @logger.debug("Sending SIGUSR1 to observer")
         end                                
         Process.kill("SIGUSR1", @observerPID)
      end
      
      @newFile = false   
  
   end
   #-------------------------------------------------------------
   
   # Method triggered by Listener 
   def poll
      startTime = Time.new
      startTime.utc 
  
      @logger.info("Polling #{@pollingDir}  ...")

      prevDir = Dir.pwd    
  
      begin 
         Dir.chdir(@pollingDir) do
            d=Dir["*"]
            self.ingest(d)
            @logger.info("Success Polling #{@pollingDir}  !")
         end      
      rescue SystemCallError
         @logger.error("Could not Poll #{@pollingDir}  !")
      end
    
      Dir.chdir(prevDir)

      # calculate required time and new interval time.
      stopTime     = Time.new
      stopTime.utc   
      requiredTime = stopTime - startTime   
      nwIntSeconds = @intervalSeconds - requiredTime.to_i
   
      if @isDebugMode == true and nwIntSeconds > 0 then
         puts "New Trigger Interval is #{nwIntSeconds} seconds | #{@intervalSeconds} - #{requiredTime.to_i}"
      end
   
      if @isDebugMode == true and nwIntSeconds < 0 then
         puts "Time performed for polling is higher than interval Server !"
         puts "polling interval -> #{@intervalSeconds} seconds "
         puts "time required    -> #{requiredTime.to_i} seconds "
         puts
      end
      
      # The lowest time we return is one second. 
      # 0 would produce the process to sleep forever.
    
      if nwIntSeconds > 0 then
         return nwIntSeconds
      else
         return 1
      end   
   end
   #-------------------------------------------------------------

private
  
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
   
      if !ENV['ORC_BASE'] then
         puts "ORC_BASE environment variable not defined !  :-(\n"
         bCheckOK = false
         bDefined = false
      end

      if !ENV['ORC_TMP'] then
         puts "ORC_TMP environment variable not defined !  :-(\n"
         bCheckOK = false
         bDefined = false
      else
         @orcTmpDir = ENV['ORC_TMP']
         checkDirectory("#{@orcTmpDir}/_ingestionError")
      end

      if bCheckOK == false or bDefined == false then
         puts "OrchestratorIngester::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end

   end
   #-------------------------------------------------------------

end #end class

end #module
