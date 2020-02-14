#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DEC_ReceiverFromInterface class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component
# 
# Git: $Id: DEC_ReceiverFromInterface.rb,v 1.29 2008/11/27 13:59:32 decdev Exp $
#
# Module Data Exchange Component
# This class polls a given Interface and gets all registered available files
# via FTP, SFTP, WebDAV HTTP, or LOCAL.
#
#########################################################################

### IPC for children process (overall volume downloaded)

### https://www.jstorimer.com/blogs/workingwithcode/7766091-introduction-to-ipc-in-ruby

### https://stackoverflow.com/questions/3057120/shared-variable-among-ruby-processeshttps://stackoverflow.com/questions/3057120/shared-variable-among-ruby-processes

### https://stackoverflow.com/questions/53646103/pipe-with-multiple-child-process

require 'rubygems'
require 'curb'
require 'net/http'
require 'net/ssh'
require 'net/sftp'
require 'timeout'
require 'benchmark'

require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'cuc/CommandLauncher'
require 'cuc/EE_ReadFileName'
require 'ctc/ListWriterUnknown'
require 'ctc/ListWriterDelivery'
require 'ctc/FTPClientCommands'
require 'ctc/SFTPBatchClient'
require 'dec/LocalInterfaceHandler'
require 'dec/FileDeliverer2InTrays'
require 'dec/ReadConfigDEC'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigIncoming'
require 'dec/EventManager'
require 'dec/EntityContentWriter'
require 'dec/CheckerInterfaceConfig'

module DEC

class DEC_ReceiverFromInterface

   include Benchmark
   include Process
   
   include CUC::DirUtils
   include CTC::FTPClientCommands
   include CUC::CommandLauncher
   
   attr_accessor :isBenchmarkMode

   ## -------------------------------------------------------------

   ## Class constructor.
   ## * entity (IN):  Entity textual name (i.e. FOS)
   def initialize(entity, drivenByDB = true, isNoDB = false, isNoInTray = false, isDelUnknown = false, isDebug = false)
      @entity        = entity
      @drivenByDB    = drivenByDB
      @isNoDB        = isNoDB
      @isNoInTray    = isNoInTray
      @isDelUnknown  = isDelUnknown
      @isDebugMode   = isDebug
      checkModuleIntegrity
      @isBenchmarkMode = false

      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("DEC_Puller", "#{@@configDirectory}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in DEC_ReceiverFromInterface::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{@@configDirectory}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end

      checker     = CheckerInterfaceConfig.new(entity, true, false)
      
      if @isDebugMode == true then
         checker.setDebugMode
      end
      
      retVal      = checker.check

      if retVal == true then
         if @isDebugMode == true then
            @logger.debug("#{entity} I/F is configured correctly\n")
	      end
      else
         raise "\nError in DEC_ReceiverFromInterface::initialize :-(\n\n" + "\n\n#{entity} I/F is not configured correctly\n\n"
      end
     
      @entityConfig     = ReadInterfaceConfig.instance
      @protocol         = @entityConfig.getProtocol(@entity)
      @ftpserver        = @entityConfig.getFTPServer4Receive(@entity)
      @ftpserver[:arrDownloadDirs] = ReadConfigIncoming.instance.getDownloadDirs(@entity)
      @pollingSize      = @entityConfig.getTXRXParams(@entity)[:pollingSize]
      
      ## -------------------------------------
      
      @dimConfig        = ReadConfigIncoming.instance
      @finalDir         = @dimConfig.getIncomingDir(@entity)
      checkDirectory(@finalDir)
      ## @finalDir         = @entityConfig.getIncomingDir(@entity)
      ## -------------------------------------
      
      ## 2016 currently hardcoded number of files handled on each iteration in case
      ## it is not defined in the configuration
      if @pollingSize == nil then
         @pollingSize      = 150
      else
         @pollingSize = @pollingSize.to_i
      end
      ## -------------------------------------      
            
      @parallelDownload = @entityConfig.getTXRXParams(@entity)[:parallelDownload]      
      
      @fileSource       = ReadConfigIncoming.instance                  
      ##@fileSource       = CTC::ReadFileSource.instance

      if @isNoDB == false then
         # require 'dbm/DatabaseModel'
         require 'dec/DEC_DatabaseModel'
         @interface        = Interface.find_by_name(@entity)
         if @interface == nil then
            raise "\n#{@entity} is not a registered I/F ! :-(" + "\ntry registering it with addInterfaces2Database.rb tool !  ;-) \n\n"
         end
      end

      removePreviousTempDirs

      @decConfig   = ReadConfigDEC.instance
      @arrFilters  = @decConfig.getIncomingFilters

      @satPrefix   = ReadConfigDEC.instance.getSatPrefix
      @prjName     = ReadConfigDEC.instance.getProjectName
      @prjID       = ReadConfigDEC.instance.getProjectID
      @mission     = ReadConfigDEC.instance.getMission
      checkDirectory(ReadConfigDEC.instance.getReportDir)
   end   
   ## -------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("DEC_ReceiverFromInterface debug mode is on")
   end
   ## -------------------------------------------------------------
   
   ## this method overrides the configuration item in the file
   def overrideParallelDownloads(nSlots)
      if (nSlots.to_i < 1) then
         return false
      end
      @parallelDownload = nSlots.to_i
   end
   ## -------------------------------------------------------------
   
   ## Check whether there are new files waiting.
   ## * Returns true if there are new files availables.
   ## * Otherwise returns false.
   def check4NewFiles(forCheck = false)
      cmd   = ""
      perf  = ""
      list  = nil
            
      case @protocol
         
         # ---------------------------------------
         
         when "FTP"
               
            if @isDebugMode == true then
               @logger.debug("I/F #{@entity} is non secure mode / #{@protocol}")
            end

            perf = measure { list = getNonSecureFileList( @ftpserver[:isPassive]) }

         # ---------------------------------------

         when "SFTP"
            
            if @isDebugMode == true then
               @logger.debug("I/F #{@entity} requires secure mode / #{@protocol}")
            end

            perf = measure { list = getSecureFileList }
            
         # ---------------------------------------
         
         when "FTPS"  
            
            puts "FTPS not integrated yet from ALGK"
            puts
            puts "DEC_ReceiverFromInterface::check4NewFiles"
            puts
            exit(99)
         
         # ---------------------------------------   
            
         when "LOCAL"
         
            if @isDebugMode == true then
               @logger.debug("I/F #{@entity} does not use network / #{@protocol}")
            end

          
            begin
               
               @local = DEC::LocalInterfaceHandler.new(@entity, true, false, @decConfig.getDownloadDirs)
               
               if @isDebugMode then 
                  @local.setDebugMode
               end
                  
               perf = measure { list = @local.getLocalList }      
            
            rescue Exception => e
                  @logger.error(e.to_s)
                  if @isDebugMode == true then
                     @logger.debug(e.backtrace)
                  end
                  exit (99)
            end     
         
         # ---------------------------------------
         
         when "WEBDAV"

            if @isDebugMode == true then
               @logger.debug("I/F #{@entity} uses #{@protocol} protocol")
            end
            
            if @isDebugMode == true then
               @logger.debug(list)
            end
            
            perf = measure { 
               list = getWebDavFileList 
               if @isDebugMode == true then
                  @logger.debug("Found #{list.length} files")
               end
            }            
                     
         # ---------------------------------------
            
      end
           
      if @isBenchmarkMode == true then
         @logger.info("File-Tree from #{@entity}: #{perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")}")
         @logger.debug("Retrieved from #{@entity} #{list.length} files to be filtered")
      end

      perf = measure { @fileList = filterFullPathFileList(list, forCheck) }
            
      n = @fileList.length

      if @isBenchmarkMode == true then
         @logger.info("Filtered (config + database) #{list.length} items : #{perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")}")
      end

      if n > 0 then
         return true
      else
         return false
      end

   end
   ## -----------------------------------------------------------
   
   def getWildNonSecureList(path)

      if @isDebugMode == true then
         @logger.debug("Wild-search enabled for #{path}")
         @ftp.debug_mode = true
      end
         
      begin
         @ftp.chdir(path)
      rescue Exception => e
         @ftp.chdir("/")
         return
      end
   
