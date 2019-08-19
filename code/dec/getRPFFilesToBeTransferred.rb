#!/usr/bin/env ruby


# == Synopsis
#
# This is a RPF command line tool that retrieves files to be transferred.
# 
#
# == Usage
# getRPFFilesToBeTransferred.rb -R <nROP> | -E -i "FILE_ID_1 .. FILE_ID_n"
#   --list      list only
#   --help      shows this help
#   --usage     shows the usage
#   --Debug     shows Debug info during the execution
#   --version   shows version number
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2006 ESA - Deimos Space S.L.
#

#########################################################################
#
# === Ruby script getFilesToBeTransferred for sending all files to an Entity
# 
# === Written by DEIMOS Space S.L.   (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# CVS: $Id: getRPFFilesToBeTransferred.rb,v 1.15 2007/12/03 14:43:05 decdev Exp $
#
#########################################################################

require 'ftools'
require 'fileutils'
require 'getoptlong'

require 'cuc/EE_ReadFileName'
require 'cuc/Logger.rb'
require 'cuc/DirUtils'
require 'cuc/FT_PackageUtils'
require 'cuc/CheckerProcessUniqueness'
require 'ctc/CheckerOutgoingFileConfig'
require 'ddc/RetrieverFromArchive'
require 'dec/ReadInterfaceConfig'
require 'dec/DEC_DatabaseModel'
require 'dec/DEC_Environment'



@isDebugMode      = false                  
@entity           = ""

