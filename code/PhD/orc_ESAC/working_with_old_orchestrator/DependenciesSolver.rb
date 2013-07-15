#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DependenciesSolver class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS => ORC Component
# 
# CVS: $Id: DependenciesSolver.rb,v 1.3 2009/02/16 12:16:20 decdev Exp $
#
# module ORC
#
#########################################################################

require 'date'

require 'cuc/DirUtils'
require 'cuc/Log4rLoggerFactory'
require 'cuc/EE_ReadFileName'
require 'cuc/EE_DateConverter'

require 'minarc/FileRetriever'

require 'orc/ReadOrchestratorConfig'
require 'orc/ORC_DataModel'
require 'orc/GapsExtractor'


module ORC

# --------------------------------------
# For NRT Trigger Coverage 
# these are the different product types: 

NRT_TRIGGER_OLD     = "OLD"
NRT_TRIGGER_MIXED   = "MIX"
NRT_TRIGGER_NRT     = "NRT"
NRT_TRIGGER_FUTURE  = "FUT"
NRT_TRIGGER_UNKNOWN = "UKN"
# --------------------------------------

class DependenciesSolver
   
   include CUC::DirUtils
   include CUC::EE_DateConverter

   #-------------------------------------------------------------
  
   # Class constructor

   def initialize(triggerFile, jobId = "0", bTestMode = true)
      @isDebugMode   = false
      @isConfigured  = false
      @isResolved    = false
      @bTestMode     = bTestMode

      @triggerFile = triggerFile
      nameDecoder  = CUC::EE_ReadFileName.new(@triggerFile)
      
      @triggerType      = nameDecoder.getFileType
      @strNominalStart  = nameDecoder.getStrDateStart
      @strNominalEnd    = nameDecoder.getStrDateStop
      
      @dateNominalStart = nameDecoder.start_as_dateTime
      @dateNominalStop  = nameDecoder.stop_as_dateTime

      @jobId            = jobId

      @tRemainingStart  = nil
      @tRemainingStop   = nil
      
      checkModuleIntegrity
      
      checkDates

      @ftReadConf = ORC::ReadOrchestratorConfig.instance
      if @isDebugMode == true then
         @ftReadConf.setDebugMode
      end

      @dataType    = @ftReadConf.getDataType(@triggerType)
      @outDataType = @ftReadConf.getResultDataType(@dataType)
      @outFileType = @ftReadConf.getFileType(@outDataType)
      @coverMode   = @ftReadConf.getTriggerCoverageByInputDataType(@dataType)
      @nrtType     = nil

      if @isDebugMode == true then
         puts @triggerType
         puts @dataType
         puts @outDataType
         puts @outFileType
         puts @coverMode
      end

      if @outFileType == nil then
         puts
         puts "No processing rule found for #{@triggerType} ! =-O"
         puts
         puts "Check configuration ! :-p"
         puts
         exit(99)
      end

      @outReportType = String.new(@outFileType)
      @outReportType[0] = 'R'
      @outReportType[1] = 'E'
      @outReportType[2] = 'P'

      if @outFileType == "" or @outFileType == nil or @coverMode == nil then
         puts "Fatal Error in DependenciesSolver::initialize ! :-("
         puts
         exit(99)
      end   
   
      @arrDataTypesProcessed = Array.new
   end
   #-------------------------------------------------------------

   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "DependenciesSolver debug mode is on"
   end
   #-------------------------------------------------------------

   # This method calculates the real trigger time window
   def init
      @isConfigured = calcEffectiveTimeWindow
      return @isConfigured
   end
   #-------------------------------------------------------------
   
   # If the trigger-product coverage mode is NRT it returns its 
   # classification:
   # - OLD
   # - MIXED
   # - NRT
   # - FUTURE
   def getNRTType
      if @isConfigured == true then
         return @nrtType
      else
         return nil
      end
   end
   #-------------------------------------------------------------
   
   # Main method of this class that performs the dependencies
   # checker.
   def resolve

      @isResolved    = false
      @arrJobInputs  = Array.new

      @listOfInputRules = @ftReadConf.getListOfInputsByTriggerDataType(@dataType)

      if @listOfInputRules == nil then
         if @isDebugMode == true then
            puts "No dependencies to be resolved 4 #{@dataType} ! :-|"
            puts
         end
         return false
      end

      @arrDataTypesProcessed = Array.new
      
      retVal = true

      # ------------------------------------------
      # Dependencies Rules solver

      @listOfInputRules.each { |inputRule|
         
         fileType = @ftReadConf.getFileType(inputRule[:dataType])
         
         if @arrDataTypesProcessed.include?(inputRule[:dataType]) then
            if @isDebugMode == true then
               puts
               puts "Discarding rule:"
               puts inputRule
            end
            next
         end
         
         if @isDebugMode == true then
            puts
            puts "Resolving rule #{inputRule[:coverage]} for #{fileType} :"
         end

         ret = resolveDependency(inputRule)

         if inputRule[:mandatory] == true then
            if ret == false then
               puts "[Mandatory] #{fileType} => Rule #{inputRule[:coverage]} not solved !  :-("
            end
         else
            if ret == false then
               puts "[Optional]  #{fileType} => Rule #{inputRule[:coverage]} not solved !  :-|"
            end
         end

         if ret == false then
            if inputRule[:mandatory] == true then
               retVal = false
            end
         else
            @arrDataTypesProcessed << inputRule[:dataType]
            if inputRule[:excludeDataType] != nil then
               @arrDataTypesProcessed << inputRule[:excludeDataType]
               if @isDebugMode == true then
                  puts "Rule for #{inputRule[:dataType]} excludes Rule for #{inputRule[:excludeDataType]}"
               end
            end
         end
      }

      # ------------------------------------------

      @isResolved = retVal
      return retVal
   end
   #-------------------------------------------------------------

   def commit(bCommit = false)
      if @isResolved == false then
         return false
      end
      if @coverMode == "NRT" and @isResolved == true then
         
         if @jobId != "0" then
         
            aTrigger = TriggerProduct.find_by_id(@jobId.to_i)
         
            if aTrigger.filename == trigger.filename then
               trigger = OrchestratorQueue.getQueuedFile(@jobId)
               puts trigger.filename
               puts trigger.sensing_start
               puts trigger.sensing_stop
               puts trigger.runtime_status
               puts @dateRealStart.to_time
               puts @dateRealStop.to_time
               puts @nrtType
            
               trigger.sensing_start   = @dateRealStart.to_time
               trigger.sensing_stop    = @dateRealStop.to_time
               trigger.runtime_status  = @nrtType
               trigger.save!
            end
         end
         
         if @tRemainingStart != nil and @tRemainingStop != nil then
            cmd = "queueOrcProduct.rb -f #{@triggerFile} -s OLD "
            strStart = convert2EEString(@tRemainingStart.to_s)
            strStop  = convert2EEString(@tRemainingStop.to_s)
            cmd = "#{cmd} --start #{strStart} --stop #{strStop}"
            puts cmd
            system(cmd)
         end
      end
      return true
   end
   #-------------------------------------------------------------

   # It returns Job-Inputs   
   def getJobInputs
      if @isResolved == false then
         return Array.new
      else
         return @arrJobInputs
      end
   end
   #-------------------------------------------------------------
   
   # It returns the output types
   def getOutputTypes
      if @isResolved == false then
         return Array.new
      else
         arrTemp = Array.new
         arrTemp << @outFileType
         arrTemp << @outReportType
         return arrTemp
      end
   end
   #-------------------------------------------------------------

   def getStartWindow
      if @isResolved == false then
         return nil
      else
         return @strRealStart
      end
   end
   #-------------------------------------------------------------

   def getStopWindow
      if @isResolved == false then
         return nil
      else
         return @strRealStop
      end
   end
   #-------------------------------------------------------------

   #-------------------------------------------------------------