#      entries = @ftp.nlst("-R")
      entries = @ftp.list("-R")

      currentDir = ""

      entries.each{|element|
         if element == "" then
            next
         end
         if element.slice(0,1) == "." then
            currentDir = path + element.chop.slice(1,element.length)
            next
         end
         type = element.slice(0,1)

         if type != "-" then
            next
         end
                  
         newFile = currentDir + "/" + element.split(" ").at(-1)
         
         if @isDebugMode == true then
            @logger.debug("Found #{newFile}")
         end

         @newArrFile << newFile
      }
      return
   end
   ## -----------------------------------------------------------

   def getNonSecureFileList(bPassive)
      @newArrFile    = Array.new
      @ftp           = nil
      host           = @ftpserver[:hostname]      
      port           = @ftpserver[:port].to_i
      user           = @ftpserver[:user]
      pass           = @ftpserver[:password]
      @depthLevel    = 0

      begin
         if @isDebugMode == true then
            @logger.debug("FTP #{host}:#{port} #{user}:#{pass} | passive = #{bPassive}")
         end
         @ftp = Net::FTP.new(host)
         @ftp.login(user, pass)
         @ftp.passive = bPassive
      rescue Exception => e
         @logger.error("#{@entity}: #{e.to_s}")
         @logger.error("#{@entity}: Unable to connect to #{host} with passive mode #{bPassive}")
         @logger.error("Could not poll #{@entity} I/F")
         exit(99)
      end

      arrElements = @ftpserver[:arrDownloadDirs]

      arrElements.each{|element|
                  
         @remotePath = element[:directory]
         @maxDepth   = element[:depthSearch]

         # If it is desired recursive "wild" mode 
         if @maxDepth == 666 then
            getWildNonSecureList(@remotePath)
            next
         end

         if @isDebugMode == true then
            @logger.debug("Polling directory => #{@remotePath} for #{@entity}")
         end
         
         begin
            @ftp.chdir(@remotePath)
         rescue Exception => e
            @ftp.chdir("/")
            @logger.error("cannot reach #{@remotePath}")
            @logger.error(e.to_s)               
            if @isDebugMode == true then
               @logger.debug(e.backtrace)
            end
            next
         end

         @pwd = @ftp.pwd
         
         begin         
            entries = @ftp.list
         rescue Exception => e
            @logger.error("Failed to get list of files / FTP passive mode is #{@ftp.passive}")
            @logger.error(e.to_s)
            if @isDebugMode == true then
               @logger.debug(e.backtrace)
            end
            exit(99)
         end
         entries.each{|entry|
            exploreNonSecureTree(entry)
         }
         @ftp.chdir("/")
      }
      @ftp.close
      return @newArrFile
   end
   ## -----------------------------------------------------------

   def exploreNonSecureTree(relativePath)
      arrTmp  = relativePath.split(" ")
      if arrTmp[0].downcase == "total" then
         return
      end
      if arrTmp[0].length != 10 then
         return
      end
      element = arrTmp[arrTmp.length-1]
      if arrTmp[0].slice(0,1) != "d" then
         if @isDebugMode == true then
            @logger.debug("Found #{%Q{#{@pwd}/#{element}}}")
         end
         @newArrFile << %Q{#{@pwd}/#{element}}
         return
      end
      
      if @depthLevel >= @maxDepth then
         return
      end

      begin
         @ftp.chdir(element)
         @pwd = @ftp.pwd
      rescue Exception => e
         @logger.error(e.to_s)
         if @isDebugMode == true then
            @logger.debug(e.backtrace)
         end
      end

      sleep(0.4)

      begin
         @ftp.noop
      rescue Exception => e
         @logger.error(e.to_s)
         if @isDebugMode == true then
            @logger.debug(e.backtrace)
         end
      end

      @depthLevel = @depthLevel + 1 

      entries = @ftp.list
      entries.each{|element|
         exploreNonSecureTree(element)
      }
      begin
         @ftp.noop
         @ftp.chdir("..")
         @pwd = @ftp.pwd
      rescue Exception => e
         @logger.error(e.to_s)
         if @isDebugMode == true then
            @logger.debug(e.backtrace)
         end
      end
      @depthLevel = @depthLevel - 1   
   end
   
   ## -----------------------------------------------------------

   ## retrieving of the list of files available using WebDAV protocol   
   def getWebDavFileList

      @newArrFile = Array.new
      host        = ""
      if isSecureMode == false then
         host        = "http://#{@ftpserver[:hostname]}:#{@ftpserver[:port]}/"
      else
         host        = "https://#{@ftpserver[:hostname]}:#{@ftpserver[:port]}/"
      end
      port        = @ftpserver[:port].to_i
      user        = @ftpserver[:user]
      pass        = @ftpserver[:password]
      dav         = Net::DAV.new(host, :curl => false)
      
      ## -------------------------------
      ## new configuration item VerifyPeerSSL is needed
      ##
      # dav.verify_server = true
      dav.verify_server = false
      ## -------------------------------
 
      ## -------------------------------
      ## if credentials are not empty in the configuration file
      if user != "" or (pass != "" and pass != nil) then
         if @isDebugMode == true then
            @logger.debug("Passing Credentials #{user} #{pass} to WebDAV server")
         end
         dav.credentials(user, pass)
      end
      ## -------------------------------
      
      @depthLevel = 0
      arrElements = @ftpserver[:arrDownloadDirs]

      arrElements.each{|element|
         @remotePath    = element[:directory]
         @recursive     = (element[:depthSearch].to_i > 0)
         
         if @isDebugMode == true then
            @logger.debug("Checking directory #{@remotePath} - recursive search is #{@recursive}")
         end
         
         begin
            dav.find(@remotePath,:recursive => @recursive,:suppress_errors=>true) do | item |
               if @isDebugMode == true then
                  @logger.debug("Found #{item.url.to_s}")
               end 
               if item.type.to_s.downcase == "file" then
                  @newArrFile << item.url.to_s
               end
            end
         rescue Exception => e
            @logger.error(e.to_s)
            if @isDebugMode == true then
               @logger.debug(e.backtrace)
            end
            next
         end
      }   
      
      return @newArrFile
   end
   ## -----------------------------------------------------------

   def getSecureFileList
      @newArrFile = Array.new
      @ftp        = nil
      host        = @ftpserver[:hostname]
      port        = @ftpserver[:port].to_i
      user        = @ftpserver[:user]
      @depthLevel = 0

      begin
         Timeout.timeout(10) do
            @ftp     = Net::SFTP.start(host, user, :port => port, :timeout => 5)
            @session = @ftp.connect!
         end
      rescue Exception => e
         @logger.error("#{@entity}: #{e.to_s}")
         @logger.error("#{@entity}: Unable to connect to #{host}")
         @logger.error("Could not poll #{@entity} I/F")
         if @isDebugMode == true then
            @logger.debug(e.backtrace)
         end
         exit(99)
      end

      arrElements = @ftpserver[:arrDownloadDirs]

      arrElements.each{|element|
         @remotePath = element[:directory]
         @maxDepth   = element[:depthSearch]
         begin

            exploreSecureTree(@remotePath, 0)

         rescue Exception => e
            @logger.error("#{e.class.to_s.upcase} : Unable to explore directory tree from : #{@remotePath}")
            @logger.error(e.to_s)
         
            if @isDebugMode == true then
               @logger.debug(e.backtrace)
            end            
            next
         end
      }

      @ftp.session.close

      return @newArrFile
   end
   ## -----------------------------------------------------------
   ##
   ## Method that recursively list the files in the directoy corresponding to the given handle.
   def exploreSecureTree(path, depth)
      req = Array.new
      begin
        Timeout.timeout(300) do
            handle = @ftp.opendir!(path)
            req = @ftp.readdir!(handle)
            # req = @ftp.readdir(handle)
            @ftp.close!(handle)
        end
      # rescue Net::SFTP::StatusException => status_e
      rescue Exception => status_e
         @logger.error("StatusException : Unable to list #{path} (#{status_e.message})")
         if @isDebugMode == true then
            @logger.debug(status_e.backtrace)
         end
         return
      end

      req.each{|item| 
         # Discard folders "." and ".."
         if item.name == "." or item.name == ".." then
            next
         end       

         # Add item to list if it is a regular file
         if item.file? then
            fullFile = "#{path}/#{item.name}"
            if @isDebugMode then
               @logger.debug("Found #{fullFile}")
            end
            @newArrFile << fullFile
            next         
         end 

         # Make recursive call if the item is a directory
         if item.directory? and depth < @maxDepth then
            exploreSecureTree("#{path}/#{item.name}", depth+1)
         end
  
      }

   end
   ## -----------------------------------------------------------

   def receiveAllFilesParallel
      currentDir = Dir.pwd
      checkDirectory(@localDir)
      Dir.chdir(@localDir)
      @retValFilesReceived    = true
      @atLeast1FileReceived   = false
      listFiles               = Array.new(@fileList)
      
      arrSent  = Array.new
      
      loop do
         break if listFiles.empty?
         1.upto(@parallelDownload) {|i|
            break if listFiles.empty?
            file = listFiles.shift
            arrSent << file
            fork{
               if @isDebugMode == true then
                  @logger.debug("Child process created to download #{File.basename(file)}")
            	end
               ret = downloadFile(file)
               if ret == false then
                  @logger.error("Child process failed to download #{File.basename(file)}")
                  @retValFilesReceived  = false
                  exit(1)
               else
                  #@logger.info("Forking Success #{File.basename(file)}")
                  @atLeast1FileReceived = true
                  exit(0)
               end 
            }
         }
         arr = Process.waitall
         arr.each{|child|
            if child[1].exitstatus == 0 then
               #@logger.info(arrSent)
               @atLeast1FileReceived = true
            else
               @logger.error("Problem(s) during file download")
               @retValFilesReceived = false
            end
         }
         arrSent  = Array.new
      end
            
      deleteTempDir
      
#		createContentFile(@finalDir)

      # Create new files received lock file
      if @bCreateNewFilesLock == true and @fileList.length >0 and @atLeast1FileReceived == true
         notifyNewFilesReceived
      end

      Dir.chdir(currentDir)
      return @retValFilesReceived   
   end
   ## -----------------------------------------------------------

   def receiveAllFiles
      ret = false
      perf = measure{ ret = receiveAllFiles_forReal }
      
      if @isBenchmarkMode == true then
         @logger.info("Complete download from #{@entity} in #{perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")}")
      end

      return ret
   end
   ## -----------------------------------------------------------
   
   ## Get all Files found in the previous polling to the I/F.
   ## All files are left in a temp local directory
   ## $DEC_TMP/<current_time>_entity
   def receiveAllFiles_forReal
   
      if @parallelDownload > 1 then
         return receiveAllFilesParallel
      end
   
      currentDir = Dir.pwd
      checkDirectory(@localDir)
      Dir.chdir(@localDir)

      @retValFilesReceived  = true
      @atLeast1FileReceived = false
		
      
      @fileList.each{|file|
                      
			      ret = downloadFile(file)
            
               if ret == false then
                  @retValFilesReceived  = false
               else
                  @atLeast1FileReceived = true
               end
		
      
      }
      
      deleteTempDir
      
