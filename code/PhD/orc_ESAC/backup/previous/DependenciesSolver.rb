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

require 'cuc/DirUtils'
require 'cuc/Log4rLoggerFactory'
require 'cuc/EE_ReadFileName'
require 'cuc/EE_DateConverter'

require 'minarc/FileRetriever'

require 'orc/ReadOrchestratorConfig'
require 'orc/ORC_DataModel'
require 'orc/GapsExtractor'


module ORC


class DependenciesSolver
   
   include CUC::DirUtils
   include CUC::EE_DateConverter

   #-------------------------------------------------------------
  
   # Class constructor

   def initialize(triggerFile)
      @isDebugMode   = false
      @isConfigured  = false
      @isResolved    = false

      @triggerFile = triggerFile
      nameDecoder  = CUC::EE_ReadFileName.new(@triggerFile)
      
      @triggerType      = nameDecoder.getFileType
      @strNominalStart  = nameDecoder.getStrDateStart
      @strNominalEnd    = nameDecoder.getStrDateStop

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

      @outReportType = String.new(@outFileType)
      @outReportType[0] = 'R'
      @outReportType[1] = 'E'
      @outReportType[2] = 'P'

      if @outFileType == "" or @outFileType == nil or @coverMode == nil then
         puts "Fatal Error in DependenciesSolver::initialize ! :-("
         puts
         exit(99)
      end   
   
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
   
   # Main method of this class that performs the dependencies
   # checker
   def resolve

      @isResolved    = false
      
      # Array to keep all required inputs
      @arrJobInputs  = Array.new

      @listOfInputRules = @ftReadConf.getListOfInputsByTriggerDataType(@dataType)

      if @listOfInputRules == nil then
         if @isDebugMode == true then
            puts "No dependencies to be resolved 4 #{@dataType} ! :-|"
            puts
         end
         return false
      end

      retVal = true

      @listOfInputRules.each { |inputRule|
         
         ret = resolveDependency(inputRule)

         if ret == false then
            retVal = false
         end
      }

      @isResolved = retVal
      return retVal
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

   def resolveDependency(inputDep)
      if @isDebugMode == true then
         puts inputDep
      end

      fileType = @ftReadConf.getFileType(inputDep[:dataType])

      case inputDep[:coverage]
         when "SAME"       then
         when "ALL"        then
            return resolveAll(fileType, @dateRealStart, @dateRealStop ,inputDep[:mandatory])
         when "INTERSECT"  then
            return resolveIntersect(fileType, @dateRealStart, @dateRealStop ,inputDep[:mandatory])
      end

   end

   #-------------------------------------------------------------

   # It checks an ALL rule
   def resolveAll(fileType, start, stop, mandatory)

      strStart = convert2EEString(start.to_s)
      strStop  = convert2EEString(stop.to_s) 

      cmd = "minArcRetrieve.rb -t #{fileType} -s #{strStart} -e #{strStop} -S -E -l -r LAST"
      
      fRetrvr  = MINARC::FileRetriever.new(true)
      arrFiles = fRetrvr.getFileList_by_type(fileType, start, stop, true, true)

      if @isDebugMode == true then
         puts "Resolving ALL rule #{fileType} :"
         puts cmd
      end

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
      else
         if @isDebugMode == true then
            puts "Rule ALL not solved !  :-("
         end
      end
   
   end
   #-------------------------------------------------------------
   
   # It checks an INTERSECT rule
   def resolveIntersect(fileType, start, stop, mandatory)

      strStart = convert2EEString(start.to_s)
      strStop  = convert2EEString(stop.to_s) 

      cmd = "minArcRetrieve.rb -t #{fileType} -s #{strStart} -e #{strStop} -S -E -l"
      
      fRetrvr  = MINARC::FileRetriever.new(true)
      arrFiles = fRetrvr.getFileList_by_type(fileType, start, stop, true, true)

      if @isDebugMode == true then
         puts "Resolving INTERSECT rule #{fileType} :"
         puts cmd
         arrFiles.each{|aFile|
            puts aFile.filename
         }
         if arrFiles.empty? == true then
            puts "Rule INTERSECT not solved !  :-("
         else
            puts "Rule INTERSECT has been solved !  :-)"
         end
      end

      # --------------------------------
      # Fill up job-order input files      
      if arrFiles.empty? == false then

         arrFiles.each{|aFile|
            anInput = Hash.new
            anInput[:filename] = aFile.filename
            anInput[:strStart] = convert2JobOrderDate(start.to_s)
            anInput[:strStop]  = convert2JobOrderDate(stop.to_s)

            @arrJobInputs << anInput

         }

      end
      # --------------------------------

      if mandatory == false then
         return true
      else
         return !arrFiles.empty?
      end

   end
   #-------------------------------------------------------------

   # This method checks whether trigger dates in filename are coherent
   # and converts them into DateTime objects
   def checkDates
      begin
         @startVal = DateTime.parse(@strNominalStart)
         @endVal   = DateTime.parse(@strNominalEnd)
      rescue Exception
         puts
         puts "Fatal Error at DependenciesSolver::checkDates"
         puts "Invalid date format or date out of bounds ! :-("
         puts
         exit(99)
      end

      if @startVal >= @endVal then
         puts
         puts "Fatal Error at DependenciesSolver::checkDates"
         puts "End date must be greater than start date ! :-("
         puts
         RDoc::usage("usage")
         exit(99)
      end
   end
   #-------------------------------------------------------------
   
   # Calculate Final Trigger Window based on the coverage mode 
   def calcEffectiveTimeWindow
     
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
      @dateRealStop  = DateTime.parse(@strNominalStop, "%Y%m%dT%H%M%S")
      @strRealStart  = @strNominalStart
      @strRealStop   = @strNominalStop
      return true
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
         @dateRealStart = nil
         @dateRealStop  = nil
         return false
      end
   end
   #-------------------------------------------------------------

end #end class

end #module
