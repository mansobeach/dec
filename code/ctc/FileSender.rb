#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileSender class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: FileSender.rb,v 1.4 2008/07/03 13:12:05 decdev Exp $
#
#########################################################################

require 'net/ssh'
require 'net/sftp'
require 'fileutils'

require "ctc/FTPClientCommands"
require "ctc/SFTPBatchClient"
require "cuc/DirUtils"


module CTC

 # Module Common Transfer Component
 # This class performs the file(s) delivery.
 #
 # This class provides methods for sending files to entities using FTP.
 # It implements both, secure and non secure file transfers.
 #

class FileSender

   # Mixins includes
   include CTC::FTPClientCommands
   include CTC   
   include CUC::DirUtils

   attr_reader :fileList
   
   # Class constructor
   # - FTPServer Struct  (IN): DDC_ReadEntityConfig::fillFTPServerStruct
   # - hParameters       (IN): Hash type containing Additional Parameters   
   def initialize(ftpServerStruct, hParameters=nil)
      @ftpConfigStruct  = ftpServerStruct
      @hParameters      = hParameters
      checkModuleIntegrity
      @ftBatchFilename  = %Q{.BatchSenderFile4#{ftpServerStruct[:mnemonic]}}
      @isDebugMode      = false
      @fileListLoaded   = false
      @entity           = ftpServerStruct[:mnemonic]
      @secureMode       = ftpServerStruct[:isSecure]
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "FileSender debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Set the files to be sent.
   # - arrFiles (IN): Array of files to be sent
   # - dirname  (IN): Outbox directory path.
   def setFileList(arrFiles, outboxPath)
      checkDirectory(outboxPath)
      pwd = Dir.pwd
      Dir.chdir(outboxPath)      
      arrFiles.each{|file|
         if File.exist?(file) == false then
            print file, " does not exist in ", outboxPath, " ! :-( \n"
            puts "Error in FileSender::setFileList !"
            exit(99)
         end
      }
      Dir.chdir(pwd)
      @fileList         = arrFiles.uniq
      @srcDirectory     = outboxPath
      @fileListLoaded   = true
   end
   #-------------------------------------------------------------
   
   # THIS METHOD SHALL BE DEPRECATED !!!!!!! 
   #
   # It Sends all files placed in the outbox directory @srcDirectory.
   #
   # It executes the #sendFile method for each file.
   #
   # Each time a file is sent, it is invoked explicit the Ruby
   # Thread Scheduler through the Thread method pass.
   # If the file is not sent due to different problems an Exception
   # is raised.
   def sendAllFiles(bDeleteSource=true)
           
      isReadyToSend
      
      cleanUpRemoteTemp
      
      numFiles = @fileList.length
            
      # number of files dispatched
      cont      = 0
      @iCounter = 0
      
      bAllSent = true
      @fileList.each{|file|
         bSent = sendFile(file)
         if bSent == true then
            cont= cont + 1
            if bDeleteSource == true
               File.delete(%Q{#{@srcDirectory}/#{file}})
            end
            msg = "Sent #{cont} file(s) of #{numFiles} to #{@entity}"
            puts msg
         else
            msg = "Could not send #{file} to #{@entity}"
            puts msg
            bAllSent = false
         end
         Thread.pass
      }
      if bAllSent == false then
         raise
      end
   end
   #-------------------------------------------------------------

   # Send File now just sends the file
   def sendFile(file, bDeleteSource=true)
     
      isReadyToSend(file)
      command = ""
      prevDir = Dir.pwd
      Dir.chdir(@srcDirectory)
      
      # If there is a previous file of a failed execution we delete it.
      if @secureMode == true and (FileTest.exist?(@ftBatchFilename) == true) then 
         File.delete(@ftBatchFilename)
      end      
   
         
      if @secureMode == false then
            filename = %Q{#{@srcDirectory}/#{file}}
            command  = self.createNcFtpPut(@ftpConfigStruct[:hostname],
                                          @ftpConfigStruct[:port],
                                          @ftpConfigStruct[:user],
                                          @ftpConfigStruct[:password],
                                          @ftpConfigStruct[:uploadDir],
                                          filename,
                                          @isDebugMode)  
      else
            uploadDir   = @ftpConfigStruct[:uploadDir]
            uploadTemp  = @ftpConfigStruct[:uploadTemp]
            sourceFile  = %Q{#{@srcDirectory}/#{file}}
            targetTemp  = %Q{#{uploadTemp}/#{file}}
            targetFile  = %Q{#{uploadDir}/#{file}}
                    
            sftpClient  = SFTPBatchClient.new(@ftpConfigStruct[:hostname],
                                             @ftpConfigStruct[:port],
                                             @ftpConfigStruct[:user],
                                             @ftBatchFilename,
                                             @ftpConfigStruct[:isCompressed])
            if @isDebugMode == true then
               sftpClient.setDebugMode
            end

	         # It deletes an existing file in the upload dir
	         # with the same filename as the one about to be transferred
	         deleteRemoteFile(file)
	    
	         sftpClient.addCommand("put",
                                  sourceFile,
                                  targetTemp)

            sftpClient.addCommand("rename",
                                  targetTemp,
                                  targetFile)

      end
                   
      if @secureMode == false then
         if @isDebugMode == true then
            puts command
         end
         output = `#{command}`
         if $? != 0 then
            retVal = false
         else
            retVal = true
         end
      else
         retVal = sftpClient.executeAll
         output = sftpClient.output
      end
                  
      # After the execution we delete the batchfile
      if @secureMode == true and (FileTest.exist?(@ftBatchFilename) == true) then
         n = File.delete(@ftBatchFilename)
      end
      
      Dir.chdir(prevDir)
      
      if retVal == true and bDeleteSource == true then
         File.delete(%Q{#{@srcDirectory}/#{file}})
      end

      return retVal
   end


   #-------------------------------------------------------------

   # It sends the directory and all its content
   def sendDir(dir, bDeleteSource = true)
      if @secureMode == false then
         return sendNonSecureDir(dir, bDeleteSource)
      else
         puts
         puts "FileSender::sendSecureDir is not implemented ! :-p"
         puts
         exit(99)
      end
   end
   #-------------------------------------------------------------

   def sendNonSecureDir(dir, bDeleteSource = true)

      @ftp           = nil
      host           = @ftpConfigStruct[:hostname]      
      port           = @ftpConfigStruct[:port].to_i
      user           = @ftpConfigStruct[:user]
      pass           = @ftpConfigStruct[:password]

      begin
         @ftp = Net::FTP.new(host)
         @ftp.login(user, pass)
         @ftp.passive = true
      rescue Exception => e
         puts
         puts e.to_s
         puts "Unable to connect to #{host}"
         #@logger.log("#{@entity}: #{e.to_s}", LOG_ERROR)
         #@logger.log("#{@entity}: Unable to connect to #{host}", LOG_ERROR)
         #@logger.log("Could not send #{dir} to #{@entity} I/F", LOG_ERROR)
         puts
         return false
      end

      prevDir = Dir.pwd
      
      begin
         @ftp.chdir(@ftpConfigStruct[:uploadDir])
         @ftp.mkdir("__#{dir}")
      rescue Exception => e
         puts "Could not create __#{dir}"
         # Remove remote directory and its content
         # We rule !!!
         @ftp.chdir("__#{dir}")
         arrFiles = @ftp.nlst
         arrFiles.each{|aRemoteFile|
            @ftp.delete(aRemoteFile)
         }
         @ftp.chdir("..")
         @ftp.rmdir("__#{dir}")
      end

      begin
         @ftp.chdir("__#{dir}")
         Dir.chdir(dir)
         arrFiles = Dir["*"]

         arrFiles.each{|aFile|
            # puts "sending file #{aFile}" 
            @ftp.putbinaryfile(aFile)
         }
         @ftp.chdir("..")
      rescue Exception => e
         puts
         puts "Could not send temp __#{dir}"
         puts
         Dir.chdir(prevDir)
         return false
      end

      begin      
         @ftp.rename("__#{dir}", dir)
         Dir.chdir(prevDir)
         return true      
      rescue Exception => e
         @ftp.chdir(dir)
         arrFiles = @ftp.nlst
         arrFiles.each{|aRemoteFile|
            @ftp.delete(aRemoteFile)
         }
         @ftp.chdir("..")
      end

      begin      
         @ftp.rename("__#{dir}", dir)
      rescue Exception => e
         puts
         puts "Could not send #{dir}"
         puts
         Dir.chdir(prevDir)
         return false      
      end

      Dir.chdir(prevDir)

      if bDeleteSource == true then
         FileUtils.rm_rf(dir)
      end

      return true

   end
   #-------------------------------------------------------------

   # It deletes from the Upload dir if exist a filename with the
   # same filename as the one about to be transfer in the loop.
   #
   # Nominally and in OPERATIONS that situation should never happen.
   #
   # Unfortunately during GSOV tests, some I/Fs did not retrieve their
   # files, and the repetition of tests caused the FT to fail.
   #
   def deleteRemoteFile(file)
      uploadDir   = @ftpConfigStruct[:uploadDir]
      targetFile  = %Q{#{uploadDir}/#{file}}
       
      sftpClient  = SFTPBatchClient.new(@ftpConfigStruct[:hostname],
                                            @ftpConfigStruct[:port],
                                            @ftpConfigStruct[:user],
                                            @ftBatchFilename,
                                            @ftpConfigStruct[:isCompressed])
#       sftpClient.setDebugMode
      sftpClient.addCommand("rm", targetFile, nil)
       
      retVal = sftpClient.executeAll
      output = sftpClient.output 
   end   
   #-------------------------------------------------------------
      
private

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true
      
      #check the commands needed
      isToolPresent = `which ncftp`   
      if isToolPresent[0,1] != '/' then
         puts "\n\nDDC_FileSender::checkModuleIntegrity\n"
         puts "Fatal Error: ncftp not present in PATH !!   :-(\n\n\n"
         bCheckOK = false
      end

      isToolPresent = `which ncftpput`
      if isToolPresent[0,1] != '/' then
         puts "\n\nDDC_FileSender::checkModuleIntegrity\n"
         puts "Fatal Error: ncftpput not present in PATH !!   :-(\n\n\n"
         bCheckOK = false
      end      
 
      isToolPresent = `which sftp`   
      if isToolPresent[0,1] != '/' then
         puts "\n\nDDC_FileSender::checkModuleIntegrity\n"
         puts "Fatal Error: sftp not present in PATH !!   :-(\n\n\n"
         bCheckOK = false
      end
                   
      if bCheckOK == false then
         puts "\nDDC_FileSender::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end      
   end
   
   #-------------------------------------------------------------
   # Check if everything is ready to perform the transfer.
   # The following data needs to be loaded in the object:
   # * List of files to be sent
   def isReadyToSend(file = "")
      if @fileListLoaded == false then
         puts "\nError in FileSender::isReadyToSend"
         print "\nClass is not configured yet !   :-( \n\n"
         exit(99)       
      end
      if file != "" then
         if File.exist?("#{@srcDirectory}/#{file}") == false then
            puts "File {file} is not present in the outbox ! :-("
            puts "Fatal Error in FileSender::isReadyToSend(#{file})"
            exit(99)
         end
      end
   end
   #-------------------------------------------------------------

   # It deletes all UploadTemp content
   def cleanUpRemoteTemp
      if @secureMode == false then
         puts "Warning: UploadTemp cleanup not implemented for non-secure mode !"
	      exit(99)
      end
      uploadTemp  = @ftpConfigStruct[:uploadTemp]
       
      sftpClient  = CTC::SFTPBatchClient.new(@ftpConfigStruct[:hostname],
                                           @ftpConfigStruct[:port],
                                           @ftpConfigStruct[:user],
                                           @ftBatchFilename,
                                           @ftpConfigStruct[:isCompressed])
    
      sftpClient.addCommand("cd", uploadTemp, nil)
      sftpClient.addCommand("rm","*", nil)
       
      retVal = sftpClient.executeAll
      output = sftpClient.output
   end
   #-------------------------------------------------------------
   
end # class

end # module