#		createContentFile(@finalDir)

      # Create new files received lock file
      if @bCreateNewFilesLock == true and @fileList.length >0 and @atLeast1FileReceived == true
         notifyNewFilesReceived
      end

      Dir.chdir(currentDir)
      return @retValFilesReceived
   end
   ## -------------------------------------------------------------
   
	# createListFile
	def createListFile(directory, bDeliver = true)
	   createContentFile(directory, bDeliver)
	end
	## -------------------------------------------------------------
	
   def createReportFile(directory, bDeliver = true, bForceCreation = false)
	   bFound      = false
      bIsEnabled  = false
      fileType    = ""
      fileClass   = ""
      desc        = ""
      time        = Time.now
      now         = time.strftime("%Y%m%dT%H%M%S")
               
      arrReports = @decConfig.getReports

      bIsEnabled = false

      # -----------------------------------------------------
      # Create RetrievedFiles Report

      if @fileList.length > 0 then

         arrReports.each{|aReport|
            if aReport[:name] == "RETRIEVEDFILES" then
               bFound      = true
               fileType    = aReport[:fileType]
               desc        = aReport[:desc]
               bIsEnabled  = aReport[:enabled]
               fileClass   = aReport[:fileClass]
            end
         }

         if bForceCreation == true and bFound == false then
            if @isDebugMode == true then
               @logger.debug("Explicit Request creation of RetrievedFiles Report")
            end
            @logger.warn("RetrievedFiles Report is not configured in dec_config.xml :-|")
            return
         end

         if bFound == true and bIsEnabled == true then

            writer = CTC::ListWriterDelivery.new(directory, true, fileClass, fileType)

            if @isDebugMode == true then
		         writer.setDebugMode
            end

            writer.setup(@satPrefix, @prjName, @prjID, @mission)
            writer.writeData(@entity, time, @fileList)
      
            filename = writer.getFilename
         
            @logger.info("Created Report File #{filename}")
   
            if filename == "" then
               @logger.error("Error in DEC_ReceiverFromInterface::createReportFile !!!! =:-O \n\n")
               exit(99)
            end

