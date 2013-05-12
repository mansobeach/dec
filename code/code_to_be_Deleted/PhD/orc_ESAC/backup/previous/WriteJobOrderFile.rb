#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #WriteJobOrderFile class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS => ORC Component
# 
# CVS: $Id: WriteJobOrderFile.rb,v 1.4 2009/02/16 12:21:04 decdev Exp $
#
# module ORC
#
#########################################################################


require 'rexml/document'

require 'cuc/EE_ReadFileName'
require 'cuc/DirUtils'
require 'orc/ORC_DataModel'


module ORC

class WriteJobOrderFile

   include CUC::DirUtils
   include REXML

   #-------------------------------------------------------------
   
   # Class constructor.
   # IN Parameters:
   def initialize(dir, start, stop, jobId, counter, sequence, site_id)
      @full_path_dir = dir
      @jobStart      = start
      @jobStop       = stop
      @jobId         = jobId.to_s.rjust(15, '0')
      @counter       = counter
      @sequence      = sequence
      @site_id       = site_id
      @isDebugMode   = false
		checkModuleIntegrity
      createJobName
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "WriteJobOrderFile debug mode is on"
   end
   #-------------------------------------------------------------

   
   #-------------------------------------------------------------

   # Main class method
   # It writes the data to the report.
   def writejob(arrInputs, arrOutputs, dir)
      @full_path_dir = dir
      writeJobOrder(arrInputs ,arrOutputs)
   end
   #-------------------------------------------------------------

private

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      checkDirectory(@full_path_dir)
   end
   #-------------------------------------------------------------

   def createJobName
      @strJobFileName   = "SM_OPER_MPL_JOBORD_#{@jobStart}_#{@jobStop}_#{@jobId}_#{@counter}_#{@sequence}_#{@site_id}.xml"
      @fullPathFileName = "#{@full_path_dir}/#{@strJobFileName}"
      if @isDebugMode == true then
         puts @strJobFileName
         puts @fullPathFileName
      end
   end
   #-------------------------------------------------------------

   def writeJobOrder(arrInputFiles, arrOutputTypes)
         
      doc = Document.new 
      doc.add_element 'Job_Order'
      doc << XMLDecl.new

      # --------------------------------
      # First Section : OrderId
      orderId = Element.new "OrderId"
      orderId.text = @jobId.to_i.to_s
      doc.root.elements << orderId

      # --------------------------------
      # Second Section : Conf
      conf = Element.new "Conf"
      
         # Processor Name
         procName       = Element.new "Processor_Name"
         procName.text  = "DummyProcessor"
         conf << procName

         # Version
         version       = Element.new "Version"
         version.text  = "01_01"
         conf << version

         # Proc Type
         procType       = Element.new "Process_Type"
         procType.text  = "SYSTEMATIC"
         conf << procType

         # Log_Level
         logLevel       = Element.new "Log_Level"
         logLevel.text  = "INFO"
         conf << logLevel

         # Control_Folder
         controlFolder  = Element.new "Control_Folder"
         controlFolder.text  = "#{@full_path_dir}/control"
         conf << controlFolder

         # Test
         test  = Element.new "Test"
         test.text  = "False"
         conf << test

         # TroubleShooting
         tb  = Element.new "Troubleshooting"
         tb.text  = "False"
         conf << tb

         # Processing_Station
         procStation       = Element.new "Processing_Station"
         procStation.text  = "1"
         conf << procStation

         # Phase
         phase       = Element.new "Phase"
         phase.text  = "OPER"
         conf << phase

         # Config_Files
         confFiles = Element.new "Config_Files"
         confFiles.attributes["count"] = "0"
         conf << confFiles

      doc.root.elements << conf

      # --------------------------------

      # --------------------------------
      # Third Section : <List_of_Procs>

      listOfProcs = Element.new "List_of_Procs"
      listOfProcs.attributes["count"] = "1"

         aProc    = Element.new "Proc"
         
         taskName = Element.new "Task_Name"
         taskName.text = "DummyProcessor" 
         aProc << taskName

         taskVersion = Element.new "Task_Version"
         taskVersion.text = "01_01" 
         aProc << taskVersion
        
         bkpoints = Element.new "Breakpoint"
         enable   = Element.new "Enable"
         enable.text = "OFF"
         bkpoints << enable
         listOfBrks = Element.new "List_of_Brk_Files"
         listOfBrks.attributes["count"] = "0"
         bkpoints << listOfBrks
         aProc << bkpoints         

         # List of Inputs
         numInputs = arrInputFiles.length
         listInputs = Element.new "List_of_Inputs"
         listInputs.attributes["count"] = numInputs.to_s

         arrInputFiles.each{|anInputFile|

            anInput  = Element.new "Input"

               fileType = Element.new "File_Type"
               fileType.text = CUC::EE_ReadFileName.new(anInputFile[:filename]).fileType
               anInput << fileType

               fileNameType       = Element.new "File_Name_Type"
               fileNameType.text  = CUC::EE_ReadFileName.new(anInputFile[:filename]).fileNameType
               anInput << fileNameType

               listOfFNames      = Element.new "List_of_File_Names"
               listOfFNames.attributes["count"] = "1"

               oneInputFilename  = Element.new "Input_File"
               
               strFilename       = anInputFile[:filename]

               oneFilename       = Element.new "File_Name"
               oneFilename.add(Text.new("#{@full_path_dir}/inputs/#{anInputFile[:filename].to_s}"))
               oneInputFilename   << oneFilename
 
               aState            = Element.new "State"
               aState.text       = "Non alternative"
               oneInputFilename << aState

               listOfFNames   << oneInputFilename

              

               anInput << listOfFNames


               listOfTIntervals  = Element.new "List_of_Time_Intervals"
               listOfTIntervals.attributes["count"] = "1"

               aTimeInterval     = Element.new "Time_Interval"

               aTimeStart        = Element.new "Start"
               aTimeStart.text   = anInputFile[:strStart]
               aTimeInterval << aTimeStart

               aTimeStop         = Element.new "Stop"
               aTimeStop.text    = anInputFile[:strStop]
               aTimeInterval << aTimeStop

               fpFilename2 = Element.new "file_name"
               fpFilename2.add  Text.new("#{@full_path_dir}/inputs/#{anInputFile[:filename].to_s}")
               aTimeInterval << fpFilename2

               listOfTIntervals << aTimeInterval
 
               anInput << listOfTIntervals

               listInputs << anInput
         }
         
         aProc << listInputs


         # List of Outputs
         numOutputs  = arrOutputTypes.length
         listOutputs = Element.new "List_of_Outputs"
         listOutputs.attributes["count"] = numOutputs.to_s


         arrOutputTypes.each{|outputType|

            anOutput  = Element.new "Output"

            aFileType = Element.new "File_Type"
            aFileType.text = outputType
            anOutput << aFileType

            aFileNameType = Element.new "File_Name_Type"
            aFileNameType.text = "Directory"
            anOutput << aFileNameType

            aFileName = Element.new "File_Name"
            aFileName.add Text.new("#{@full_path_dir}/outputs/")
            anOutput << aFileName

            aCounter = Element.new "File_Counter"
            aCounter.text = "001"
            anOutput << aCounter

            listOutputs << anOutput

         }

         aProc << listOutputs

         listOfProcs << aProc

      doc.root.elements << listOfProcs
      
      file = File.open(@fullPathFileName, "w")
      
      doc.write(file, 2)
      
      file.close
   end
   #-------------------------------------------------------------
   #-------------------------------------------------------------


end # class

end # module