private
  
   #-------------------------------------------------------------
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

   # Resolve INPUT dependency. If successfull returns true,
   # otherwise it returns false.
   def resolveDependency(inputDep)
      if @isDebugMode == true then
         puts inputDep
      end

      fileType = @ftReadConf.getFileType(inputDep[:dataType])
      coverage = inputDep[:coverage]
      
      case coverage
         when "SAME"       then
            return resolveSame(fileType, @dateRealStart, @dateRealStop ,inputDep[:mandatory])
         when "ALL"        then
            return resolveAll(fileType, @dateRealStart, @dateRealStop ,inputDep[:mandatory])
         when "INTERSECT"  then
            return resolveIntersect(fileType, @dateRealStart, @dateRealStop ,inputDep[:mandatory])
         when "MATCH" then
            return resolveMatch(fileType, @dateRealStart, @dateRealStop ,inputDep[:mandatory])
         when "LAST" then
            return resolveLast(fileType, @dateRealStart, @dateRealStop, inputDep[:mandatory])
         else
            if coverage.slice(0,8) == "PAST_IN_" then            
               time = coverage.slice(7,10).to_i
               if time == 0 then
                  puts "Wrong time reference in rule #{coverage}"
               else
                  return resolvePastIn(fileType, @dateRealStart, @dateRealStop, inputDep[:mandatory], time)
               end
            else
               puts
               puts "Unknown dependency #{coverage} ! :-("
               puts
               exit(99)
            end
      end

   end

   #-------------------------------------------------------------

   # It checks an ALL rule
   def resolveAll(fileType, start, stop, mandatory)

      strStart = convert2EEString(start.to_s)
      strStop  = convert2EEString(stop.to_s) 

      cmd = "minArcRetrieve.rb -t #{fileType} -s #{strStart} -e #{strStop} -S -E -l -r LAST"
      if @isDebugMode == true then
         puts cmd
      end
      
      fRetrvr  = MINARC::FileRetriever.new(true)
            
      arrFiles = fRetrvr.getFileList_by_type(fileType, start, stop, true, true)

      bRet = false

      # Currently we get only the LAST product

      if arrFiles.empty? == false then
         selectedProduct = arrFiles[0]
         arrFiles.each{|aFile|
            if aFile.archive_date > selectedProduct.archive_date then
               selectedProduct = aFile
            end
         }

         if @isDebugMode == true then
            puts selectedProduct.filename
         end

         # If product covers the full window it is selected
         if selectedProduct.validity_start <= start and selectedProduct.validity_stop >= stop then
            anInput = Hash.new
            anInput[:filename] = selectedProduct.filename
            anInput[:strStart] = convert2JobOrderDate(selectedProduct.validity_start.to_s)
            anInput[:strStop]  = convert2JobOrderDate(selectedProduct.validity_stop.to_s)
            @arrJobInputs << anInput
            bRet = true
         end
      end
      return bRet
   end
   
   #-------------------------------------------------------------
   
   # It checks the PAST_IN rule:
   # This rule looks for products that are <delta_time> seconds 
   # in the past from the trigger product start time window
   def resolvePastIn(fileType, start, stop, mandatory, pastDeltaTime)

      stop     = start
      strStop  = convert2EEString(stop.to_s) 

      tStart   = start.to_time
      tStart   = tStart - pastDeltaTime
      start    = tStart.to_datetime
      strStart = convert2EEString(start.to_s)

      cmd = "minArcRetrieve.rb -t #{fileType} -s #{strStart} -e #{strStop} -S -E -l"
      if @isDebugMode == true then
         puts cmd
      end

      fRetrvr  = MINARC::FileRetriever.new(true)            
      arrFiles = fRetrvr.getFileList_by_type(fileType, start, stop, true, true)
      bRet     = false
      
      if @isDebugMode == true then
         arrFiles.each{|aFile|
            puts aFile.filename
         }
      end
      
      arrFiles.each{|aFile|
         decoder  = CUC::EE_ReadFileName.new(aFile.filename)
         strDateStart = decoder.getStrDateStart
         strDateStop = decoder.getStrDateStop                  
            anInput = Hash.new
            anInput[:filename] = aFile.filename
            anInput[:strStart] = convert2JobOrderDate(aFile.validity_start.to_s)
            anInput[:strStop]  = convert2JobOrderDate(aFile.validity_stop.to_s)
            @arrJobInputs << anInput
            bRet = true
      }
      return bRet
   end
   
   #-------------------------------------------------------------
   
   def resolveLast(fileType, start, stop, mandatory)

      cmd = "minArcRetrieve.rb -t #{fileType} -r LAST -l"
      if @isDebugMode == true then
         puts cmd
      end

      retriever  = MINARC::FileRetriever.new(true)
      retriever.setRule("LAST")
      arrFiles   = retriever.getFileList_by_type(fileType)      

      if arrFiles.length > 1 then
         puts "Fatal Error in DependenciesSolver::resolveLast ! :-("
         puts
         puts "Check MINARC LAST Rule :-|"
         puts
         puts cmd
         puts
         exit(99)
      end

      arrFiles.each{|aFile|
         anInput = Hash.new
         anInput[:filename] = aFile.filename
         anInput[:strStart] = convert2JobOrderDate(start.to_s)
         anInput[:strStop]  = convert2JobOrderDate(stop.to_s)

         @arrJobInputs << anInput
           
         if @isDebugMode == true then
            puts aFile.filename
         end
      }
      return !arrFiles.empty?
   end
   #-------------------------------------------------------------
   
   # It checks SAME rule
   
   def resolveSame(fileType, start, stop, mandatory)
      strStart = convert2EEString(start.to_s)
      strStop  = convert2EEString(stop.to_s) 

      cmd = "minArcRetrieve.rb -t #{fileType} -s #{strStart} -e #{strStop} -l"
      if @isDebugMode == true then
         puts cmd
      end
      
      fRetrvr  = MINARC::FileRetriever.new(true)
      arrFiles = fRetrvr.getFileList_by_type(fileType, start, stop, true, true)

      if @isDebugMode == true then
         arrFiles.each{|aFile|
            puts aFile.filename
         }
      end

      # --------------------------------
      # Fill up job-order input files      
      if arrFiles.empty? == false then

         arrFiles.each{|aFile|
            anInput = Hash.new
            anInput[:filename] = aFile.filename
            anInput[:strStart] = convert2JobOrderDate(start.to_s)
            anInput[:strStop]  = convert2JobOrderDate(stop.to_s)

            if aFile.validity_start == start and aFile.validity_stop == stop then
               if @isDebugMode == true then
                  puts aFile.filename
               end
               @arrJobInputs << anInput
               break
            end
         }
      end
      # --------------------------------
      return !arrFiles.empty?
   end
   #-------------------------------------------------------------
   
   # It checks an INTERSECT rule
   def resolveIntersect(fileType, start, stop, mandatory)

      strStart = convert2EEString(start.to_s)
      strStop  = convert2EEString(stop.to_s) 

      cmd = "minArcRetrieve.rb -t #{fileType} -s #{strStart} -e #{strStop} -S -E -l"
      if @isDebugMode == true then
         puts cmd
      end
      
      fRetrvr  = MINARC::FileRetriever.new(true)
      arrFiles = fRetrvr.getFileList_by_type(fileType, start, stop, true, true)

      # --------------------------------
      # Fill up job-order input files      
      if arrFiles.empty? == false then

         # -----------------------------
         # Check whether a single product might cover the whole 
         # time window
         
         arrFiles.each{|aFile|
         
            ret = isFullCover?(aFile, start, stop)
            
            if ret == true then
               if @isDebugMode == true then
                  puts aFile.filename
               end
               anInput = Hash.new
               anInput[:filename] = aFile.filename
               anInput[:strStart] = convert2JobOrderDate(start.to_s)
               anInput[:strStop]  = convert2JobOrderDate(stop.to_s)

               @arrJobInputs << anInput
               return true
            end
         }
         # -----------------------------
         
         # DANGER:
         # It is supposed files are sorted in validity time although
         # It is not written anywhere

         
         arrFiles.each{|aFile|
            if @isDebugMode == true then
               puts aFile.filename
            end
            
            anInput = Hash.new
            anInput[:filename] = aFile.filename

            # Trim Validity Start
            if aFile.validity_start < start then
               anInput[:strStart] = convert2JobOrderDate(start.to_s)
            else
               anInput[:strStart] = convert2JobOrderDate(aFile.validity_start.to_s)
            end

            # Trim Validity Stop
            if aFile.validity_stop > stop then
               anInput[:strStop] = convert2JobOrderDate(stop.to_s)
            else
               anInput[:strStop] = convert2JobOrderDate(aFile.validity_stop.to_s)
            end

            @arrJobInputs << anInput

         }
         
      end
      # --------------------------------
      return !arrFiles.empty?
   end
   
   #-------------------------------------------------------------   
   
   # It checks a MATCH rule
   def resolveMatch(fileType, start, stop, mandatory)

      arrCandidates = Array.new
 
      strStart = convert2EEString(start.to_s)
      strStop  = convert2EEString(stop.to_s) 

      cmd = "minArcRetrieve.rb -t #{fileType} -s #{strStart} -e #{strStop} -S -E -l"
      if @isDebugMode == true then
         puts cmd
      end
      
      fRetrvr  = MINARC::FileRetriever.new(true)
      arrFiles = fRetrvr.getFileList_by_type(fileType, start, stop, true, true)

      # --------------------------------
      # Fill up job-order input files      
      if arrFiles.empty? == false then

          arrFiles.each{|aFile|
             arrCandidates << aFile
          }
      end
      # --------------------------------

      # Perform Match Selection
     
      if arrCandidates.length > 0 then
      
         matchedFile = arrCandidates[0]
      
         arrCandidates.each{|candidateFile|
            if candidateFile.validity_start <= start and candidateFile.validity_stop >= stop then
               matchedFile = candidateFile
            end
         }
         
         if @isDebugMode == true then
            puts matchedFile.filename
         end
            
         anInput = Hash.new
         anInput[:filename] = matchedFile.filename
         
         # Trim Validity Start
         if matchedFile[:validity_start] < start then
            anInput[:strStart] = convert2JobOrderDate(start.to_s)
         else
            anInput[:strStart] = convert2JobOrderDate(matchedFile[:validity_start].to_s)
         end

         # Trim Validity Stop
         if matchedFile[:validity_stop] > stop then
            anInput[:strStop] = convert2JobOrderDate(stop.to_s)
         else
            anInput[:strStop] = convert2JobOrderDate(matchedFile[:validity_stop].to_s)
         end
 
         @arrJobInputs << anInput
 
       end
      # --------------------------------
      return !arrCandidates.empty?
   end   
   #-------------------------------------------------------------

   # This method checks whether trigger dates in filename are coherent
   # and converts them into DateTime objects
   def checkDates
      begin
         @startVal = DateTime.parse(@strNominalStart)
         @endVal   = DateTime.parse(@strNominalEnd)
         