## Report files are not disseminated but placed in the directory <ReportDir> defined in dec_config.xml         
#            if bDeliver == true then
#               deliverer = FileDeliverer2InTrays.new
#   
#               if @isDebugMode == true then
#                  deliverer.setDebugMode
#               end

#               deliverer.deliverFile(@entity, directory, filename)

#            end
         end

      end

      #-----------------------------------------------------
      # Create UnknownFiles Report

      if @fileListError.length > 0 then

         arrReports.each{|aReport|
            if aReport[:name] == "UNKNOWNFILES" then
               bFound      = true
               fileType    = aReport[:fileType]
               desc        = aReport[:desc]
               bIsEnabled  = aReport[:enabled]
            end
         }

         if bForceCreation == true and bFound == false then
            if @isDebugMode == true then
               @logger.debug("Explicit Request creation of UnknownFiles Report")
            end
            @logger.warn("UnknownFiles Report is not configured in dec_config.xml :-|")
            return
         end


         if bFound == true and bIsEnabled == true then
	         writer = CTC::UnknownListWriter.new(directory, false, fileType)

            if @isDebugMode == true then
		         writer.setDebugMode
            end

            writer.setup(@satPrefix, @prjName, @prjID, @mission)
            writer.writeData(@entity, time, @fileListError)
      
            filename = writer.getFilename
         
            if @isDebugMode == true then
               @logger.debug("Created Report File #{filename}")
            end
   
            if filename == "" then
               @logger.error("Error in DEC_ReceiverFromInterface::createReportFile !!!! =:-O")
               exit(99)
            end
         
            if bDeliver == true then
               deliverer = FileDeliverer2InTrays.new
   
               if @isDebugMode == true then
                  deliverer.setDebugMode
                  @logger.debug("Creating and Deliver Report File")
               end
               deliverer.deliverFile(@entity, directory, filename)
            end
         end

      end

   end
   #-------------------------------------------------------------
   
   # Get new files availables from the I/F
   def getAvailablesFiles
      return @fileList
   end
   #-------------------------------------------------------------

   # Get new files availables from the I/F
   def getUnknownFiles
      return @fileListError
   end
   #-------------------------------------------------------------

