#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileDeleter class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: FileDeleter.rb,v 1.8 2008/11/26 12:40:47 decdev Exp $
#
# module MINARC
#
#########################################################################

require "cuc/DirUtils"
require "cuc/EE_ReadFileName"
require "arc/MINARC_DatabaseModel"
require "arc/ReportEditor"

module ARC

class FileDeleter

   include CUC::DirUtils
   #-------------------------------------------------------------   
   
   # Class contructor
   def initialize(bListOnly = false)
      @bListOnly     = bListOnly
      checkModuleIntegrity
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      puts "FileDeleter debug mode is on"
   end
   #-------------------------------------------------------------

   def disableListMode
      @bListOnly = false
   end
   #-------------------------------------------------------------

   def enableListMode
      @bListOnly = true
   end
   #-------------------------------------------------------------

   def enableReporting(filePath)
      @bReport = true
      @reportFullName = filePath
   end
   #-------------------------------------------------------------

   # Main method of the class.
   def delete_by_type(fileType, start = nil, stop = nil, bIncStart=false, bIncStop=false)

      arrFiles = ArchivedFile.searchAllWithinInterval(fileType.upcase, start, stop, bIncStart, bIncStop)

      if @bReport then
         editor = ARC::ReportEditor.new(arrFiles)
         editor.generateReport(@reportFullName)
      end

      retVal = true

      if arrFiles != nil then
         arrFiles.each{|aFile|
            if @bListOnly then
               puts aFile.filename
               aRetVal = true
            else
               aRetVal = deleteFromArchive(aFile)  
            end

            if retVal then
               retVal = aRetVal
            end
         }
      end

      return retVal

   end
   #-------------------------------------------------------------

   def delete_by_name(filename)

      aFile = ArchivedFile.find_by_filename(filename)

      if !aFile then
         puts
         puts "#{filename} not present in the archive :-|"
         puts
         return false
      end

      if @bReport then
         editor = ARC::ReportEditor.new(Array[aFile])
         editor.generateReport(@reportFullName)
      end

      if @bListOnly then
         puts aFile.filename
         return true
      else
         retVal = deleteFromArchive(aFile)  
         return retVal
      end

   end
   #-------------------------------------------------------------

private


   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      
      if !ENV['MINARC_ARCHIVE_ROOT'] then
         puts
         puts "MINARC_ARCHIVE_ROOT environment variable is not defined !\n"
         bDefined = false
      end

      if bCheckOK == false or bDefined == false then
         puts("FileDeleter::checkModuleIntegrity FAILED !\n\n")
         exit(99)
      end

      @archiveRoot = ENV['MINARC_ARCHIVE_ROOT']
      return
   end
   #-------------------------------------------------------------

   def deleteFromArchive(aFile)

      # cmd = "\\chmod -R a+w #{@archiveRoot}/#{aFile.path}/" << "/#{aFile.filename}"
      cmd = "\\chmod -R a+w #{aFile.path}/" << "/#{aFile.filename}"

      system(cmd)

      # cmd = "\\rm -rf #{@archiveRoot}/#{aFile.path}/" << "/#{aFile.filename}"
      cmd = "\\rm -rf #{aFile.path}/" << "/#{aFile.filename}"

      retVal = system(cmd)

      if retVal == true then
         aFile.destroy
         puts "(Deleted)  : " << aFile.filename
         return true
      else
         puts "Could not delete #{aFile.filename} from archive :-("
         return false
      end

   end
   #-------------------------------------------------------------

end # class

end # module
#=====================================================================


#-----------------------------------------------------------


