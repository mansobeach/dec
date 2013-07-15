#!/usr/bin/ruby

#########################################################################
#
# === Ruby source for #CheckerInTrayConfig class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# ==  Data Exchange Component -> Data Collector Component
# 
# CVS:  $Id: CheckerInTrayConfig.rb,v 1.3 2007/12/19 06:03:48 decdev Exp $
#
# === module Data Collector Component (DCC)
# This class is in charge of verify that the dissemination configuration
# defined in files2InTrays.xml is correct.
#
# ==== This class is in charge of verify that integrity of files2InTrays.
# ==== This is to check that In-Trays specified for a file-type are defined.
# ==== As well it is in charge of verifying coherency with ft_incoming_files.xml
#
#########################################################################

require 'ctc/ReadFileSource'
require 'dcc/ReadInTrayConfig'
require 'cuc/DirUtils'


module DCC


class CheckerInTrayConfig
   
   include CUC::DirUtils 
   #--------------------------------------------------------------

   # Class constructor.
   def initialize
      checkModuleIntegrity
      @dccReadConf = DCC::ReadInTrayConfig.instance
      @dccIncoming = CTC::ReadFileSource.instance
   end
   #-------------------------------------------------------------
   
   # ==== Main method of the class
   # ==== It returns a boolean True whether checks are OK. False otherwise.
   def check     
      retVal       = true      
      arrDims      = @dccReadConf.getAllDIMs
 
      arrDims.each{|dim|
          
         inTray = @dccReadConf.getDIMInTray(dim)

         if @isDebugMode == true then
            puts "Verifying #{dim} configuration ..."
            puts "InTray: #{inTray}"
         end
  
         if inTray == false then
            retVal = false
            puts "#{dim} is not declared in the DIM_List"
         else
            checkDirectory(inTray)
         end
      }     
      
      arrTypes = @dccReadConf.getAllFileTypes
     
      arrTypes.each{|type|
         arrDest = @dccReadConf.getDIMs4Filetype(type)
 
         if @isDebugMode == true then
            puts "Verifying #{type} configuration ..."
            puts "DIMs: #{arrDest}"
         end
         
         if arrDest == false then
            puts "No target DIMs for #{type} filetype in files2Dims.xml" 
            retVal = false          
         end
         
         arrDest.each{|adim|
            intray = @dccReadConf.getDIMInTray(adim)
            if intray == false then
               retVal = false
               puts "#{type} - #{adim} is not declared in the DIM_List"
            end
         }
      }

      # Perform integrity between ft_incoming_files.xml & files2Dims.xml
      arrIncomingTypes = @dccIncoming.getAllIncomingFiles
      arrIncomingTypes.each{|fileType|
         if @dccReadConf.existFileType?(fileType) == false then
            puts "Warning ! Incoming files #{fileType} are not disseminated to any In-Tray  :-|"
         end
      }
      
      # Check whether disseminated types are defined in ft_incoming_files.xml
      # In case a given file-type is not defined a warning is raised.
      # There are some file-types (e.g. DCC own generated reports) that are not received
      # for any Interface but they are disseminated locally
      arrTypes.each{|type|
         if arrIncomingTypes.include?(type) == false then
            puts "Warning ! Disseminated files #{type} are not received from any I/F  :-|"
         end
      }

      
#       if retVal == false then
#          puts
#          puts "Error in files2Dims.xml configuration"
#          puts "Please check your configuration file"
#          puts
#       end
      return retVal
   end
   #-------------------------------------------------------------

   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "DCC_CheckerDimInTrayConfig debug mode is on"
   end
   #-------------------------------------------------------------

private

   @isDebugMode       = false      

   #-------------------------------------------------------------

   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   #-------------------------------------------------------------

end # class

end # module