private
   @logger        = nil
   @ftpserver     = nil
   @localDir      = ""
   @finalDir      = ""
   @fileList      = nil
   @fileListErr   = nil
   
   ## -------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      
      if !ENV['DEC_TMP'] then
         puts "\nDEC_TMP environment variable not defined !\n"
         bDefined = false
      end
      
      if ENV['DEC_TMP'] then
         @tmpDir         = %Q{#{ENV['DEC_TMP']}}  
      end        
      
      configDir = nil
         
      if ENV['DEC_CONFIG'] then
         configDir         = %Q{#{ENV['DEC_CONFIG']}}
      else
         puts "Fatal ERROR ::DEC_ReceiverFromInterface::checkModuleIntegrity DEC_CONFIG not defined"
         exit(99)
      end        
            
      @@configDirectory = configDir
     
      if bDefined == false then
         puts "\nError in DEC_ReceiverFromInterface::checkModuleIntegrity :-(\n\n"
         exit(99)
      end
                        
      time = Time.new
      time.utc
      str  = time.strftime("%Y%m%d_%H%M%S")
                                      
      @localDir        = %Q{#{@tmpDir}/.#{str}_#{@entity}}  
      @ftBatchFilename = %Q{#{@tmpDir}/.FTBatchReceiveFrom#{@entity}}
      if FileTest.exist?(@ftBatchFilename) == true then
         File.delete(@ftBatchFilename)
      end

      # Specific RPF/MMPF Requirement:
      # FTPROOT is not an "official" DCC environment variable
      # therefore its definition is not mandatory.
      # When it is defined, everytime new files are retrieved ft_new_files.lock
      # is created

      if !ENV['FTPROOT'] then
         @bCreateNewFilesLock = false
         @DCC_NEW_FILES_LOCK = "/tmp/ft_new_files.lock"
      else
         @bCreateNewFilesLock = true
         @DCC_NEW_FILES_LOCK  = %Q{#{ENV['FTPROOT']}/ft_new_files.lock}
      end

   end
   ## -----------------------------------------------------------
   
   def downloadFileLocal(filename)
      retVal = @local.downloadFile(filename)
      
       if retVal == false then
         @logger.error("Could not download #{filename} from #{@entity} I/F")
         return false
      else
		   # copy it to the final destination
         
         size = File.size("#{@localDir}/#{File.basename(filename)}")
         
         # @logger.debug("#{File.basename(filename)} received with size #{size} bytes")
         # @logger.info("#{File.basename(filename)} received with size #{size} bytes")
			
         copyFileToInBox(File.basename(filename), size)
			         
			# update DEC Inventory
			setReceivedFromEntity(File.basename(filename), size)
			
			# if deleteFlag is enable delete it from remote directory
         if @protocol == "LOCAL" then
            @local.deleteFromEntity(filename)
         else
   			deleteFromEntity(filename)
         end      
         
         @logger.info("#{File.basename(filename)} Downloaded from #{@entity} I/F with size #{size} bytes")

         event  = EventManager.new
         
         if @isDebugMode == true then
            event.setDebugMode
         end

         hParams              = Hash.new
         hParams["filename"]  = File.basename(filename)
         hParams["directory"] = @finalDir 
               
         if @isDebugMode == true then
            @logger.debug("Event ONRECEIVENEWFILE #{File.basename(filename)} => #{@finalDir}")
         end
         #@logger.info("Event ONRECEIVENEWFILE #{File.basename(filename)} => #{@finalDir}")

         event.trigger(@entity, "ONRECEIVENEWFILE", hParams, @logger)

         ## ------------------------------------------------
         ## rename the file if AddMnemonic2Name enabled
         ## ret = renameFile(File.basename(filename))
         ## ------------------------------------------------

##         disFile = ""
##         if ret != false then
##            disFile = ret
##         else
##            disFile = File.basename(filename)
##         end

         # disseminate the file to the In-Trays

         if @isNoInTray == false then
            disseminateFile(disFile)
         end     

         return true
      end     
      
   end

   ## -------------------------------------------------------------
   ##
   ## download file using HTTP protocol verb GET 
   ##
   def downloadFile_WebDAV(url)
      if @isDebugMode == true then
         @logger.debug("Downloading #{url} using HTTP(S)")
      end
      
      # http = Curl.get(url)
      http = Curl::Easy.new(url)
      
      # HTTP "insecure" SSL connections (like curl -k, --insecure) to avoid Curl::Err::SSLCACertificateError
      
      http.ssl_verify_peer = false
      
      # Curl::Err::SSLPeerCertificateError ?????
      http.ssl_verify_host = false
      
      http.perform

      ## TO DO : replace in memory file with 
      ## https://www.rubydoc.info/github/taf2/curb/Curl/Easy#download-class_method

      filename = getFilenameFromFullPath(url)
      aFile = File.new(filename, "wb")
      aFile.write(http.body_str)
      aFile.flush
      aFile.close
 
      size = File.size("#{@localDir}/#{File.basename(filename)}")
         
      @logger.info("#{File.basename(filename)} with size #{size} bytes received from #{@entity}")
		
      # File is made available at the interface inbox	
      copyFileToInBox(File.basename(filename), size)
			         
		# Update DEC Inventory
	   setReceivedFromEntity(File.basename(filename), size)
	
      # if deleteFlag is enable delete it from remote directory
      ret = deleteFromEntity(url)

      return true
   end
      
   ## -------------------------------------------------------------
   ##
   ## Download a file from the I/F and local dissemination
   ##
   def downloadFile(filename)
            
      # Quoting the filename to avoid problems with special chars (like #)
      quoted_filename = %Q{"#{filename}"}

      if @protocol == "LOCAL" then
         return downloadFileLocal(filename)
      end
      
      # ------------------------------------------
      if @protocol == "WEBDAV" then
         downloadFile_WebDAV(filename)
         
         if @isNoInTray == false then
            disseminateFile(getFilenameFromFullPath(filename))
         end     
         
         return true
      end
      # ------------------------------------------
      
      # If secure create the sftp client.
      if @ftpserver[:isSecure] == true then
         sftpClient = CTC::SFTPBatchClient.new(@ftpserver[:hostname],
                                             @ftpserver[:port],
                                             @ftpserver[:user],
                                             @ftBatchFilename)
         if @isDebugMode == true then
            sftpClient.setDebugMode
         end
      end
      
      if isSecureMode == true then

         # Right now filenames are specified in full_path
      
#          sftpClient.addCommand("cd #{@ftpserver[:downloadDir]}",
#                                   nil,
#                                   nil)
                                  
         sftpClient.addCommand("get",
                                filename,
                                nil)
         
         # If registered in database we do not delete the file
         # after retrieving it
         if @drivenByDB == false then                       
            sftpClient.addCommand("rm",
                                   filename,
                                   nil)
         end      
      
      
      else
         cmd = self.createNcFtpGet(@ftpserver[:hostname],
                                   @ftpserver[:port],
                                   @ftpserver[:user],
                                   @ftpserver[:password],
                                   "",
                                   filename,
                                   @ftpserver[:isDeleted], 
                                   @isDebugMode)
      end
      
      if @isDebugMode == true and @ftpserver[:isSecure] == false then
         @logger.debug(cmd)
      end
      
      if @ftpserver[:isSecure] == false then
         #output = `#{cmd}`
         retVal = execute(cmd, "DEC_Puller")
#          if $? != 0 then
#             retVal = false
#          else
#             retVal = true
#          end
      else
         retVal = sftpClient.executeAll
         output = sftpClient.output
      end
      
#      if @isDebugMode == true and @ftpserver[:isSecure] == true then
#         puts
#         puts "------------------------------------------"
#         puts "Client FT output is :\n\n"
#         puts output
#         puts "------------------------------------------"
#         puts
#      end
            
      if retVal == false then
         @logger.error("Could not download #{filename} from #{@entity} I/F")
         return false
      else
		   # copy it to the final destination
         
         size = File.size("#{@localDir}/#{File.basename(filename)}")
         
			copyFileToInBox(File.basename(filename), size)
			         
			# update DEC Inventory
			setReceivedFromEntity(File.basename(filename), size)
			
			# if deleteFlag is enable delete it from remote directory
			deleteFromEntity(filename)
         
         @logger.info("#{File.basename(filename)} Downloaded from #{@entity} I/F with size #{size} bytes")

         if size.to_i == 0 then
            return true
         end

         event  = EventManager.new
         
         if @isDebugMode == true then
            event.setDebugMode
         end

         hParams              = Hash.new
         hParams["filename"]  = File.basename(filename)
         hParams["directory"] = @finalDir 
         
         if @isDebugMode == true then      
            @logger.debug("Event ONRECEIVENEWFILE #{File.basename(filename)} => #{@finalDir}")
         end
         #@logger.info("Event ONRECEIVENEWFILE #{File.basename(filename)} => #{@finalDir}")

         event.trigger(@entity, "ONRECEIVENEWFILE", hParams, @logger)
         
         disFile = File.basename(filename)
         
         ## ------------------------------------------------
         ##
         ## rename the file if AddMnemonic2Name enabled
         ## ret = renameFile(File.basename(filename))
         ##
         ## if ret != false then
         ##   disFile = ret
         ## else
         ##   disFile = File.basename(filename)
         ## end
         ##
         ## ------------------------------------------------

         ## disseminate the file to the In-Trays

         if @isNoInTray == false then
            disseminateFile(disFile)
         end     

         return true
      end
   end	
	## -------------------------------------------------------------
	## 
   ## method not used for the time being / configuration addMnemonic not supported
   ##
   def renameFile(file)

      bRename  = false
      bRename2 = false

      # If File is not an Earth Explorer File, perform only the check by Filename
      if CUC::EE_ReadFileName.new(file).isEarthExplorerFile? == true then
         fileType = CUC::EE_ReadFileName.new(file).fileType
         bRename  = @fileSource.isMnemonicAddedToName?(@entity, fileType)
      end

      if bRename == false then
         bRename2 = @fileSource.isMnemonicAddedToName?(@entity, file, false)
      end

      if bRename == true or bRename2 == true then
         
         cmd  = "\\mv -f #{@finalDir}/#{file} #{@finalDir}/#{@entity}_#{file}"
   		if @isDebugMode == true then
            @logger.debug(cmd)
		   end
         
         bRet = execute(cmd, "DEC_Puller")

         if bRet == false then
            msg = "Could not apply AddMnemonic2Name flag for #{file}"
            @logger.error(msg)
         else
            msg = "#{file} has been renamed locally to #{@entity}_#{file}"
            @logger.info(msg)
            return "#{@entity}_#{file}"
         end

      end
      return false
   end
   ## -------------------------------------------------------------
   ##
   ## disseminate file
   ##
   def disseminateFile(file)
      deliverer = FileDeliverer2InTrays.new
	   if @isDebugMode == true then
	      deliverer.setDebugMode
	   end
      deliverer.deliverFile(@entity, @finalDir, file)          
   end
   ## -------------------------------------------------------------
   ##
   ## it deletes a filename which must be a complete URL
   ##
   def deleteFromEntity_HTTP(filename, bForce = false)
      begin
         if @isDebugMode == true then
            @logger.debug("Deleting #{filename}")
         end
         http = Curl.delete(filename)
      rescue Exception => e
         @logger.error(e.to_s)
         if @isDebugMode == true then
            @logger.debug(e.backtrace)
         end
         return false
      end
      msg = "#{filename} deleted at #{@entity}"
      @logger.info(msg)
      return true
   end
   ## -------------------------------------------------------------

	## This method is invoked after placing the files into the operational
	## directory. It deletes the file in the remote Entity if the Config
	## flag DeleteFlag is enable.
	def deleteFromEntity(filename, bForce = false)
	   deleteFlag = @entityConfig.deleteAfterDownload?(@entity)
		# if true proceed to remove the files from the remote I/F
		if deleteFlag == true or bForce == true then
		   if @isDebugMode == true then
			   @logger.debug("DeleteFlag is #{deleteFlag} | ForceFlag is #{bForce} for #{@entity} I/F ")
			end
         
         if @protocol == "LOCAL" then
            @local.deleteFromEntity(filename)
            return
         end

         if @protocol == "WEBDAV" then
            return deleteFromEntity_HTTP(filename)
         end

		   if isSecureMode == true then
			   sftpClient = CTC::SFTPBatchClient.new(@ftpserver[:hostname],
                                             @ftpserver[:port],
                                             @ftpserver[:user],
                                             @ftBatchFilename)
            if @isDebugMode == true then
               sftpClient.setDebugMode
            end
				
# 				sftpClient.addCommand("cd #{@ftpserver[:downloadDir]}",
#                                   nil,
#                                   nil)

				sftpClient.addCommand("rm #{filename}",
                                     nil,
                                     nil)
				
			   retVal = sftpClient.executeAll
            output = sftpClient.output
      
#            if @isDebugMode == true then
#               puts
#               puts "------------------------------------------"
#               puts "Client FT output is :\n\n"
#               puts output
#               puts "------------------------------------------"
#               puts
#            end
			else
           # ncftpget performs the retrieval and delete operation in just one call
           # so additional commands are not required
# 			   @logger.error("DEC_ReceiverFromInterface::deleteFromEntity not implemented for non secure")
# 				exit(99)
			end      
		else
		   if @isDebugMode == true then
			   @logger.debug("DeleteFlag is #{deleteFlag} | ForceFlag is #{bForce} for #{@entity} I/F ")
			end
		end
	end
   ## -------------------------------------------------------------
   ##
   
   ## Returns true if server configuration is secure
   def isSecureMode
      return @ftpserver[:isSecure]
   end
   ## -------------------------------------------------------------
   
   ##
   def filterFullPathFileList(list, forTracking)      
      arrTemp        = Array.new
      arrFiles       = Array.new
      tmpList        = Array.new(list)
      @fileListError = Array.new
      nStart         = list.length
      numFilesToBeRetrieved = 0
      perf           = nil
      # ------------------------------------------

#===============================================================================
# 20170411 - temporal patch for massive ingestion of archives 2015 and 2016
#      
#       # Remove Repeated files found in different directories
#       # and extract filename from the full path
# 
#       perf = measure {
#     
#       tmpList.each{|fullpath|
#          puts fullpath
#          filename = File.basename(fullpath)
#          if arrFiles.include?(filename) == true then
#             list.delete(fullpath)
#             next
#          end
#          arrFiles << filename
#       }
# 
#       } # end of measure
#
#      # ------------------------------------------
#
#      if @isBenchmarkMode == true then
#         puts
#         puts "File Filter Step 1 - Remove repeated files (#{arrFiles.length} elements) of #{nStart}:"
#         puts perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")
#         puts
#         puts "Retrieved #{nStart} files"
#         puts
#      end
#=============================================================================== 

      # ------------------------------------------

      # - Remove files which do not match with filters defined in dcc_config.xml
      # - Remove files which file-type are not defined in the dec_incoming_files.xml
      
      arrDelete = Array.new
      tmpList   = list
      
      nStart    = list.length

      if @isDebugMode == true then
         @logger.debug("Filtering filetypes / #{list.length} items for #{@entity}")
      end

      perf = measure{

      tmpList.each{|fullpath|
         if @isDebugMode == true then
            @logger.debug("Filtering #{fullpath}")
         end
         filename = File.basename(fullpath)
         # Check dcc_config.xml filters
         bFound = false
         @arrFilters.each {|ext|
            if File.fnmatch(ext, filename) == true then
               if @isDebugMode == true then
                  @logger.debug("#{filename} matched filter #{ext}")
               end
               # Here it is checked the file vs dec_incoming_files.xml 
               # file-types and filenames (wildcards)
               if checkFileSource(filename) == false then
                  if @isDebugMode == true then
                     @logger.debug("#{filename} discarded for #{@entity}")
                  end
                  arrDelete << fullpath
               else
                  bFound = true
                  if @isDebugMode == true then
                     @logger.debug("#{filename} matched for #{@entity}")
                  end
               end
               break
            end
		   }

         if bFound == false then
            arrDelete << fullpath
         else
            numFilesToBeRetrieved += 1
         end

         if @pollingSize != nil and numFilesToBeRetrieved >= @pollingSize.to_i then
         	break
         end
      }
                  
      # ------------------------------------------
      
      # ------------------------------------------
      #
      # delete undesired files
      #
      # 2016 patch
             
      if @isDelUnknown == true and arrDelete.uniq.length > 0 then
         
         
         arrDelete.uniq.each{|aFile|
         
            # ----------------------------------------------
            # 20160927
            # Avoid "strange" case of temporal files which in principle should not be listed
            # [ INFO] deleting .S2A_OPER_REP_METARC_PDMC_20160922T140422_V20160922T085940_20160922T091131.xml
            
            if File.basename(aFile).to_s.slice(0,1) == "." then
               @logger.warn("detected temporal file #{File.basename(aFile)} ?!")
               next
            end
         
            # ----------------------------------------------
            
#             @logger.info("deleting unknown #{File.basename(aFile)}")
#             deleteFromEntity(aFile)
         }
      end

      # exit
      
      arrDelete.each{|element| list.delete(element)}
      
      @fileListError = arrDelete

      } # end of measure

      if @isBenchmarkMode == true then
         @logger.info("Filtered in #{@entity} #{nStart}/#{tmpList.length} items (wildcards/file-type): #{perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")}")
      end

      # - Remove files that have already been retrieved/tracked

      if @isNoDB == false then

      if @isDebugMode == true then
         @logger.debug("Filtering files #{@entity} previously recorded within db / #{list.length} items")
      end

      perf = measure{

      arrDelete = Array.new
      arrPolled = Array.new
      tmpList   = list
      nStart    = list.length
      numFilesToBeRetrieved = 0
      
      tmpList.each{|fullpath|
      
         filename = File.basename(fullpath)
         if forTracking == false then
            if hasBeenAlreadyReceived(filename) == true then
               arrDelete << fullpath
               if @isDebugMode == true or true then
                  @logger.info("#{File.basename(filename)} already received from #{@entity}")
               end
                
               ## --------------------------------
               ##
               ## dec_config.xml <DeleteDuplicatedFiles>
               ##
               if DEC::ReadConfigDEC.instance.getDeleteDuplicated == true then
                  @logger.info("removing duplicated #{File.basename(filename)} previously received from #{@entity}")
                  # deleteFromEntity(fullpath, true)
                  deleteFromEntity(fullpath, false)
               else
                  if @isDebugMode == true then
                     @logger.debug("Duplicated files removal is #{DEC::ReadConfigDEC.instance.getDeleteDuplicated} / #{File.basename(filename)} ")
                  end
               end
               ## --------------------------------
            else
               numFilesToBeRetrieved += 1
               arrPolled << fullpath
            end
         else
            if hasBeenAlreadyTracked(filename) == true then
               arrDelete << fullpath
               if @isDebugMode == true then
                  @logger.debug("#{getFilenameFromFullPath(filename)} already tracked from #{@entity}")
               end
            else
               numFilesToBeRetrieved += 1
               arrPolled << fullpath
            end                     
         end
      
         if @pollingSize != nil and numFilesToBeRetrieved >= @pollingSize.to_i then
         	break
         end         
      }
      
   #   exit
      
      arrDelete.each{|element| list.delete(element)}
      
      @fileListError << arrDelete

      list.replace(arrPolled)

      } # end of measure

      if @isDebugMode == true then
         @logger.debug("Filtering Completed for #{@entity}")
      end

      end # end of if @isNoDB

      if @isNoDB == true then
         list = list[0..@pollingSize-1]
      end

      if @isBenchmarkMode == true then
         @logger.info("Filtered in #{@entity} #{nStart}/#{tmpList.length} items in database):#{ perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")}")
      end

      @fileListError = @fileListError.flatten.uniq
      return list
   end
   #-------------------------------------------------------------
      
   # It process the output of ncftpls or sftp "ls" in order to
   # delete rubbish which does not correspond to a file
   # * Returns an array of Filenames
   def filterFileList(output, forTracking)
      arrFile = Array.new
      arrTemp = Array.new
      output  = output.split(/\n/)
      output  = output.uniq
      
      numFilesToBeRetrieved = 0
      
      output.each{|element|
            # Check dcc_config.xml filters
            @arrFilters.each {|ext|
               ext = ext.sub("*", ".*")
               ext = ext.sub("?", ".?")
               if element.match(ext) then
                  fileName = element
                  # Check file source
                  if checkFileSource(fileName) then
                     arrTemp << fileName
                  end
               end
				}
			
      }
      arrTemp = arrTemp.flatten
      arrTemp = arrTemp.uniq
      
      arrTemp.each{|fileName|
         if forTracking == false then
            if hasBeenAlreadyReceived(fileName) == false then
               arrFile << fileName
               numFilesToBeRetrieved += 1
            else
               if @isDebugMode == true then
                  @logger.debug("#{getFilenameFromFullPath(fileName)} already received from #{@entity}")
               end
               #2016 patch
               @logger.info("removing duplicated #{File.basename(fileName)} previously received from #{@entity}")
               # deleteFromEntity(fileName, true)
               deleteFromEntity(fileName, false)
            end
         else
            if hasBeenAlreadyTracked(fileName) == false then
               arrFile << fileName
            else
               if @isDebugMode == true then
                  @logger.debug("#{getFilenameFromFullPath(fileName)} already tracked from #{@entity}")
               end
            end                     
         end
                  
         if @pollingSize != nil and num_filesToRetrieve >= @pollingSize.to_i then
         	break
         end         

         
      }
      arrFile = arrFile.uniq
      return arrFile
   end

	## -------------------------------------------------------------

   ## Check if source for incoming file is the current entity
   ## - fileName (IN): Incoming file basename
   ##
   ## Return
   ## - true if source in dec_incoming_files.xml is current entity
   ## - false otherwise
   def checkFileSource(fileName)

      sources  = @fileSource.getEntitiesSendingIncomingFileName(fileName)

      if sources == nil then
         if @isDebugMode == true then
            @logger.debug("\nNo File-Name matchs with #{fileName} in dec_incoming_files.xml !")
         end
         return false
      else
         return sources.include?(@entity)
      end

#      # Second we perform EE file-type matching in ft_incoming_files
#      
#      # Maybe it would be nice to force every file to extract its file-type but
#      # with LTA files this method will fail  _EX.xml
#      # There would not be a manner to distinguish normal file with its LTA receipt
#
#      if  CUC::EE_ReadFileName.new(fileName).isEarthExplorerFile? == true then
#         fileType = CUC::EE_ReadFileName.new(fileName).fileType
#         sources  = @fileSource.getEntitiesSendingIncomingFileType(fileType)
# 
#         # If Earth Explorer file matchs by file-type      
#         if sources != nil then
#            if sources.include?(@interface.name) == true then
#               return true
#            else
#               return false
#            end
#         else
#            if @isDebugMode == true then
#               puts "\nNo File-Type matchs with #{fileName} in ft_incoming_files.xml ! \n\n"
#            end
#            return false
#         end
#      else
#         return false
#      end
#      return false
   end   
   
   ## -------------------------------------------------------------
   
	## It invokes the method DCC_InventoryInfo::isFileReceived? 
   def hasBeenAlreadyReceived(filename)
      if @isDebugMode == true then
         @logger.debug("checking previous reception of #{filename}")
      end
      arrFiles = ReceivedFile.where(filename: filename)
      if arrFiles == nil then
         #@logger.info("not prev received #{filename}")
         @logger.debug("not prev received #{filename}")
         return false
      end

     # 20170822 temporal fix / if received by any interface is OK since S2PDGS is the entry point

     arrFiles.to_a.each{|file|
          
         if file.interface_id == @interface.id then
            #@logger.info("hasBeenAlreadyReceived: #{filename}")
            @logger.debug("hasBeenAlreadyReceived: #{filename}")
            return true
         end
      }
      return false
   end
   #-------------------------------------------------------------

   
   #-------------------------------------------------------------
   
	# It invokes the method DCC_InventoryInfo::isFileReceived? 
   def hasBeenAlreadyReceived_NOT_WORKING(filename)
      if @isDebugMode == true then
         @logger.debug("checking previous reception of #{filename}")
      end
      arrFiles = ReceivedFile.where(filename: filename).to_a
      
      ## 20170917 PROBABLY RETURN IS NEVER NIL NOW !!! 
            
      if arrFiles == nil then
         @logger.debug("never received #{filename} by anyone")
         return false
      end

      return true
      
      arrFiles.each{|file|
         if file.interface_id == @interface.id then
            #@logger.info("hasBeenAlreadyReceived: #{filename}")
            @logger.debug("hasBeenAlreadyReceived: #{filename}")
            return true
         end
      }
      @logger.info("#{filename} received for other interface than #{@interface.name} / #{@interface.id}")
      return false
   end
   #-------------------------------------------------------------

	# It invokes the method DCC_InventoryInfo::isFileChecked? 
   def hasBeenAlreadyTracked(filename)
      arrFiles = TrackedFile.find_by filename: filename 
      if arrFiles == nil then
         return false
      end

      # arrFiles.each{|file|
         if arrFiles.interface_id == @interface.id then
            return true
         end
      # }
      return false
   end
   #-------------------------------------------------------------

   def setReceivedFromEntity(filename, size = nil)
      if @isNoDB == true then
         return
      end
      
      # ------------------------------------------
      # 20170917 patch to avoid updating the database when received file is empty
      # to allow retransfer from originator 
      if size.to_i == 0 then
         @logger.info("abort setReceivedFromEntity for #{filename} with size #{size} bytes")
         return 
      end
      # ------------------------------------------
            
      receivedFile                = ReceivedFile.new
      
      receivedFile.filename       = filename
      receivedFile.size           = size
      receivedFile.interface      = @interface
      receivedFile.protocol       = @protocol
      receivedFile.reception_date = Time.now
            
      begin
         receivedFile.save!
      rescue Exception => e
         @logger.error(e.to_s)
         @logger.error("DEC_ReceiverFromInterface::setReceivedFromEntity when updating database")
         @logger.error("FATAL ERROR when updating database RECEIVED_FILES #{filename},#{@interface} I/F")
         if @isDebugMode == true then
            @logger.debug(e.backtrace)
         end
         exit(99)
      end
   end
   #-------------------------------------------------------------
   
	# It copies the downloaded file into the Entity Local InBox
	def copyFileToInBox(filename, size)
	   
      if size.to_i == 0 then
         cmd = %Q{\\rm -f \"#{@localDir}/#{filename}"}

         if @isDebugMode == true then
            @logger.debug("Removing #{filename} empty with size 0 received from #{@entity}")
         end
      
         retVal = execute(cmd, "DEC_Puller")
      
         if retVal == false then
            if @isDebugMode == true then
               @logger.debug("#{cmd} Failed !")
            end
            @logger.error("Could not remove empty file #{filename}")
            @logger.warn("#{filename} is still placed in #{@localDir}")
            @logger.info("#{size}")
			   exit(99)
         else
            @logger.error("Removing #{filename} empty with size 0 received from #{@entity}")
         end

         return
      
      end
      
      
      
      cmd = "mv -f #{@localDir}/#{filename} #{@finalDir}"

      if @isDebugMode == true then
         @logger.debug("\nCopying #{filename} received from #{@entity} to #{@finalDir}")
         @logger.debug(cmd)
      end
      
      retVal = execute(cmd, "DEC_Puller")
      
      if retVal == false then
         if @isDebugMode == true then
            @logger.debug("#{cmd} Failed ")
            @logger.debug("Error in DEC_ReceiverFromInterface::copyFileToInBox :-(")
         end
         @logger.error("Could not copy #{filename} into #{@entity} local Inbox")
         @logger.warn("#{filename} is still placed in #{@localDir}")
         # @logger.info("#{size}")
			exit(99)
      end
	end
	# -------------------------------------------------------------
	
	# It removes the file from the temporary directory.
	def deleteFileFromTemp(filename)
	   cmd = %Q{\\rm -f #{@localDir}/#{filename}}
      
      if @isDebugMode == true then
         @logger.debug("Deleting temporary file #{@localDir}/#{filename}")
      end
      
      retVal = execute(cmd, "DEC_Puller")
      
      if retVal == false then
         if @isDebugMode == true then
            @logger.debug("#{cmd} Failed !")
         end
         @logger.error("Could not delete temporary file #{@localDir}/#{filename}")
      end
	end

   # -------------------------------------------------------------
   
	# It creates a file with the list of files of the remote I/F 
	def createContentFile(directory, bDeliver = true)
	   time = Time.now
      now  = time.strftime("%Y%m%dT%H%M%S")
		
#		bRegisterDirContent = @entityConfig.registerDirContent?(@entity)
		
#		if bRegisterDirContent == true then
         @fileList = filterAlreadyCheckedFiles(@fileList, bDeliver)
		   writer    = EntityContentWriter.new(directory)
         if @isDebugMode == true then
		      writer.setDebugMode
         end
         
         writer.writeData(@entity, time, @fileList)
         filename = writer.getFilename
         
         if @isDebugMode == true then
            @logger.debug("Created Content File #{filename}")
         end
   
         if filename == "" then
            @logger.error("Error in DEC_ReceiverFromInterface::createContentFile !!!! =:-O")
            exit(99)
         end
         
         if bDeliver == true then
            deliverer = FileDeliverer2InTrays.new
   
            if @isDebugMode == true then
               deliverer.setDebugMode
               @logger.debug(puts "Creating and Deliver Content File")
            end
            
            deliverer.deliverFile(@entity, directory, filename)
            
         end
#		end
	end
	#-------------------------------------------------------------
   
   # Filter the files already received from I/F
   def filterAlreadyCheckedFiles(arrFiles, bTrack = true)
   
      if @isDebugMode == true and arrFiles.length > 0 then
         @logger.debug("Filtering the Files")
      end
   
      if @isDebugMode == true and arrFiles.length == 0 then
         @logger.debug("No newer Files to be filtered")
      end
      bFirst = true
      filteredFiles = Array.new
      arrFiles.each{|file|
         #afile = file.chop
         afile = file
         if hasBeenAlreadyTracked(File.basename(afile)) == false then
            if bFirst == true
               @logger.debug("Tracking file(s) ...")
               bFirst = false
            end
            @logger.debug(File.basename(afile))
            filteredFiles << afile
            if bTrack == true then
               aTrackedFile            = TrackedFile.new
               aTrackedFile.filename   = File.basename(afile)
               aTrackedFile.interface  = @interface
               aTrackedFile.tracking_date = Time.now
               begin
                  aTrackedFile.save!
               rescue Exception => e
                  @logger.error(e.to_s)
                  @logger.error("DEC_ReceiverFromInterface::filterAlreadyCheckedFiles when updating database")
                  @logger.error("FATAL ERROR when updating database TRACKED_FILES #{File.basename(afile)},#{@interface} I/F")
                  next
                  exit(99)
               end
               @logger.info("#{getFilenameFromFullPath(afile)} Tracked from #{@entity} I/F")
               if @isDebugMode == true then
                  @logger.debug("File #{getFilenameFromFullPath(afile)} has been tracked in DEC-Inventory from #{@entity}")
               end
            end
         else
            if @isDebugMode == true then
               @logger.debug("File #{getFilenameFromFullPath(afile)} already tracked in DEC-Inventory from #{@entity}")
            end
         end
      }
      return filteredFiles
   end
   #-------------------------------------------------------------
   
   ## -----------------------------------------------------------
   
   ## It removes temp directory created with the files. 
   def deleteTempDir      
      Dir.chdir("..")
      cmd = %Q{\\rm -rf #{@localDir} }
      
      if @isDebugMode == true then
         @logger.debug("Removing #{@localDir} ...")
      end
      
      retVal = execute(cmd, "DEC_Puller")
      
      if retVal == false then
         @logger.error("#{cmd} Failed !")
         @logger.error("Error in DEC_ReceiverFromInterface::deleteTempDir :-(")
      end
   end
   ## -----------------------------------------------------------
   
   # It creates a dummy file just to inform new files have been received
   # This method is only invoked if FTPROOT is defined.
   # Mainly this feature is required by RPF/MMPF systems but any Client Project
   # may use it.
   def notifyNewFilesReceived
      system(%Q{touch #{@DCC_NEW_FILES_LOCK}})
   end 
   ## -------------------------------------------------------------

   ## Check if there are some temp dirs for this entity that stayed unremoved from a previous execution
   ## - entity (IN): name of the currently processed entity
   def removePreviousTempDirs
      cmd = %Q{find #{@tmpDir}/ -name '.*\\_#{@entity}' -type d -exec rm -rf {} \\;}

      if @isDebugMode == true then
         @logger.debug("Removing old tmps for #{@entity}: #{cmd}")
      end
      
      execute(cmd, "getFromInterface", false, false, false, false)

   end
   ## -------------------------------------------------------------

end # class

end # module
