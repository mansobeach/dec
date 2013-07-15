#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #OrchestratorIngester class
#
# === Written by DEIMOS Space S.L. (algk)
#
# === MDS-LEGOS => ORC Component
# 
# CVS: $Id: OrchestratorIngester.rb,v 1.2 2008/12/16 11:45: decdev Exp $
#
# module ORC
#
#########################################################################

require 'orc/ReadOrchestratorConfig'

require 'cuc/Log4rLoggerFactory'
require 'cuc/EE_ReadFileName'

#require 'ctc/FileNameDecoder'  para borrar

module ORC



class OrchestratorIngester

   #-------------------------------------------------------------
  
   # Class constructor

   def initialize(pollDir, interval, debugMode, log)
      @pollingDir = pollDir
      @intervalSeconds = interval
      @isDebugMode = debugMode
      @logger = log
      @ftReadConf = ORC::ReadOrchestratorConfig.instance
   end
   #-------------------------------------------------------------


 #-----------------------
#method that checks if the given file is a valid type and stores or delete it accordingly to the result
   def ingest(polledFile, typeFile)  
   retVal= false #|||||||||||||||||||||||||||for test|||para borrar||||||||||||||||||||||||||
      if  @ftReadConf.isValidFileType(typeFile) then #store
         puts "Valid File"     
#         command ="minArcStore.rb -f #{@pollingDir}/polledFile -D"
#         retVal = system(command)      
         if retVal == true then
            puts "Success storing File !\n\n"   
            @logger.info("Success Storing File !")  
         else
            puts "ERROR storing file !\n\n"
            @logger.error("ERROR Storing File !")

         end                     
      else #delete
         puts "File type does not exist, deleting file"
#         command ="rm #{@pollingDir}/#{polledFile}"
         command ="mv #{@pollingDir}/#{polledFile} $ORC_BASE/code/orc/failure"           
         retVal = system(command)         
         if retVal == true then
            puts "Success Deleting File !\n\n"
            @logger.info("Success Deleting File !")
         else
            puts "ERROR Deleting File !\n\n"
            @logger.error("ERROR Deleting File !")
         end               
      end     
   end #method ingest
 #-----------------------

#method that polls the specified directory on the ingestorComponent.rb call 
   def poll

      startTime = Time.new
      startTime.utc   
      puts "Polling #{@pollingDir}  ..."
      @logger.info("Polling #{@pollingDir}  ...")

      prevDir = Dir.pwd    
      begin         
          Dir.chdir(@pollingDir) do
         # polling
         d=Dir["*"]               
         d.each{|x|
            if @isDebugMode == true then
               puts x
            end
            decoder = CUC::EE_ReadFileName.new(x)
            #decoder = CTC::FileNameDecoder.new(x)          para borrar 
            self.ingest(x, decoder.getFileType)
         }
      puts "Success Polling #{@pollingDir}  !\n\n"
      @logger.info("Success Polling #{@pollingDir}  !")
      end      
      rescue SystemCallError
         puts "ERROR Polling #{@pollingDir}  !\n\n"
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
   end   #end of poll method



end #end class

end #module