#          puts @dateNominalStart
#          puts @startVal
#          
#          puts @dateNominalStop
#          puts @endVal
         
      rescue Exception
         puts
         puts "Fatal Error at DependenciesSolver::checkDates"
         puts "Invalid date format or date out of bounds ! :-("
         puts
         exit(99)
      end

      if @startVal > @endVal then
         puts
         puts "Fatal Error at DependenciesSolver::checkDates"
         puts "End date must be greater than start date ! :-("
         puts
         RDoc::usage("usage")
         exit(99)
      end
      
      if @dateNominalStart >  @dateNominalStop then
         puts
         puts "Fatal Error at DependenciesSolver::checkDates"
         puts "dateNominalStop #{@dateNominalStop} must be greater than start #{@dateNominalStart} ! :-("
         puts
         RDoc::usage("usage")
         exit(99)      
      end
      
   end
   #-------------------------------------------------------------
   
   # Calculate Final Trigger Window based on the coverage mode 
   def calcEffectiveTimeWindow
     
     
      # --------------------------------
     
      if @coverMode == "NRT" then     
         ret = calculateTimeNRT
      
         if ret == false and @isDebugMode == true then
            puts
            puts "Request in NRT mode is already covered ! ;-p"
         end
         return ret
      end     
      # --------------------------------
     
      if @coverMode == "CONT" then
         ret = calculateTimeContinuous
      
         if ret == false then
            if @isDebugMode == true then
               puts
               puts "Request in continuous mode is already covered ! ;-p"
            end
         else
            if @isDebugMode == true then
               puts "Final Start-----------------Final Stop---------------"
               print @dateRealStart, " - ", @dateRealStop, "\n"
            end         
         end
         
         return ret
      end
      # --------------------------------
      
      
      # --------------------------------
      
      if @coverMode == "SAME" then
         ret = calculateTimeSame         
         return ret
      end
      # --------------------------------
      return false

   end
   #-------------------------------------------------------------

   def calculateTimeSame
      @dateRealStart = DateTime.parse(@strNominalStart, "%Y%m%dT%H%M%S")
      @dateRealStop  = DateTime.parse(@strNominalEnd, "%Y%m%dT%H%M%S")

      @strRealStart  = @strNominalStart
      @strRealStop   = @strNominalEnd
      return true
   end
   #-------------------------------------------------------------

   # This method calculates trigger applicable start & stop
   # based on the NRT rules
   def calculateTimeNRT

      @tRemainingStart  = nil
      @tRemainingStop   = nil
      @nrtType          = nil
      
      dateNow = DateTime.now
      timeNow = Time.now

      if @isDebugMode == true then
         puts
         puts "Date Now is #{dateNow}"
         puts "Trigger coverage BEFORE NRT trimmering is:"
         puts "#{@dateNominalStart} - #{@dateNominalStop}"
      end

      # --------------------------------
      # Trim trigger with PRODUCTION_TIMELINE
      ret = trimTriggerByProduction
      
      if ret == true then
         @bTrimmered       = true
         @dateNominalStart = @dateRealStart
         @dateNominalStop  = @dateRealStop
      else
         return false
      end
                  
      # --------------------------------
                  
      # Set Orbit length rounded to 95 mins to manage overlaps:
      #
      # Although it is known that Orbit shall be 90 minutes aprox
      # NRT L0 FEP will provide orbit products with some overlap
      # and if all their coverage is missing in PRODUCTION_TIMELINE
      # it is not desired to trimmer them
      
      oneOrbitLength = (95.0/60.0) * 60.0 * 60.0
      oneHour        = 1.0 * 60.0 * 60.0
      twoHours       = 2.0 * 60.0 * 60.0

      tStart = @dateNominalStart.to_time
      tStop  = @dateNominalStop.to_time
      tDelta = tStop - tStart
     
     
      # Trim Products to one orbit length aprox
     
      if (tDelta > oneOrbitLength) then
         @tRemainingStart  = tStart.to_datetime
         @tRemainingStop   = (tStop - oneOrbitLength - 1.0).to_datetime
         @bTrimmered       = true
         tStart            = tStop - oneOrbitLength
         @dateNominalStart = tStart.to_datetime
         if @isDebugMode == true then
            puts "Trim to 1 orbit length: #{@dateNominalStart} - #{@dateNominalStop}"
            puts "Remaining coverage => : #{@tRemainingStart} - #{@tRemainingStop}"
            puts
         end      
      end
     

      @nrtType = NRT_TRIGGER_UNKNOWN
     
      # Adjust nominal Time to NRT rules
      # Currently it is assumed 30 minutes for the processing
      # plus 30 minutes for product management
      # for the cutting strategy
      # Therefore there are 120 minutes left from the 
      # 180 minutes NRT strategy
      
      # ====================================================
      # 
      # Cut OLD products management
      #
      # In order to avoid OLD products die of starvation,
      # They are cut to be only one hour sensing at each time
      
      if (tStop + twoHours) < timeNow then
         @nrtType = NRT_TRIGGER_OLD
         if @isDebugMode == true then
            puts "NRT Trigger classified as OLD type"
         end
         if (tStop - tStart) > oneHour then
            tStart            = tStop - oneHour
            @dateNominalStart = tStart.to_datetime
            @tRemainingStop   = (tStart - 1.0).to_datetime
            if @isDebugMode == true then
               puts "Trimmer cover one hour: #{@dateNominalStart} - #{@dateNominalStop}"
            end            
         end

      end

      # ====================================================
      # 
      # MIXED products management
      # 
      # Mixed products are cut to process first its NRT coverage
      # and later on the OLD part with a different Job-Order 
    
      if ((tStart + twoHours) < timeNow) and ((tStop + twoHours) > timeNow) then
         @nrtType          = NRT_TRIGGER_MIXED
         tStart            = timeNow - twoHours
         @dateNominalStart = tStart.to_datetime
         @tRemainingStop   = (tStart - 1.0).to_datetime
         if @isDebugMode == true then
            puts "NRT Trigger classified as MIXED type"
            puts "Trim to only NRT cover: #{@dateNominalStart} - #{@dateNominalStop}"
            puts "Remaining coverage => : #{@tRemainingStart} - #{@tRemainingStop}"
         end
      end
      
      # ====================================================
      # 
      # NRT products management
    
      if ((tStart + twoHours) >= timeNow) and ((tStop + twoHours) > timeNow) and
          (tStop < timeNow) and @nrtType != NRT_TRIGGER_MIXED then
         @nrtType = NRT_TRIGGER_NRT
         if @isDebugMode == true then
            puts "NRT Trigger classified as NRT type"
         end
      end


      # ====================================================
      # 
      # FUTURE products management
      #
      # Yes, there might be FUTURE products!
      # Although this case SHOULD NOT happen, a system time
      # missalignment between NRT hosts and PDPC might produce it.
      # As well there might be a problem in the L0 NRT chain.

      if tStop > timeNow then
         @nrtType = NRT_TRIGGER_FUTURE
         if @isDebugMode == true then
            puts "NRT Trigger classified as FUTURE type"
         end      
      end

