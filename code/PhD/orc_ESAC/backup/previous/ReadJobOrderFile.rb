#!/usr/bin/env ruby

#########################################################################
#
# ===Ruby source for #ReadJobOrderFile class          
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS => ORC Component
# 
# CVS: $Id: ReadJobOrderFile.rb,v 1.1 2009/02/06 17:44:26 algs Exp $
#
# This class processes job-order files to extract its information
#
#########################################################################

require 'rexml/document'


module ORC

class ReadJobOrderFile

   include REXML

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(full_path_job_order_file)
      @isDebugMode        = false
      checkModuleIntegrity
      @full_path_name     = full_path_job_order_file
      @filename           = File.basename(full_path_job_order_file)
      defineStructs
      loadData
   end
   #-------------------------------------------------------------
  
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadJobOrderFile debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Ir checks whether provided file is really a job order file

   def isJobOrderFile?
      return true
   end
   #-------------------------------------------------------------
   
   def getJobOrderId
      return @jobOrderId
   end
   #-------------------------------------------------------------
   
   def getInputsList
      return @ListOfInputFiles
   end
   #-------------------------------------------------------------

   def getOutputsList
      return @ListOfOutputFiles
   end
   #-------------------------------------------------------------


   #---------------Private section-------------------------------
   #-------------------------------------------------------------
 
private
   
   #-------------------------------------------------------------
   
   def defineStructs
      Struct.new("InputFile", :fileName, :fileType, :directory, :start, :stop)
      Struct.new("OutputFile", :fileType, :directory, :counter)
   end
   #-------------------------------------------------------------
       
   def fillInputFile(filename, filetype, directory, start, stop)
      if @isDebugMode == true then
         puts "=========================================="
         puts filename
         puts filetype
         puts directory
         puts start
         puts stop
         puts "==========================================" 
      end
      return Struct::InputFile.new(filename, filetype, directory, start, stop)
   end
   #-------------------------------------------------------------

   def fillOutputFile(filetype, directory, counter)
      if @isDebugMode == true then
         puts "=========================================="
         puts filetype
         puts directory
         puts counter
         puts "==========================================" 
      end
      return Struct::OutputFile.new(filetype, directory, counter)
   end        
   #-------------------------------------------------------------

   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def loadData

      jobFile        = File.new(@full_path_name)
      xmljobFile     = REXML::Document.new(jobFile)     
      
      parseJobOrderHeader(xmljobFile)

      parseListOfProcs(xmljobFile)

      parseListOutputs(xmljobFile)

   end   
   #-------------------------------------------------------------
 
   # Process File, Data providers module
   # - xmlFile (IN): XML file 
   def parseJobOrderHeader(xmlFile)
      
      @jobOrderId = -1

      XPath.each(xmlFile,"Job_Order/OrderId/"){
         |orderId|
         @jobOrderId = orderId.text
      }
 
   end
   #-------------------------------------------------------------

   # Process list of inputs
   # - xmlFile (IN): XML file 
   def parseListOfProcs(xmlFile)
      
      fileType    = ""
      fileName    = ""
      directory   = ""
      start       = ""
      stop        = ""

      @ListOfInputFiles = Array.new
      
      XPath.each(xmlFile,"Job_Order/List_of_Procs/Proc/List_of_Inputs/Input"){#/List_of_Procs/Proc/List_of_Inputs"){      
         |anInput|

         XPath.each(anInput, "File_Type"){
            |aFileType|
            fileType = aFileType.text
         }

         XPath.each(anInput, "List_of_Time_Intervals/Time_Interval"){
            |aTimeInterval|

            XPath.each(aTimeInterval, "Start"){
               |anStart|
               start = anStart.text
            }

            XPath.each(aTimeInterval, "Stop"){
               |anStop|
               stop = anStop.text
            }

            XPath.each(aTimeInterval, "File_Name"){
               |aFilename|
               fileName  = File.basename(aFilename.text)
               directory = File.dirname(aFilename.text)
            }

            @ListOfInputFiles << fillInputFile(fileName, fileType, directory, start, stop)

         }

      }

   end
   #-------------------------------------------------------------------------

   # Process list of outputs
   # - xmlFile (IN): XML file 
   def parseListOutputs(xmlFile)
      fileType    = ""
      directory   = ""
      counter     = ""

      @ListOfOutputFiles = Array.new
      
      XPath.each(xmlFile,"Job_Order/List_of_Procs/Proc/List_of_Outputs/Output"){
         |anOutput|

         XPath.each(anOutput, "File_Type"){
            |aFileType|
            fileType = aFileType.text
         }

         XPath.each(anOutput, "File_Name"){
            |aDir|
            directory = aDir.text
         }

         XPath.each(anOutput, "File_Counter"){
            |aCounter|
            counter = aCounter.text
         }

         @ListOfOutputFiles << fillOutputFile(fileType, directory, counter)
 
      }

   end
   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
   end
   #-------------------------------------------------------------
   #-------------------------------------------------------------
  
end # class

end # module
