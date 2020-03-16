#!/usr/bin/ruby

#########################################################################
#
# === Ruby source for #CheckerInTrayConfig class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# ==  Data Exchange Component
# 
# Git:  $Id: CheckerInTrayConfig.rb,v 1.3 2007/12/19 06:03:48 decdev Exp $
#
# This class is in charge of verify that the dissemination configuration
# defined in dec_incoming_files.xml is correct.
#
# ==== This class is in charge of verify that integrity of dec_incoming_files.xml
# ==== This is to check that In-Trays specified for a file-type are defined.
#
#########################################################################

require 'sys/filesystem'

require 'cuc/DirUtils'
require 'dec/ReadConfigIncoming'

module DEC

class CheckerInTrayConfig
   
   include CUC::DirUtils
   include Sys 
   ## -----------------------------------------------------------

   ## Class constructor.
   def initialize
      checkModuleIntegrity
      @decReadConf = ReadConfigIncoming.instance
      @dccIncoming = ReadConfigIncoming.instance
   end
   ## -----------------------------------------------------------
   
   ## Main method of the class
   ## It returns a boolean True whether checks are OK. False otherwise.
   def check     
      retVal       = true      
      
      arrInTrayDirs = Array.new
      
      
      arrDims      = @decReadConf.getIntrayNames
 
      arrDims.each{|dim|
                    
         inTray   = @decReadConf.getInTrayDir(dim)
         compress = @decReadConf.getInTrayCompress(dim)

         if compress == nil then
            puts "No compression is applied at #{dim} intray"
         else
            puts "Compression #{compress} applied at #{dim} intray"
         end

         if @isDebugMode == true then
            puts "Verifying #{dim} configuration ..."
            puts "InTray:    #{inTray}"
            puts "Compress:  #{compress}"
         end
  
         if inTray == false then
            retVal = false
            puts "#{dim} is not declared in the ListIntrays"
         else
            checkDirectory(inTray)
         end
         
      }     
      
      arrTypes = @decReadConf.getAllFileTypes
     
      arrTypes.each{|type|
         
         arrInTrays  = Array.new
         hdlinked    = @decReadConf.isHardLinked?(type)
         arrDest     = @decReadConf.getInTrays4Filetype(type)
 
         if @isDebugMode == true then
            puts "================================================"
            puts "Verifying #{type} configuration vs DIMs ..."
            arrDest.each{|dim|
              puts "#{type} - #{dim}"
            }
         end
         
         if arrDest == false then
            puts "No target DIMs for #{type} filetype in dec_incoming_files.xml" 
            retVal = false          
         end
         
         arrDest.each{|dim|
            intray = @decReadConf.getInTrayDir(dim)
            if intray == false then
               retVal = false
               puts "#{type} - #{dim} is not declared in the ListIntrays"
            end
            
            arrInTrays << intray
            
         }
         
         
         if hdlinked == true then
            puts
            puts "Verification of hardlink configuration for #{type}:"
            filesystemID_prev = Filesystem.stat(arrInTrays[0]).filesystem_id
            inTray_prev       = arrInTrays[0]
            arrInTrays.each{|intray|
               puts "#{intray} => #{Filesystem.stat(intray).filesystem_id}"
               if filesystemID_prev != Filesystem.stat(intray).filesystem_id then
                  puts "ERROR #{intray} and #{inTray_prev} are not in the same filesystem"
                  retVal = false
               end
               filesystemID_prev = Filesystem.stat(intray).filesystem_id
               inTray_prev       = intray
            }
         end
         
         
         arrDirs = @decReadConf.getTargetDirs4Filetype(type)
         
#         puts "----------------------------------------"
#         puts "getTargetDirs4Filetype(#{type})"
#         puts arrDirs
#         puts "----------------------------------------"
#        

         


 
      }

      # Perform integrity dec_incoming_files.xml
      arrIncomingTypes = @dccIncoming.getAllIncomingFiles
      arrIncomingTypes.each{|fileType|
         if @decReadConf.existFileType?(fileType) == false then
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
#          puts "Error in dec_incoming_files.xml configuration"
#          puts "Please check your configuration file"
#          puts
#       end
      return retVal
   end
   ## -----------------------------------------------------------

   ## Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "CheckerInTrayConfig debug mode is on"
   end
   ## -----------------------------------------------------------

private

   @isDebugMode       = false      

   ## -----------------------------------------------------------

   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   ## -----------------------------------------------------------

end # class

end # module
