#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileSender class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: FileSender.rb,v 1.18 2014/05/20 14:41:04 algs Exp $
#
#########################################################################

require 'net/ssh'
require 'net/sftp'
require 'ftpfxp'
require 'fileutils'

require "ctc/FTPClientCommands"
require "ctc/SFTPBatchClient"
require "ctc/LocalInterfaceHandler"
require "cuc/DirUtils"
require "cuc/CommandLauncher"

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
   include CUC::CommandLauncher

   attr_reader :fileList
   
   # Class constructor
   # - FTPServer Struct  (IN): DDC_ReadEntityConfig::fillFTPServerStruct
   # - hParameters       (IN): Hash type containing Additional Parameters   
   def initialize(ftpServerStruct, protocol, hParameters=nil)
      @ftpServer        = ftpServerStruct
      @protocol         = protocol
      @hParameters      = hParameters
      checkModuleIntegrity
      @ftBatchFilename  = %Q{.BatchSenderFile4#{ftpServerStruct[:mnemonic]}}
      @isDebugMode      = false
      @fileListLoaded   = false
      @entity           = ftpServerStruct[:mnemonic]
      @secureMode       = ftpServerStruct[:isSecure]
      @passiveMode      = ftpServerStruct[:isPassive]
      @dynamic          = false
      @mirroring        = false
      @prefix           = ''
      if protocol == 'LOCAL' then
         #false stands for use DCC; true stands for use DDC
         @local = CTC::LocalInterfaceHandler.new(@entity, false, true, DDC::ReadConfigDDC.instance.getUploadDirs)
      end
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "FileSender debug mode is on"
   end
   #-------------------------------------------------------------

   # Set the flag for debugging on
   def setUploadPrefix(prefix)
      @prefix = prefix
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
   
   def useMirrorServer(file, bIsNotDir=true)
      
      @mirroring  =  true
      @protocol   =  @ftpServer[:FTPServerMirror][:protocol]
      @hostname   =  @ftpServer[:FTPServerMirror][:hostname]
      @port       =  @ftpServer[:FTPServerMirror][:port].to_i
      @user       =  @ftpServer[:FTPServerMirror][:user]
      @password   =  @ftpServer[:FTPServerMirror][:password]

      if bIsNotDir then
         retVal=sendFile(file)
      else
         retVal=sendDir(file)
      end
      @mirroring =false 
      return retVal    
   end          
   #-------------------------------------------------------------

   def dynamicDirectory (directory, file)
      while directory.include?('[') do
         @dynamic=true
         cmd= directory.slice(directory.index('[')+1..directory.index(']')-1)
         order= cmd.slice(0, cmd.index('('))
         case order
            when "cut" then #cut(#,1)
               separator= cmd.slice(cmd.index('(')+1..cmd.index(',')-1)
               field= cmd.slice(cmd.index(',')+1..cmd.index(')')-1).to_i
               if file.include?(separator) then
                  fileSplitArray = file.split(separator)
                  directory= directory.sub(/\[.{0,10}\]/,fileSplitArray[field])
               else
                  directory= directory.sub(/\[.{0,10}\]/,"")                  
               end
            when "sub" then #sub (4,5)
               from=cmd.slice(cmd.index('(')+1..cmd.index(',')-1).to_i
               to=cmd.slice(cmd.index(',')+1..cmd.index(')')-1).to_i
               directory= directory.sub(/\[.{0,10}\]/,file.slice(from,to))
         end
      end
      return directory
   end
   ## -----------------------------------------------------------

   def getUploadTargets(file)

      @uploadDir   = @ftpServer[:uploadDir]
      @uploadTemp  = @ftpServer[:uploadTemp]
      @sourceFile  = %Q{"#{@srcDirectory}/#{file}"}

      @former_uploadDir=""
      if @uploadDir.include?('[') then
         @former_uploadDir=@uploadDir.slice(0..@uploadDir.index('[')-1)
      end

      @uploadDir = dynamicDirectory(@uploadDir, file)
      @targetFile  = "#{@uploadDir}/#{file}"

      @uploadTemp = dynamicDirectory(@uploadTemp, file)
      @targetTemp  = "#{@uploadTemp}/#{@prefix}#{file}"
   
   end

   ## ------------------------------------------------------
   ##
   ## Send File now just sends the file
   ##
   def sendFile(file, bDeleteSource=true)

      getUploadTargets(file)

      isReadyToSend(file)
      prevDir = Dir.pwd
      Dir.chdir(@srcDirectory)

      if !@mirroring then
         @protocol   =  @ftpServer[:protocol]
         @hostname   =  @ftpServer[:hostname]
         @port       =  @ftpServer[:port].to_i
         @user       =  @ftpServer[:user]
         @password   =  @ftpServer[:password]
      end

      if @secureMode then 
         @protocol= "SFTP" 
      end 

      #secureMode should be changed for protocol; backwards compatibility
      case @protocol

   #FTP protocol
         when "FTP" then
            if @dynamic then
               cmd  = self.createNcFtpMkd(@hostname,
                                          @port,
                                          @user,
                                          @password,
                                          @uploadDir,
                                          ENV["DCC_TMP"],
                                          "createDir",
                                          @isDebugMode) 
               if @isDebugMode then
                  puts cmd
               end
               retVal = execute(cmd, "send2interface")
            end

            cmd  = self.createNcFtpPut(@hostname,
                                          @port,
                                          @user,
                                          @password,
                                          @uploadTemp,
                                          @uploadDir,
                                          file,
                                          @prefix,
                                          @isDebugMode) 

            if @isDebugMode then
               puts cmd
            end
            retVal = execute(cmd, "send2interface")

   #SFTP protocol
         when "SFTP" then
            # If there is a previous file of a failed execution we delete it.
            if FileTest.exist?(@ftBatchFilename) then 
               File.delete(@ftBatchFilename)
            end  
                    
            sftpClient  = SFTPBatchClient.new(@hostname,
                                             @port,
                                             @user,
                                             @ftBatchFilename,
                                             @ftpServer[:isCompressed])
            if @isDebugMode == true then
               sftpClient.setDebugMode
            end

   	      # It deletes an existing file in the upload dir
	         # with the same filename as the one about to be transferred
	         deleteRemoteFile(file)

   #dynamic directories
            if @dynamic then
               dynamic_uploadDir=@uploadDir.sub(@former_uploadDir,'')
               dynamicSplitArray = dynamic_uploadDir.split('/')
               dynamicSplitArray.each { |dir|
                  @former_uploadDir=@former_uploadDir+'/'+dir
                  sftpClient.addCommand("mkdir", @former_uploadDir, "") 
               }  
               sftpClient.executeAll				           
               @dynamic=false
            end
   ###	    

   	      sftpClient.addCommand("put",
                                  @sourceFile,
                                  %Q{#{@targetTemp}})

            sftpClient.addCommand("rename",
                                  %Q{#{@targetTemp}},
                                  %Q{#{@targetFile}})
         
            retVal = sftpClient.executeAll
            output = sftpClient.output
            
            if @isDebugMode == true then
               puts
               puts "------------------------------------------"
               puts "Client FT output is :\n\n"
               puts output
               puts "------------------------------------------"
               puts
            end

            # After the execution we delete the batchfile
            if FileTest.exist?(@ftBatchFilename) then
               n = File.delete(@ftBatchFilename)
            end

   #FTPS protocol
         when "FTPS" then

            if @isDebugMode then
               puts "FTPS connecting to #{@user}@#{@hostname} getting file #{file}"
            end
        
            begin
               @ftp = Net::FTPFXPTLS::new(@hostname)
               @ftp.login(@user,@password)
               @ftp.passive = true

         #dynamic directories
               if @dynamic then
                  dynamic_uploadDir=@uploadDir.sub(@former_uploadDir,'')
                  dynamicSplitArray = dynamic_uploadDir.split('/')
                  dynamicSplitArray.each { |dir|
                     @former_uploadDir=@former_uploadDir+'/'+dir
                     @ftp.mkdir(@former_uploadDir) 
                  }  			           
                  @dynamic=false
               end
         ###
               @ftp.put(file,@targetTemp)
               @ftp.rename(@targetTemp,@targetFile)
               @ftp.close
               retVal=true
            rescue Exception => e
               puts"Error on FTPS:: #{e}"
               retVal= false 
            end
   #LOCAL protocol
         when "LOCAL" then
            begin
               #dynamic directories
               if @dynamic then
                  FileUtils.mkdir_p(@uploadDir)
                  @dynamic=false
               end
               ###
               retVal= @local.uploadFile(file,@targetFile,@targetTemp)
            rescue Exception => e
               puts"#{e}"
               retVal= false 
            end            
      end   #end of case                                 
    
      Dir.chdir(prevDir)
      
      ## -----------------------------------------
      
      if retVal == true and bDeleteSource == true then
         File.delete(%Q{#{@srcDirectory}/#{file}})
      end

      ## -----------------------------------------

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

      if @protocol == "LOCAL" then
         getUploadTargets(dir)
         retVal=@local.uploadDir(dir,@targetFile,@targetTemp)
         if !retVal then return false end
      else

      @ftp           = nil

      if !@mirroring then
         @hostname   = @ftpServer[:hostname]      
         @port       = @ftpServer[:port].to_i
         @user       = @ftpServer[:user]
         @password   = @ftpServer[:password]
      end

      begin
         if @protocol == "FTPS" then
            @ftp = Net::FTPFXPTLS::new(@hostname)
         else
            @ftp = Net::FTP.new(@hostname)
         end
         @ftp.login(@user, @password)
         @ftp.passive = true
      rescue Exception => e
         puts
         puts e.to_s
         puts "Unable to connect to #{@hostname}"
         @logger.log("#{@entity}: #{e.to_s}")
         @logger.log("#{@entity}: Unable to connect to #{@hostname}")
         @logger.log("Could not send #{dir} to #{@entity} I/F")
         puts
         return false
      end

      prevDir = Dir.pwd
      
      begin
         @ftp.chdir(@ftpServer[:uploadDir])
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
   end

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
      uploadDir   = @ftpServer[:uploadDir]
      targetFile  = %Q{"#{uploadDir}/#{file}"}
       
      sftpClient  = SFTPBatchClient.new(@hostname,
                                            @port,
                                            @user,
                                            @ftBatchFilename,
                                            @ftpServer[:isCompressed])
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
      uploadTemp  = @ftpServer[:uploadTemp]
       
      sftpClient  = CTC::SFTPBatchClient.new(@hostname,
                                           @port,
                                           @user,
                                           @ftBatchFilename,
                                           @ftpServer[:isCompressed])
    
      sftpClient.addCommand("cd", uploadTemp, nil)
      sftpClient.addCommand("rm","*", nil)
       
      retVal = sftpClient.executeAll
      output = sftpClient.output
   end
   #-------------------------------------------------------------
   
end # class

end # module
