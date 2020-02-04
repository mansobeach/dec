#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #OrchestratorIngester class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === ORC Component
# 
# CVS: $Id: OrchestratorIngester.rb,v 1.7 2009/03/31 08:42:53 decdev Exp $
#
# module ORC
#
#########################################################################

require 'cuc/DirUtils'
require 'cuc/Log4rLoggerFactory'

require 'orc/ReadOrchestratorConfig'
require 'orc/ORC_DataModel'


module ORC


class OrchestratorIngester
   
   include CUC::DirUtils
   #-------------------------------------------------------------
  
   # Class constructor

   def initialize(pollDir, interval, debugMode, log, pid)
      @logger              = log
      checkModuleIntegrity
      @pollingDir          = pollDir
      @intervalSeconds     = interval
      @isDebugMode         = debugMode
      @observerPID         = pid
      @newFile             = false
      @ftReadConf          = ORC::ReadOrchestratorConfig.instance
      if @isDebugMode == true then
         @ftReadConf.setDebugMode
      end
      if ENV['ORC_DB_ADAPTER'] == "sqlite3" then
         @parallelIngest      = 1
      else
         @parallelIngest      = @ftReadConf.getParallelIngest
      end
   end
   ## -------------------------------------------------------------

   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "OrchestratorIngester debug mode is on"
   end
   ## -------------------------------------------------------------

   def ingestFile(polledFile)
      bIngested   = false
      cmd         = "minArcFile -T S2PDGS -f #{polledFile} -t"         
      filetype    = `#{cmd}`.chop
         
      @logger.debug(%Q{#{cmd} / #{filetype} => #{$?}})
                                 
      if @ftReadConf.isValidFileType?(polledFile) == true then
         @newFile = true
         cmd      = "minArcStore --noserver -t S2PDGS -m -f #{@pollingDir}/#{polledFile}"
         if @isDebugMode == true then
            cmd = "#{cmd.dup} -D"
         end
         retVal   = system(cmd)
         @logger.info("#{cmd} => #{$?}")
                  
         if retVal == true then               
            bIngested = true                              
            if @ftReadConf.isFileTypeTrigger?(polledFile) == true then
               cmd      = "orcQueueInput -f #{polledFile} -P -s NRT"
               retVal   = system(cmd)
               @logger.info("#{cmd} / #{retVal}")
               if retVal != true then
                  @logger.error("Could not queue #{polledFile}")
                  cmd      = "minArcRetrieve --noserver -f #{File.basename(polledFile, ".*")} -L #{@ftReadConf.getFailureDir}"
                  retVal   = system(cmd)
                  if retVal == true then
                     @logger.info("#{polledFile} copied into failure dir #{@ftReadConf.getFailureDir}")
                  else
                     @logger.error("Could not place #{polledFile} into failure dir #{@ftReadConf.getFailureDir}")
                  end
                  return false
               end
            else
               @logger.debug("#{polledFile} is not trigger")
            end
         else
            bIngested = false
            @logger.error("Could not Archive #{polledFile} File on MINARC")
         end  
      else
         bIngested = false
         @logger.error("File-type #{filetype} not present in configuration !")
      end
      
      ## ---------------------------------------------------
      ##   
      ## Move to ingestionError folder if still present in polling dir
      ##
      ## 1- not configured triggers to orc are moved 
      ## 2- theoretically minarc errors would move files into MINARC_ARCHIVE_ERROR
      
      if bIngested == false and File.exist?("#{@pollingDir}/#{polledFile}") == true then      
         command = "\\mv -f #{@pollingDir}/#{polledFile} #{@orcTmpDir}/_ingestionError"      
         if @isDebugMode == true then
            @logger.debug(%Q{\n#{command}})
         end
            
         retVal = system(command)          
            
         if retVal == true then
            @logger.warn("File #{polledFile} moved to #{@orcTmpDir}/_ingestionError")
         else
            @logger.warn("Failed to move #{polledFile} to #{@orcTmpDir}/_ingestionError")
            command = "\\rm -rf #{@pollingDir}/#{polledFile}"
            if @isDebugMode == true then
               @logger.debug(%Q{\n#{command}})
            end
            system(command)
         end               
      end
      
      ## ---------------------------------------------------   
         
      return bIngested
           
   end
   ## -------------------------------------------------------------

   # Method that checks on the given array of files which one is a 
   # valid type and stores or delete it accordingly to the result
   def ingest(arrPolledFiles)
      @newFile = false
      
      # Log all files found in the polling dir
      arrPolledFiles.each{|polledFile|   
         @logger.debug(%Q{Found #{polledFile}})
      }

      loop do
         
         break if arrPolledFiles.empty?
         
         1.upto(@parallelIngest) {|i|
         
            break if arrPolledFiles.empty?
            
            file = arrPolledFiles.shift

            if file.to_s.slice(0,1) == "_" or file.to_s.slice(0,2) != "S2" then
               @logger.warn(%Q{Discarded #{file}})
               next
            end
            
            fork{
            	ret = ingestFile(file)
               if ret == false then
                  exit(1)
               else
                  exit(0)
               end 
            }
         }
         arr = Process.waitall
         arr.each{|child|
            if child[1].exitstatus == 0 then
               @newFile = true
            else
               @logger.error("Problem(s) during file ingestion")
            end
         }
      end

      ## ---------------------------------------------------
      ## Notify to the scheduler if a new file has been detected

      if (@observerPID != nil) and (@newFile == true) then
         sleep(2.0)
         @logger.debug("Sending SIGUSR1 to Observer with pid #{@observerPID}")                                
         ret = Process.kill("SIGUSR1", @observerPID)
         @logger.debug(ret)
         puts ret
      end
      ## ---------------------------------------------------
      
      @newFile = false   
  
   end
   ## -------------------------------------------------------------
   
   # Method triggered by Listener 
   def poll
      startTime = Time.new
      startTime.utc 
      
#      if @isDebugMode == true then
         @logger.debug("Polling #{@pollingDir}")
#      end     

      # Polls the given dir and calls the "ingest" method for each entry
      prevDir = Dir.pwd     
      begin 
         Dir.chdir(@pollingDir) do
            d=Dir["*"]
            self.ingest(d)
            if @isDebugMode == true then
               @logger.debug("Success Polling #{@pollingDir}  !")
            end
         end      
      rescue SystemCallError => e
         puts e.to_s
         puts
         puts e.backtrace
         @logger.error("Could not Poll #{@pollingDir}  !")
         @logger.error(e.to_s)
         @logger.error(e.backtrace)
      end    
      Dir.chdir(prevDir)

      # Calculate required time and new interval time.
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
  
   # -------------------------------------------------------------
   # Check that everything needed by the class is present.
   
   def checkModuleIntegrity
   
      if !ENV['ORC_TMP'] then
         @logger.debug("ORC_TMP environment variable not defined")
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
   # -------------------------------------------------------------

end #end class

end #module
