#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FileSender class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# Git: $Id: FileSender.rb,v 1.18 2014/05/20 14:41:04 algs Exp $
#
#########################################################################

require 'net/ssh'
require 'net/sftp'
require 'ftpfxp'
require 'fileutils'

require 'ctc/FTPClientCommands'
require 'ctc/SFTPBatchClient'
require 'ctc/WrapperCURL'
require 'ctc/LocalInterfaceHandler'
require 'cuc/DirUtils'
require 'cuc/CommandLauncher'
require 'dec/LocalInterfaceHandler'

module CTC

 # Module Common Transfer Component
 # This class performs the file(s) delivery.
 #
 # This class provides methods for sending files to entities using various protocols.
 # It implements both, secure and non secure file transfers.
 #

class FileSender

   # -------------------------
   # Mixins includes
   include CTC::FTPClientCommands
   include CTC::WrapperCURL
   include CTC   
   include CUC::DirUtils
   include CUC::CommandLauncher
   # -------------------------

   attr_reader :fileList
   
   ## Class constructor
   ## - Server Struct  (IN): DDC_ReadEntityConfig::fillFTPServerStruct
   ## - hParameters       (IN): Hash type containing Additional Parameters   
   def initialize(entity, pushServerStruct, protocol, logger, hParameters=nil)
      @entity           = entity
      @pushServer       = pushServerStruct
      @protocol         = protocol
      @uploadDir        = @pushServer[:uploadDir]
      @uploadTemp       = @pushServer[:uploadTemp]
      @logger           = logger
      @hParameters      = hParameters
      checkModuleIntegrity
      @ftBatchFilename  = %Q{.BatchSenderFile4#{@pushServer[:mnemonic]}}
      @isDebugMode      = false
      @fileListLoaded   = false
      @entity           = @pushServer[:mnemonic]
      @secureMode       = @pushServer[:isSecure]
      @passiveMode      = @pushServer[:isPassive]
      @url              = nil
      @dynamic          = false
      @mirroring        = false
      @prefix           = ''
      
      if @protocol == 'LOCAL' then
         #false stands for use DCC; true stands for use DDC
         @local = DEC::LocalInterfaceHandler.new(@entity, false, true, false)
      end
      
      if @protocol == 'HTTP' then
         buildURL
      end
      
   end
   ## -----------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("FileSender debug mode is on")
   end
   ## -----------------------------------------------------------

   ## Set the flag for debugging on
   def setUploadPrefix(prefix)
      @prefix = prefix
   end
   ## -----------------------------------------------------------
   
   ## Set the files to be sent.
   ## - arrFiles (IN): Array of files to be sent
   ## - dirname  (IN): Outbox directory path.
   def setFileList(arrFiles, outboxPath)
      checkDirectory(outboxPath)
      pwd = Dir.pwd
      Dir.chdir(outboxPath)      
      arrFiles.each{|file|
         if File.exist?(file) == false then
            @logger.error("Error in FileSender::setFileList #{file} does not exist in #{outboxPath}")
            raise "#{file} does not exist in #{outboxPath}"
         end
      }
      Dir.chdir(pwd)
      @fileList         = arrFiles.uniq
      @srcDirectory     = outboxPath
      @fileListLoaded   = true
   end
   ## -----------------------------------------------------------
   
   def useMirrorServer(file, bIsNotDir=true)
      
      @mirroring  =  true
      @protocol   =  @pushServer[:FTPServerMirror][:protocol]
      @hostname   =  @pushServer[:FTPServerMirror][:hostname]
      @port       =  @pushServer[:FTPServerMirror][:port].to_i
      @user       =  @pushServer[:FTPServerMirror][:user]
      @password   =  @pushServer[:FTPServerMirror][:password]

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

      @uploadDir   = @pushServer[:uploadDir]
      @uploadTemp  = @pushServer[:uploadTemp]
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

      if @isDebugMode == true then
         @logger.debug("FileSender::sendFile => #{file}")
      end

      getUploadTargets(file)

      isReadyToSend(file)
      prevDir = Dir.pwd
      Dir.chdir(@srcDirectory)

      if !@mirroring then
         @protocol   =  @pushServer[:protocol]
         @hostname   =  @pushServer[:hostname]
         @port       =  @pushServer[:port].to_i
         @user       =  @pushServer[:user]
         @password   =  @pushServer[:password]
      end
      
      ## ===================================================
      
      case @protocol.upcase

         when "FTP" then
            if @dynamic then
               cmd  = self.createNcFtpMkd(@hostname,
                                          @port,
                                          @user,
                                          @password,
                                          @uploadDir,
                                          ENV["DEC_TMP"],
                                          "createDir",
                                          @isDebugMode) 
               if @isDebugMode then
                  @logger.debug(cmd)
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
               @logger.debug(cmd)
            end
            retVal = execute(cmd, "send2interface")

         ## ===================================================
         
         when "SFTP" then
            # If there is a previous file of a failed execution we delete it.
            if FileTest.exist?(@ftBatchFilename) then 
               File.delete(@ftBatchFilename)
            end  
                    
            sftpClient  = SFTPBatchClient.new(@hostname,
                                             @port,
                                             @user,
                                             @ftBatchFilename,
                                             @pushServer[:isCompressed])
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
               @logger.debug("Client FT output is :")
               @logger.debug(output)
            end

            # After the execution we delete the batchfile
            if FileTest.exist?(@ftBatchFilename) then
               n = File.delete(@ftBatchFilename)
            end

         ## ===================================================
         
         when "FTPS" then

            if @isDebugMode then
               @logger.debug("FTPS connecting to #{@user}@#{@hostname} getting file #{file}")
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
         ## ===================================================
         
         when "LOCAL" then
            begin
               #dynamic directories
               if @dynamic then
                  FileUtils.mkdir_p(@uploadDir)
                  @dynamic=false
               end
               ###
               retVal = @local.uploadFile(file, @targetFile, @targetTemp)
            rescue Exception => e
               @logger.error("#{e.to_s}")
               retVal= false 
            end
            
         ## ===================================================
               
         when "WEBDAV" then
            retVal = sendFileHTTP(file, bDeleteSource)
         
         ## ===================================================
         
         when "HTTP" then
            retVal = sendFileHTTP(file, bDeleteSource)
         else
            @logger.error("protocol #{@protocol} not implemented")
            raise "protocol #{@protocol} not implemented"
            
         ## ===================================================          
      end   #end of case                                 
    
      Dir.chdir(prevDir)
      
      ## -----------------------------------------
      
      if retVal == true and bDeleteSource == true then
         File.delete(%Q{#{@srcDirectory}/#{file}})
      end

      ## -----------------------------------------

      return retVal
      
   end


   ## -----------------------------------------------------------

   def sendFileHTTP(file, bDeleteSource = true)
      if @isDebugMode == true then
         @logger.debug("FileSender::sendFileHTTP => #{file} / #{bDeleteSource}")
      end
      return putFile(@url, file, @isDebugMode, @logger)
   end

   ## -----------------------------------------------------------

   ## It sends the directory and all its content
   def sendDir(dir, bDeleteSource = true)
      if @secureMode == false then
         return sendNonSecureDir(dir, bDeleteSource)
      else
         @logger.error("FileSender::sendSecureDir is not implemented ! #{'1F480'.hex.chr('UTF-8')}")
         raise "FileSender::sendSecureDir is not implemented ! #{'1F480'.hex.chr('UTF-8')}"
      end
   end
   ## -----------------------------------------------------------

   def sendNonSecureDir(dir, bDeleteSource = true)

      if @protocol == "LOCAL" then
         getUploadTargets(dir)
         retVal=@local.uploadDir(dir,@targetFile,@targetTemp)
         if !retVal then return false end
      else

      @ftp           = nil

      if !@mirroring then
         @hostname   = @pushServer[:hostname]      
         @port       = @pushServer[:port].to_i
         @user       = @pushServer[:user]
         @password   = @pushServer[:password]
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
         @logger.error("#{@entity}: #{e.to_s}")
         @logger.error("#{@entity}: Unable to connect to #{@hostname}")
         @logger.error("Could not send #{dir} to #{@entity} I/F")
         return false
      end

      prevDir = Dir.pwd
      
      begin
         @ftp.chdir(@pushServer[:uploadDir])
         @ftp.mkdir("__#{dir}")
      rescue Exception => e
         @logger.error("Could not create __#{dir}")
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
            @ftp.putbinaryfile(aFile)
         }
         @ftp.chdir("..")
      rescue Exception => e
         @logger.error("Could not send temp __#{dir}")
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
         @logger.error("Could not send #{dir}")
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
      uploadDir   = @pushServer[:uploadDir]
      targetFile  = %Q{"#{uploadDir}/#{file}"}
       
      sftpClient  = SFTPBatchClient.new(@hostname,
                                            @port,
                                            @user,
                                            @ftBatchFilename,
                                            @pushServer[:isCompressed])
#       sftpClient.setDebugMode
      sftpClient.addCommand("rm", targetFile, nil)
       
      retVal = sftpClient.executeAll
      output = sftpClient.output 
   end   
   #-------------------------------------------------------------
      
private

   ## -----------------------------------------------------------
   
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true
                   
      if bCheckOK == false then
         puts "\nFileSender::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end      
   end
   
   ## -----------------------------------------------------------
   ## Check if everything is ready to perform the transfer.
   ## The following data needs to be loaded in the object:
   ## * List of files to be sent
   def isReadyToSend(file = "")
      if @fileListLoaded == false then
         raise "Error in FileSender::isReadyToSend"
      end
      if file != "" then
         if File.exist?("#{@srcDirectory}/#{file}") == false then
            @logger.error("File {file} is not present in the outbox ! :-(")
            @logger.error("Fatal Error in FileSender::isReadyToSend(#{file})")
            raise "Fatal Error in FileSender::isReadyToSend(#{file})"
         end
      end
   end
   ## -----------------------------------------------------------

   ## It deletes all UploadTemp content
   def cleanUpRemoteTemp
      if @secureMode == false then
         @logger.error("UploadTemp cleanup not implemented for non-secure mode !")
         raise "UploadTemp cleanup not implemented for non-secure mode !"
      end
      uploadTemp  = @pushServer[:uploadTemp]
       
      sftpClient  = CTC::SFTPBatchClient.new(@hostname,
                                           @port,
                                           @user,
                                           @ftBatchFilename,
                                           @pushServer[:isCompressed])
    
      sftpClient.addCommand("cd", uploadTemp, nil)
      sftpClient.addCommand("rm","*", nil)
       
      retVal = sftpClient.executeAll
      output = sftpClient.output
   end
   ## -----------------------------------------------------------
   
   def buildURL
      if @pushServer[:user] != "" and @pushServer[:password] != "" then
         @url = "#{@pushServer[:user]}:#{@pushServer[:password]}@#{@pushServer[:hostname]}:#{@pushServer[:port]}#{@pushServer[:uploadDir]}"
      else
         @url = "#{@pushServer[:hostname]}:#{@pushServer[:port]}#{@pushServer[:uploadDir]}"
      end
      
      if @pushServer[:isSecure] == false then
         @url = "http://#{@url}"
      else
         @url = "https://#{@url}/"
      end
   end
   ## -----------------------------------------------------------
   
end # class

end # module