#exit

      if @isDebugMode == true then
         puts
         puts "Final coverage of #{@nrtType} product:"
         puts @dateNominalStart
         puts @dateNominalStop
         
         # If Trigger has been cut
         if @tRemainingStart != nil and @tRemainingStop != nil then
            puts
            puts "Trigger remaining sensing to process :"
            puts @tRemainingStart
            puts @tRemainingStop
         end
      end

      @dateRealStart = @dateNominalStart
      @dateRealStop  = @dateNominalStop

   end
   #-------------------------------------------------------------

   # We will destroy you
   
   def calculateTimeContinuous
      cmd = "extractTimelineGaps.rb -t #{@outFileType} -s #{@strNominalStart}"
      cmd = "#{cmd} -e #{@strNominalEnd} -l"
      if @isDebugMode == true then
         puts cmd
      end
      
      # Extract all portions of the production timeline for the given file-type and time interval
      arrTimeLines = ProductionTimeline.searchAllWithinInterval(@outFileType, @startVal, @endVal, true, true)

      # Extract the gaps to calculate new trigger window
      extractor    = GapsExtractor.new(arrTimeLines, @filetype, @startVal, @endVal)   
      arrGaps      = extractor.calculateGaps
      firstGap     = nil

      arrGaps.each{|segment|            
         if @isDebugMode == true then
            puts segment
         end
         # Get first GAP segment
         if segment.isEmpty? == true then
            firstGap = segment
            break
         end
      }

      if firstGap != nil then
         @dateRealStart = firstGap.getStartTime
         @dateRealStop  = firstGap.getEndTime
         @strRealStart  = firstGap.getStrStartTime
         @strRealStop   = firstGap.getStrStopTime
         return true
      else
         @dateRealStart = DateTime.parse(@strNominalStart, "%Y%m%dT%H%M%S")
         @dateRealStop  = DateTime.parse(@strNominalEnd, "%Y%m%dT%H%M%S")
         @strRealStart  = @strNominalStart
         @strRealStop   = @strNominalEnd         
         return false
      end
   end
   #-------------------------------------------------------------

   # It returns true if the segment fully covers requested window
   def isFullCover?(aFile, start, stop)
      if aFile.validity_start <= start and aFile.validity_stop >= stop then
         return true
      else
         return false
      end
   end
   #-------------------------------------------------------------

   # It trims by production_timeline 

   def trimTriggerByProduction
      cmd = "extractTimelineGaps.rb -t #{@outFileType} -s #{@strNominalStart}"
      cmd = "#{cmd} -e #{@strNominalEnd} -l"
      if @isDebugMode == true then
         puts
         puts cmd
      end
      
      # Extract all portions of the production timeline for the given file-type and time interval
      arrTimeLines = ProductionTimeline.searchAllWithinInterval(@outFileType, @dateNominalStart, @dateNominalStop, true, true)

      # Extract the gaps to calculate new trigger window
      extractor    = GapsExtractor.new(arrTimeLines, @filetype, @dateNominalStart, @dateNominalStop)   
      arrGaps      = extractor.calculateGaps
      firstGap     = nil

      arrGaps.each{|segment|            
         if @isDebugMode == true then
            puts segment
         end
         # Get first GAP segment
         if segment.isEmpty? == true then
            firstGap = segment
            break
         end
      }

      ret = nil
      
      if firstGap != nil then
         @dateRealStart = firstGap.getStartTime
         @dateRealStop  = firstGap.getEndTime
         @strRealStart  = firstGap.getStrStartTime
         @strRealStop   = firstGap.getStrStopTime
         ret = true
      else
         @dateRealStart = DateTime.parse(@strNominalStart, "%Y%m%dT%H%M%S")
         @dateRealStop  = DateTime.parse(@strNominalEnd, "%Y%m%dT%H%M%S")
         @strRealStart  = @strNominalStart
         @strRealStop   = @strNominalEnd         
         ret = false
      end
      
      if @isDebugMode == true and ret == true then
         puts "Trimmer by ProductionTimeline: #{@strRealStart} - #{@strRealStop}"
         puts
      end
      
      return ret
   end
   #-------------------------------------------------------------

end #end class

end #module