# MAIN script function
def main

   include           FileUtils::NoWrite
   include           DDC
   include           CUC::DirUtils
   include           DEC

   @isDebugMode        = false
   @isVerboseMode      = false
   @bJustList          = false
   @nROP               = 0
   # Flag for updating the database for Transfer purposes.
   # This flag is disabled in Transfers in Emergency mode.
   @bROPChecks         = true
   @bUsage             = false
   @bShowVersion       = false

   
   opts = GetoptLong.new(
     ["--ROP", "-R",            GetoptLong::REQUIRED_ARGUMENT],
     ["--ids", "-i",            GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--list", "-l",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--Verbose", "-V",        GetoptLong::NO_ARGUMENT],
     ["--Emergency", "-E",      GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt      
            when "--Debug"       then @isDebugMode          = true
            when "--version"     then @bShowVersion         = true
            when "--list"        then @bJustList            = true
            when "--help"        then @bUsage               = true
            when "--usage"       then @bUsage               = true
            when "--ROP"         then @nROP                 = arg.to_s
            when "--Emergency"   then @bROPChecks           = false
            when "--Verbose"     then @isVerboseMode        = true
	         when "--ids" then @listIDs = arg         
         end
      end
   rescue Exception
      exit(99)
   end
    
   if @bShowVersion == true then
      print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " Version: [#{DEC.class_variable_get(:@@version)}]", "\n\n")
      hRecord = DEC.class_variable_get(:@@change_record)
      hRecord.each_pair{|key, value|
         puts "#{key} => #{value}"
      }      
      exit(0)
   end
   
   if @bUsage then
      usage
      exit(0)
   end

   if @nROP == 0 and @bROPChecks == true then
      usage
      exit(99)
   end


   if self.checkEnvironmentEssential == false then
      puts
      self.printEnvironmentError
      puts
      exit(99)
   end


   checkModuleIntegrity

   @configFileManager  = ReadInterfaceConfig.instance
   @fileDestination    = CTC::ReadFileDestination.instance 


   # AUTOMATION - FileTransfer:
   # It is now allowed to have send2Interface.rb processes running when running this tool.

#    # It checks there is not a send2Interface process running
#    retVal = checkProcessIntegrity
#    if retVal == false then
#       exit(99)
#    end 

   # if list of files to be sent are specified by their FILE_IDs
   if @bROPChecks == false then
      deliverListOfFiles(@listIDs)
      exit(0)
   end

   #-----------------------------------------------
   # Perform file Retrieval for a given ROP Number

   # Check ROP Transferability
   aROP = InventoryROP.where(ROP_ID: @nROP)
   
   if aROP == nil or aROP.empty? == true then
      puts "\nError: ROP #{@nROP} does not exist ! :-(\n"
      exit(99) 
   end

   if aROP[0].TRANSFERABILITY.to_i == InventoryROP::NOT_TRANSFERABLE then
      puts "\nWarning: ROP #{@nROP} is not Transferable\n" 
   end
   
   arrInv = InventoryROPFileView.find_by_sql(["select FILENAME, FILE_ID, TYPE_ID from ROP_FILE_VW
                                                 where CURRENT_ROP=? and TYPE_ID<? and STATUS=?",@nROP, 1000, InventoryFile::STATUS_VALIDATED ])
   if arrInv == nil or arrInv.length == 0 then
      puts "There are no Files to be transferred for ROP #{@nROP}\n"
   end


   arrInv.each{|row|
      file     = row.FILENAME
      fileId   = row.FILE_ID.to_i
      # Extract its File_Type
      if (@currentFileType = CUC::EE_ReadFileName.new(file).fileType) == false then
         puts "File #{file} has not a recognized FileType !"
         next
      end

      # Check file with FileType @currentFileType Destinations
      arrDest = @fileDestination.getEntitiesReceivingOutgoingFile(@currentFileType)
      if arrDest != nil then
         puts "-----------------------------------------------------------------"
         puts %Q{#{file} #{fileId}}
         puts
         arrDest.each{|x|
            setToBeSent(file, fileId, x)
         }
      else
         if @isVerboseMode == true then
            puts "-----------------------------------------------------------------"
            puts "#{file} is not sent to any I/F"
         end
         # 1 - Copy File from Archive to FT outbox ($FTPROOT/outbox/_processed_/ROPXXX)
         # 2 - Move it to discarded dir ($FTPROOT/outbox/_discarded_/ROPXXX)
         #     as it has not been set up for any I/F
         if @bJustList == false then
            getFileFromRPFArchive2MainOutbox(file)
            srcFile     = %Q{#{@srcDirectory}/#{file}}
            targetFile  = %Q{#{@discardedDir}/#{file}}
            File.mv(srcFile, targetFile)
         end
      end
   }

end
#---------------------------------------------------------------------


# Get Files to be sent in Emergency mode.
# The files are obtained from a FILE_IDs list given in the command line
def deliverListOfFiles(listIDs)
   files      = Array.new   
   arrFileIDs = listIDs.split    
   arrNames   = getNamesFromIDs(arrFileIDs) 
   struct     = Struct.new("FileToSend", :filename, :fileid)
   size       = arrNames.length - 1
   
   0.upto(size) do |i|
      files << struct.new(arrNames[i], arrFileIDs[i])
   end
   
#    if @isDebugMode == true then
#       puts files
#    end
   
   files.each{|x|
      file   = x[:filename].to_s
      fileId = x[:fileid].to_s
      
      # Extract its File_Type
      if (@currentFileType = CUC::EE_ReadFileName.new(file).fileType) == false then
         puts "File #{file} has not a recognized FileType !"
         next
      end
      
      # Check file with FileType @currentFileType Destinations
      arrDest = @fileDestination.getEntitiesReceivingOutgoingFile(@currentFileType)

      if arrDest != nil then
         puts "-----------------------------------------------------------------"
         puts %Q{#{file} #{fileId}}
         puts
         arrDest.each{|x|
	    # Set to be sent for a given Interface
            setToBeSent(file, fileId, x)
         }
      else
         if @isVerboseMode == true then
            puts "-----------------------------------------------------------------"
            puts "#{file} is not sent to any I/F"
         end
         # 1 - Copy File from Archive to FT outbox ($FTPROOT/outbox/_processed_/ROPXXX)
         # 2 - Move it to discarded dir ($FTPROOT/outbox/_discarded_/ROPXXX)
         #     as it has not been set up for any I/F
         if @bJustList == false then
            getFileFromRPFArchive2MainOutbox(file)
            srcFile     = %Q{#{@srcDirectory}/#{file}}
            targetFile  = %Q{#{@discardedDir}/#{file}}
            FileUtils.mv(srcFile, targetFile)
	    if @isDebugMode == true then
	    	puts "File moved to #{@discardedDir}"
	    end
         end
      end     
            
   }
   
end
#---------------------------------------------------------------------

#---------------------------------------------------------------------

# It checks that there are no "dangerous" processes runnning.
# It checks there are no send2Interface processes running
# * It returns true if the intergrity is OK and can go on
# * It returns false if the integrity is NOT OK and should stop 
def checkProcessIntegrity
   bIsNotBlocked = true
   arrDest = @configFileManager.getAllExternalMnemonics
   arrDest.each{|x|
      checker = CUC::CheckerProcessUniqueness.new("send2Interface.rb", x, true)
      ret     = checker.isRunning
      if ret == true then
         puts "send2Interface for #{x} I/F is running !"
	      bIsNotBlocked = false
      end
   }
   return bIsNotBlocked
end
#-------------------------------------------------------------

# From an array of FILE_IDs recover all their FILENAME and
# return them in a different array
def getNamesFromIDs(arrIDs)   
   arrFilename = Array.new
   aRpfFile    = InventoryFile.new   
   arrIDs.each{|x|
      aFilename = InventoryFile.where(FILE_ID: x)
      if aFilename != nil and aFilename.empty? == false then 
         arrFilename << aFilename[0].FILENAME
      else
         puts
         puts "No File has FILE_ID equal to #{x} ! :-("
      end
   }
   return arrFilename
end
#-------------------------------------------------------------

#-------------------------------------------------------------

# Check that everything needed by the class is present.
def checkModuleIntegrity
   bDefined = true
   bCheckOK = true
      
   if !ENV['FTPROOT'] then
      puts("\nFTPROOT environment variable not defined !  :-(\n\n")
      bCheckOK = false
      bDefined = false
   end

   if !ENV['RPF_ARCHIVE_ROOT'] then
      puts "\nRPF_ARCHIVE_ROOT environment variable not defined !\n"
      bDefined = false
   end      

# removeSchema.bin shall be invoked from RPFBIN   
#
#   isToolPresent = `which removeSchema.bin`
#    
#   if isToolPresent[0,1] != '/' then
#      puts "\nremoveSchema.bin tool is required !\n"
#      bCheckOK = false
#      bDefined = false      
#   end
#

   if bCheckOK == false or bDefined == false then
      puts("#{File.basename($0)}::checkModuleIntegrity FAILED !\n\n")
      exit(99)
   end
   @rootDirectory  = ENV['FTPROOT']
   @rpfArchiveRoot = ENV['RPF_ARCHIVE_ROOT']
   
   # Directories initialisation   
   @srcDirectory = expandPathValue("$FTPROOT/outbox/_processed_")
   @discardedDir = expandPathValue("$FTPROOT/outbox/_discarded_")
   if @nROP != 0 then
      @srcDirectory = %Q{#{@srcDirectory}/ROP#{@nROP}}
      @discardedDir = %Q{#{@discardedDir}/ROP#{@nROP}}
   else
      time = Time.now
      now  = time.strftime("%Y-%m-%d_%H:%M:%S")
      @srcDirectory = %Q{#{@srcDirectory}/Emergency_#{now}}
      @discardedDir = %Q{#{@discardedDir}/Emergency_#{now}}
   end
   if @bJustList == false then
      checkDirectory(@srcDirectory)
      checkDirectory(@discardedDir)
      if FileTest.exist?(@srcDirectory) == false then
         if @isDebugMode == true then
            print "\nError #{File.basename($0)}::checkModuleIntegrity, ", @srcDirectory, " does not exist !  :-(\n\n"
         end
      end
   end      
end
#---------------------------------------------------------------------

# It sets up a given file to be sent to a given I/F entity.
# - file (IN): File name
# - mnemonic (IN): Interface entity id
# Copy the file from @srcDirectory to Entity's ToBeSent directory
# After the copy, the files are set in the DDBB to status NOT_TRANSFERRED
# if there is not a previous entry in the database.
def setToBeSent(file, fileId, mnemonic)
   ropId = nil
   if fileId == -1 then        
      puts("\nInternal Error #{File.basename($0)}::setToBeSent #{file} ! ?:-( \n\n")
      exit(99)
   end
   
   anInterface = Interface.find_by_name(mnemonic)

   # Check whether the Destination I/F is already declared in the database  
   if anInterface == nil then
      puts "\n\nDestination I/F #{mnemonic} is not declared in Inventory !"
      puts
      puts "Use addInterfaces2Database.rb utility to register it."
      puts "\nError in #{File.basename($0)}::setToBeSent !  :-(\n\n"
      exit(99)   
   end
   destId = anInterface.id.to_i
   
   # If ROP Checks => It is not an Emergency Transfer, so ROP is updated accordingly.

   # 26-02-2007 Dirty Patch
   # Now that it is allowed to specify both "Emergency" and a ROP Number we have to check both
   if @bROPChecks == true or @nROP != 0 then
      bSent     = false
      aFile     = File.basename(file, ".*")
      aFileSent = SentFile.find_by_sql(["select * from SENT_FILES where INTERFACE_ID=? and FILENAME like ? ", destId, %Q{#{aFile}%}])

      # Avoid file extension to identify whether a files has been sent or not due 
      # to possible later file packaging
      # aFileSent = SentFile.find_by_filename_and_interface_id(file, destId)

      if aFileSent == nil or aFileSent.length == 0 then
         print(file, " has not been sent to #{mnemonic} I/F") # in ROP #{ropId}")
         puts      
      else
         bSent = true
         print(file, " has already been sent to #{mnemonic} I/F")
         puts
      end
      
      if bSent == true then
         return
      end
   else
      print(file, " is sent in Emergency Mode to #{mnemonic} I/F")
      puts
   end         
   
   # 1 - Copy File from Archive to FT outbox ($FTPROOT/outbox/_processed_/ROPXXX)
   # 2 - Place the File from the FT main outbox into outbox dir of the Entity (I/F)
   #     and apply Compression
   if @bJustList == false then
      fileType    = CUC::EE_ReadFileName.new(file).fileType
      srcFile     = %Q{#{@srcDirectory}/#{file}}
      targetDir   = @configFileManager.getOutgoingDir(mnemonic)
      arrMethods  = @fileDestination.getDeliveryMethods(mnemonic, fileType)
   
      # Get File from RPF Archive and place it into main FT outbox processing
      getFileFromRPFArchive2MainOutbox(file)
         
      # ----------------------------------------
      # For each Delivery Method to such I/F    
      arrMethods.each{|aMethod|
         aDir = %Q{#{targetDir}/#{aMethod.downcase}}
         checkDirectory(aDir)

         if @isDebugMode == true then
            print(file, " is sent via #{aMethod}")
            puts
         end

	 # Target File placed in the delivery Method outbox
         targetFile  = %Q{#{aDir}/#{file}}         
	 FileUtils.cp(srcFile, targetFile)
	 
	 # Apply compress method if configured
	 if  @fileDestination.isCompressed?(mnemonic, fileType) == true then
	    compMethod = @fileDestination.getCompressMethod(mnemonic, fileType)
	    packFile(file, aDir, compMethod)
	 end
      }
   end
end
#---------------------------------------------------------------------

# Copy a file to be sent from the RPF Archive 
# to the RPF FT main outbox directory.
# 1 - It takes the file from $RPF_ARCHIVE_ROOT/Files/<FileType>/
# 2 - It places them in $FTPROOT/outbox/ROPXXX
# 3 - It removes Schemas location

def getFileFromRPFArchive2MainOutbox(file)
   sourceDir  = %Q{#{@rpfArchiveRoot}/Files}      
   targetDir  = @srcDirectory      
   # Extract File Type from Filename
   # Once the file is the FT src Dir, this field
   # shall be extracted from its XML Header, so if there
   # is any inconsistency, it shall be detected there.
   fileType    = CUC::EE_ReadFileName.new(file).fileType

   sourceDir   = %Q{#{sourceDir}/#{fileType}}
   sourceFile  = %Q{#{sourceDir}/#{file}}
   targetFile  = %Q{#{targetDir}/#{file}}
   
   puts
   puts sourceFile
   puts targetFile
   puts
      
   FileUtils.cp(sourceFile, targetFile)
      
   #------------------------------------   
   # Remove Schema Location
   nameReader = CUC::EE_ReadFileName.new(targetFile)
   if nameReader.fileContent.upcase == ".EEF" or
      nameReader.fileContent.upcase == ".HDR" or
      nameReader.fileContent.upcase == ".XML" then
      command = %Q{#{ENV['RPFBIN']}/removeSchema.bin -f #{targetFile}}
      ret = system(command)
      if ret == false then
         puts
         puts "Error executing #{command}"
         puts         
      end
   end
   return
end

#-------------------------------------------------------------

#-------------------------------------------------------------

def packFile(file, srcPath, method, bUnPack = false)
   
   bRet = false
   if @isDebugMode == true then
      puts "#{file} is Packaged with #{method} method"
   end
   package        = FT_PackageUtils.new(file, srcPath, true)
#    if @isDebugMode == true then
#       package.setDebugMode
#    end
   bMethod = package.setCompressMethod(method)
   if bMethod == false then
      puts "\nFATAL Error in getRPFFilesToBeTransferred::packFile"
      puts "\nError in Compression Method for #{file} !! =:-O\n"
      puts
      exit(99)
   end
      
   # BOLF - 2007-04-10 We do not perform unpack directly anymore
   # Currently there is a Package method called "unpack" that performs
   # that operation when required.

   if bUnPack == false then
      bRet = package.pack
      arr  = Array.new
      arr << bRet
      bRet = arr
   else      
      bRet = package.unpack
   end
   if bRet == false then
      puts "\nError in getRPFFilesToBeTransferred::packFile"
      puts "\nFailed to Pack #{file} !! =:-O\n"
      exit(99)      
   end 
   return bRet
end 
#-------------------------------------------------------------

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = File.expand_path(__FILE__)   
   
   value = `#{"head -22 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
end
#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
