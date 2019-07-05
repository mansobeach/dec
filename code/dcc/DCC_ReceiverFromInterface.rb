#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DCC_ReceiverFromInterface class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Collector Component
# 
# CVS: $Id: DCC_ReceiverFromInterface.rb,v 1.29 2008/11/27 13:59:32 decdev Exp $
#
# Module Data Collector Component
# This class polls a given Interface and gets all registered available files
# via FTP or SFTP.
#
#########################################################################

require 'rubygems'
require 'net/ssh'
require 'net/sftp'
require 'timeout'
require 'benchmark'
# require 'Process'

require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'cuc/CommandLauncher'
require 'cuc/EE_ReadFileName'
require 'ctc/ListWriterUnknown'
require 'ctc/FTPClientCommands'
require 'ctc/SFTPBatchClient'
require 'ctc/CheckerInterfaceConfig'
require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadFileSource'
require 'ctc/EventManager'
require 'ctc/LocalInterfaceHandler'
require 'dcc/EntityContentWriter'
require 'dcc/FileDeliverer2InTrays'
require 'dcc/ReadConfigDCC'

# Conditional require driven by --nodb flag
# require 'dbm/DatabaseModel'


module DCC

class DCC_ReceiverFromInterface

   include Benchmark
   include Process
   
   include CUC::DirUtils
   include CTC::FTPClientCommands
   include CUC::CommandLauncher
   
   attr_accessor :isBenchmarkMode

   #-------------------------------------------------------------

   # Class constructor.
   # * entity (IN):  Entity textual name (i.e. FOS)
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
      loggerFactory = CUC::Log4rLoggerFactory.new("DCC_ReceiverFromInterface", "#{@@configDirectory}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in DCC_ReceiverFromInterface::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{@@configDirectory}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end

      checker     = CTC::CheckerInterfaceConfig.new(entity, true, false)
      
      if @isDebugMode == true then
         checker.setDebugMode
      end
      
      retVal      = checker.check

      if retVal == true then
         if @isDebugMode == true then
            puts "#{entity} I/F is configured correctly\n"
	      end
      else
         raise "\nError in DCC_ReceiverFromInterface::initialize :-(\n\n" + "\n\n#{entity} I/F is not configured correctly\n\n"
      end
     
      @entityConfig     = CTC::ReadInterfaceConfig.instance
      @protocol         = @entityConfig.getProtocol(@entity)
      @finalDir         = @entityConfig.getIncomingDir(@entity)
      checkDirectory(@finalDir)
      @ftpserver        = @entityConfig.getFTPServer4Receive(@entity)
      @pollingSize      = @entityConfig.getTXRXParams(@entity)[:pollingSize]
      
      # -------------------------------------
      # 2016 currently hardcoded number of files handled on each iteration in case
      # it is not defined in the configuration
      if @pollingSize == nil then
         @pollingSize      = 150
      else
         @pollingSize = @pollingSize.to_i
      end
      # -------------------------------------      
            
      @parallelDownload = @entityConfig.getTXRXParams(@entity)[:parallelDownload]      
                        
      @fileSource       = CTC::ReadFileSource.instance

      if @isNoDB == false then
         # require 'dbm/DatabaseModel'
         require 'dec/DEC_DatabaseModel'
         @interface        = Interface.find_by_name(@entity)
         if @interface == nil then
            raise "\n#{@entity} is not a registered I/F ! :-(" + "\ntry registering it with addInterfaces2Database.rb tool !  ;-) \n\n"
         end
      end

      removePreviousTempDirs

      @dccConfig   = DCC::ReadConfigDCC.instance
      @arrFilters  = @dccConfig.getIncomingFilters

      @satPrefix   = DCC::ReadConfigDCC.instance.getSatPrefix
      @prjName     = DCC::ReadConfigDCC.instance.getProjectName
      @prjID       = DCC::ReadConfigDCC.instance.getProjectID
      @mission     = DCC::ReadConfigDCC.instance.getMission
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "DCC_ReceiverFromInterface debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Check whether there are new files waiting.
   # * Returns true if there are new files availables.
   # * Otherwise returns false.
   def check4NewFiles(forCheck = false)
      cmd   = ""
      perf  = ""
      list  = nil
            
      case @protocol
         when "FTP"
               
            if @isDebugMode == true then
               puts "I/F #{@entity} is non secure mode / #{@protocol}"
            end

            perf = measure { list = getNonSecureFileList( @ftpserver[:isPassive]) }


         when "SFTP"
            
            if @isDebugMode == true then
               puts "I/F #{@entity} requires secure mode / #{@protocol}"
            end

            perf = measure { list = getSecureFileList }
            
         when "FTPS"  
            
            puts "FTPS not integrated yet from ALGK"
            puts
            puts "DCC_ReceiverFromInterface::check4NewFiles"
            puts
            exit(99)
            
            
         when "LOCAL"
         
            if @isDebugMode == true then
               puts "I/F #{@entity} does not use network / #{@protocol}"
            end

          
            begin
               
               @local = CTC::LocalInterfaceHandler.new(@entity, true, false, @dccConfig.getDownloadDirs)
               
               if @isDebugMode then 
                  @local.setDebugMode
               end
                  
               perf = measure { list = @local.getLocalList }      
            
            rescue Exception => e
                  puts e
                  exit (99)
            end     
            
      end
           
#       puts "+++++++++++++++++++++++++++++++++"
#       puts list
#       puts list.length
#       puts list.uniq.length
#       puts "+++++++++++++++++++++++++++++++++"
#       exit

      if @isBenchmarkMode == true then
         puts
         puts "Retrieved File-Tree structure from server:"
         puts perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")
         puts
         puts "Retrieved #{list.length} files to be filtered"
         puts
      end

      perf = measure { @fileList = filterFullPathFileList(list, forCheck) }
            
      n = @fileList.length

      if @isBenchmarkMode == true then
         puts
         puts "Total Filtering File-Tree (filters + database) (#{list.length} elements) :"
         puts perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")
         puts
         puts "Retrieved #{n} files"
         puts
      end

      if n > 0 then
         return true
      else
         return false
      end

   end
   #-------------------------------------------------------------
   
   def getWildNonSecureList(path)

      if @isDebugMode == true then
         puts
         puts "Wild-search enabled for #{path}"
         puts
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
            puts "Found #{newFile}"
         end

         @newArrFile << newFile
      }
      return
   end
   # -------------------------------------------------------------

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
            puts "FTP #{host}:#{port} #{user}:#{pass} | passive = #{bPassive}"
         end
         @ftp = Net::FTP.new(host)
         @ftp.login(user, pass)
         @ftp.passive = bPassive
      rescue Exception => e
         puts
         puts e.to_s
         puts "Unable to connect to #{host}"
         @logger.error("#{@entity}: #{e.to_s}")
         @logger.error("#{@entity}: Unable to connect to #{host}")
         @logger.error("Could not poll #{@entity} I/F")
         puts
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
            puts "Polling #{@remotePath}"
         end
         
         begin
            @ftp.chdir(@remotePath)
         rescue Exception => e
            @ftp.chdir("/")
#             puts
#             puts "Error trying to reach #{@remotePath}"
#             puts e.to_s
#             puts
            next
         end

         @pwd = @ftp.pwd
         
         begin         
            entries = @ftp.list
         rescue Exception => e
            puts "Failed to get list of files / FTP passive mode is #{@ftp.passive}"
            puts e.to_s
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
   # -------------------------------------------------------------

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
            puts "Found #{%Q{#{@pwd}/#{element}}}"
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
         puts e.to_s
      end

      sleep(0.4)

      begin
         @ftp.noop
      rescue Exception => e
         puts e.to_s
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
         puts e.to_s
      end
      @depthLevel = @depthLevel - 1   
   end
   #-------------------------------------------------------------

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
         puts
         puts e.to_s
         puts "Unable to connect to #{host}"
         @logger.error("#{@entity}: #{e.to_s}")
         @logger.error("#{@entity}: Unable to connect to #{host}")
         @logger.error("Could not poll #{@entity} I/F")
         puts
         exit(99)
      end

      arrElements = @ftpserver[:arrDownloadDirs]

      arrElements.each{|element|
         @remotePath = element[:directory]
         @maxDepth   = element[:depthSearch]
         begin

            exploreSecureTree(@remotePath, 0)

         rescue Exception => e
            puts
            puts "Unable to explore directory tree from : #{@remotePath} :-("
            @logger.warn("#{e.class.to_s.upcase} : Unable to explore directory tree from : #{@remotePath}")
            puts "-> Skipping Directory.."
            puts "-> Error : #{e.message}"
            puts e.backtrace
            puts
            next
         end
      }

      @ftp.session.close

      return @newArrFile
   end
   #-------------------------------------------------------------
   
   # Method that recursively list the files in the directoy corresponding to the given handle.
   def exploreSecureTree(path, depth)
      req = Array.new
      begin
        Timeout.timeout(300) do
            handle = @ftp.opendir!(path)
            req = @ftp.readdir!(handle)
            # req = @ftp.readdir(handle)
            # @sleep(10)
            # @puts "PEDO"
            # puts req.length
            @ftp.close!(handle)
        end
      # rescue Net::SFTP::StatusException => status_e
      rescue Exception => status_e
         # @logger.warn("StatusException : Unable to list #{@remotePath} (#{status_e.description})")
         @logger.error("StatusException : Unable to list #{@remotePath} (#{status_e.message})")
         puts status_e.backtrace
         puts "Could not Access to directory : #{path} :-("
         if @isDebugMode == true then
            puts "-> Skipping entry.."
            puts "-> Error : #{status_e.message}"
            puts status_e.backtrace
            puts "shit!"
            # puts "-> Error : #{status_e.description}"
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
               puts "Found #{fullFile}"
            end
            @newArrFile << fullFile
            next         
         end 

         # Make recursive call if the item is a directory
         if item.directory? and depth < @maxDepth then
            exploreSecureTree("#{path}/#{item.name}", depth+1)
         end
  
      }


      # sleep(10)
      # exit


   end
   #-------------------------------------------------------------

   def receiveAllFilesParallel
      currentDir = Dir.pwd
      checkDirectory(@localDir)
      Dir.chdir(@localDir)
      puts "Downloading file(s) ..." # into #{@localDir} ..."
      @retValFilesReceived    = true
      @atLeast1FileReceived   = false
      listFiles               = Array.new(@fileList)
      
      arrSent  = Array.new
      
      loop do
         break if listFiles.empty?
         1.upto(@parallelDownload) {|i|
            break if listFiles.empty?
            # puts "Download process #{i}"
            file = listFiles.shift
            arrSent << file
            puts File.basename(file)
            fork{
               #@logger.info("Forking #{File.basename(file)}")
            	ret = downloadFile(file)
               if ret == false then
                  #@logger.error("Forked Failed to download #{File.basename(file)}")
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
      puts "\n"

      # Create new files received lock file
      if @bCreateNewFilesLock == true and @fileList.length >0 and @atLeast1FileReceived == true
         notifyNewFilesReceived
      end

      Dir.chdir(currentDir)
      return @retValFilesReceived   
   end
   #-------------------------------------------------------------

   # Get all Files found in the previous polling to the I/F.
   # All files are left in a temp local directory
   # $DCC_TMP/<current_time>_entity
   def receiveAllFiles
   
      if @parallelDownload > 1 then
         return receiveAllFilesParallel
      end
   
      currentDir = Dir.pwd
      checkDirectory(@localDir)
      Dir.chdir(@localDir)
      puts "Downloading file(s) ..." # into #{@localDir} ..."
      @retValFilesReceived  = true
      @atLeast1FileReceived = false
		
      
      @fileList.each{|file|
      
            
		         puts File.basename(file)
                
			      ret = downloadFile(file)
            
               if ret == false then
                  @retValFilesReceived  = false
               else
                  @atLeast1FileReceived = true
               end
		
      
      }
      
      deleteTempDir
      
#		createContentFile(@finalDir)
      puts "\n"

      # Create new files received lock file
      if @bCreateNewFilesLock == true and @fileList.length >0 and @atLeast1FileReceived == true
         notifyNewFilesReceived
      end

      Dir.chdir(currentDir)
      return @retValFilesReceived
   end
   #-------------------------------------------------------------
   
	# createListFile
	def createListFile(directory, bDeliver = true)
	   createContentFile(directory, bDeliver)
	end
	#-------------------------------------------------------------
	
   def createReportFile(directory, bDeliver = true, bForceCreation = false)
	   bFound      = false
      bIsEnabled  = false
      fileType    = ""
      desc        = ""
      time        = Time.now
      now         = time.strftime("%Y%m%dT%H%M%S")
               
      arrReports = @dccConfig.getReports

      bIsEnabled = false

      #-----------------------------------------------------
      # Create RetrievedFiles Report

      if @fileList.length > 0 then

         arrReports.each{|aReport|
            if aReport[:name] == "RETRIEVEDFILES" then
               bFound      = true
               fileType    = aReport[:fileType]
               desc        = aReport[:desc]
               bIsEnabled  = aReport[:enabled]
            end
         }

         if bForceCreation == true and bFound == false then
            puts "Explicit Request creation of RetrievedFiles Report"
            puts "Warning: RetrievedFiles Report is not configured in dcc_config.xml :-|"
            puts
            return
         end

         if bFound == true and bIsEnabled == true then

	         writer = CTC::DeliveryListWriter.new(directory, false, fileType)

            if @isDebugMode == true then
		         writer.setDebugMode
            end

            writer.setup(@satPrefix, @prjName, @prjID, @mission)
            writer.writeData(@entity, time, @fileList)
      
            filename = writer.getFilename
         
            puts "Created Report File #{filename}"
   
            if filename == "" then
               puts "Error in DCC_ReceiverFromInterface::createReportFile !!!! =:-O \n\n"
               exit(99)
            end
         
            if bDeliver == true then
               deliverer = DCC::FileDeliverer2InTrays.new
   
               if @isDebugMode == true then
                  deliverer.setDebugMode
               end
               puts "Creating and Deliver Report File"
               deliverer.deliverFile(directory, filename)
               puts
            end
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
            puts "Explicit Request creation of RetrievedFiles Report"
            puts "Warning: RetrievedFiles Report is not configured in dcc_config.xml :-|"
            puts
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
         
            puts "Created Report File #{filename}"
   
            if filename == "" then
               puts "Error in DCC_ReceiverFromInterface::createReportFile !!!! =:-O \n\n"
               exit(99)
            end
         
            if bDeliver == true then
               deliverer = DCC::FileDeliverer2InTrays.new
   
               if @isDebugMode == true then
                  deliverer.setDebugMode
               end
               puts "Creating and Deliver Report File"
               deliverer.deliverFile(directory, filename)
               puts
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
   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true
      
      if !ENV['DCC_TMP'] and !ENV['DEC_TMP'] then
         puts "\nDCC_TMP environment variable not defined !\n"
         bDefined = false
      end
      
      if ENV['DEC_TMP'] then
         @tmpDir         = %Q{#{ENV['DEC_TMP']}}  
      else
         @tmpDir         = %Q{#{ENV['DCC_TMP']}}  
      end        
      
      configDir = nil
         
      if ENV['DEC_CONFIG'] then
         configDir         = %Q{#{ENV['DEC_CONFIG']}}  
      else
         configDir         = %Q{#{ENV['DCC_CONFIG']}}  
      end        
            
      @@configDirectory = configDir
     
      if bDefined == false then
         puts "\nError in DCC_ReceiverFromInterface::checkModuleIntegrity :-(\n\n"
         exit(99)
      end
                  
      # @@FileLog = %Q{#{ENV['DCC_TMP']}/ft_incoming.log}   # should this line not be removed ? (rell)
      
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
   #-------------------------------------------------------------
   
   def downloadFileLocal(filename)
      retVal = @local.downloadFile(filename)
      
       if retVal == false then
         puts "Failed to download #{filename}"
         @logger.error("Could not download #{filename} from #{@entity} I/F")
         return false
      else
		   # copy it to the final destination
         
         size = File.size("#{@localDir}/#{File.basename(filename)}")
         
         # @logger.debug("#{File.basename(filename)} received with size #{size} bytes")
         # @logger.info("#{File.basename(filename)} received with size #{size} bytes")
			
         copyFileToInBox(File.basename(filename), size)
			         
			# update DCC Inventory
			setReceivedFromEntity(File.basename(filename), size)
			
			# if deleteFlag is enable delete it from remote directory
         if @protocol == "LOCAL" then
            @local.deleteFromEntity(filename)
         else
   			deleteFromEntity(filename)
         end      
         
         @logger.info("#{File.basename(filename)} Downloaded from #{@entity} I/F with size #{size} bytes")

         event  = CTC::EventManager.new
         
         if @isDebugMode == true then
            event.setDebugMode
         end

         arrParam             = Array.new
         hParam1              = Hash.new
         hParam1["filename"]  = File.basename(filename) 

         hParam2              = Hash.new
         hParam2["directory"] = @finalDir 
      
         arrParam << hParam1
         arrParam << hParam2
         
         @logger.debug("Event ONRECEIVENEWFILE #{File.basename(filename)} => #{@finalDir}")
         #@logger.info("Event ONRECEIVENEWFILE #{File.basename(filename)} => #{@finalDir}")

         event.trigger(@entity, "ONRECEIVENEWFILE", arrParam, nil, @logger)

         # rename the file if AddMnemonic2Name enabled
         ret = renameFile(File.basename(filename))

         disFile = ""
         if ret != false then
            disFile = ret
         else
            disFile = File.basename(filename)
         end

         # disseminate the file to the In-Trays

         if @isNoInTray == false then
            disseminateFile(disFile)
         end     

         return true
      end     
      
   end
   #-------------------------------------------------------------
   
   # Download a file from the I/F
   def downloadFile(filename)
      
#      puts filename
#      exit
      
      # Quoting the filename to avoid problems with special chars (like #)
      quoted_filename = %Q{"#{filename}"}

      
      if @protocol == "LOCAL" then
         return downloadFileLocal(filename)
      end
      
      
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
         puts cmd
      end
      
      if @ftpserver[:isSecure] == false then
         #output = `#{cmd}`
         retVal = execute(cmd, "getFromInterface")
#          if $? != 0 then
#             retVal = false
#          else
#             retVal = true
#          end
      else
         retVal = sftpClient.executeAll
         output = sftpClient.output
      end
      
      if @isDebugMode == true and @ftpserver[:isSecure] == true then
         puts
         puts "------------------------------------------"
         puts "Client FT output is :\n\n"
         puts output
         puts "------------------------------------------"
         puts
      end
            
      if retVal == false then
         puts "Failed to download #{filename}"
         @logger.error("Could not download #{filename} from #{@entity} I/F")
         return false
      else
		   # copy it to the final destination
         
         size = File.size("#{@localDir}/#{File.basename(filename)}")
         
			copyFileToInBox(File.basename(filename), size)
			         
			# update DCC Inventory
			setReceivedFromEntity(File.basename(filename), size)
			
			# if deleteFlag is enable delete it from remote directory
			deleteFromEntity(filename)
         
         @logger.info("#{File.basename(filename)} Downloaded from #{@entity} I/F with size #{size} bytes")

         if size.to_i == 0 then
            return true
         end

         event  = CTC::EventManager.new
         
         if @isDebugMode == true then
            event.setDebugMode
         end

         arrParam             = Array.new
         hParam1              = Hash.new
         hParam1["filename"]  = File.basename(filename) 

         hParam2              = Hash.new
         hParam2["directory"] = @finalDir 
      
         arrParam << hParam1
         arrParam << hParam2
         
         @logger.debug("Event ONRECEIVENEWFILE #{File.basename(filename)} => #{@finalDir}")
         #@logger.info("Event ONRECEIVENEWFILE #{File.basename(filename)} => #{@finalDir}")

         event.trigger(@entity, "ONRECEIVENEWFILE", arrParam, @logger)

         # rename the file if AddMnemonic2Name enabled
         ret = renameFile(File.basename(filename))

         disFile = ""
         if ret != false then
            disFile = ret
         else
            disFile = File.basename(filename)
         end

         # disseminate the file to the In-Trays

         if @isNoInTray == false then
            disseminateFile(disFile)
         end     

         return true
      end
   end	
	#-------------------------------------------------------------
	
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
            puts cmd
		   end
         
         bRet = execute(cmd, "getFromInterface")

         if bRet == false then
            msg = "Could not apply AddMnemonic2Name flag for #{file}"
            @logger.error(msg)
            puts "#{msg} ! :-("
         else
            msg = "#{file} has been renamed locally to #{@entity}_#{file}"
            puts "#{msg}"
            @logger.info(msg)
            return "#{@entity}_#{file}"
         end

      end
      return false
   end
   #-------------------------------------------------------------

   def disseminateFile(file)
      deliverer = DCC::FileDeliverer2InTrays.new
	   if @isDebugMode == true then
	      deliverer.setDebugMode
	   end
	   
      deliverer.deliverFile(@finalDir, file)
               
   end
   #-------------------------------------------------------------

	# This method is invoked after placing the files into the operational
	# directory. It deletes the file in the remote Entity if the Config
	# flag DeleteFlag is enable.
	def deleteFromEntity(filename, bForce = false)
	   deleteFlag = @entityConfig.deleteAfterDownload?(@entity)
		# if true proceed to remove the files from the remote I/F
		if deleteFlag == true or bForce == true then
		   if @isDebugMode == true then
			   puts "DeleteFlag is #{deleteFlag} | ForceFlag is #{bForce} for #{@entity} I/F "
			end

         
         if @protocol == "LOCAL" then
            @local.deleteFromEntity(filename)
            return
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
      
            if @isDebugMode == true then
               puts
               puts "------------------------------------------"
               puts "Client FT output is :\n\n"
               puts output
               puts "------------------------------------------"
               puts
            end
			else
           # ncftpget performs the retrieval and delete operation in just one call
           # so additional commands are not required
# 			   puts "DCC_ReceiverFromInterface::deleteFromEntity not implemented for non secure"
# 				exit(99)
			end      
		else
		   if @isDebugMode == true then
			   puts "DeleteFlag is #{deleteFlag} | ForceFlag is #{bForce} for #{@entity} I/F "
			end
		end
	end
   #-------------------------------------------------------------
   
   # Returns true if ftp server configuration is secure
   def isSecureMode
      return @ftpserver[:isSecure]
   end
   #-------------------------------------------------------------
   
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
      # - Remove files which file-type are not defined in the ft_incoming_files.xml
      
      arrDelete = Array.new
      tmpList   = list
      
      nStart    = list.length

      @logger.info("Filtering filetypes / #{list.length} items for #{@entity}")

      perf = measure{

      tmpList.each{|fullpath|
         filename = File.basename(fullpath)
         # Check dcc_config.xml filters
         bFound = false
         @arrFilters.each {|ext|
            if File.fnmatch(ext, filename) == true then
               if @isDebugMode == true then
                  puts
                  puts "#{filename} matched filter #{ext}"
               end
               # Here it is checked the file vs ft_incoming_files.xml 
               # file-types and filenames (wildcards)
               if checkFileSource(filename) == false then
                  if @isDebugMode == true then
                     puts "#{filename} discarded for #{@entity}"
                  end
                  arrDelete << fullpath
               else
                  bFound = true
                  if @isDebugMode == true then
                     puts "#{filename} matched for #{@entity}"
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
      
      if @isDebugMode == true then
         puts
      end
            
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
               @logger.info("detected temporal file #{File.basename(aFile)} ?!")
               next
            end
         
            # ----------------------------------------------
            
#             puts "deleting #{File.basename(aFile)}"
#             @logger.info("deleting unknown #{File.basename(aFile)}")
#             deleteFromEntity(aFile)
         }
      end

      # exit
      
      arrDelete.each{|element| list.delete(element)}
      
      @fileListError = arrDelete

      } # end of measure

      if @isBenchmarkMode == true then
         puts
         puts "Time required to filter #{nStart}/#{tmpList.length} elements (config wildcards/file-type):"
         puts perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")
         puts
      end

      # - Remove files that have already been retrieved/tracked

      if @isNoDB == false then

      @logger.info("Filtering files #{@entity} previously recorded within db / #{list.length} items")

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
 
               puts "removing duplicated #{File.basename(filename)} previously received from #{@entity}"
               @logger.info("removing duplicated #{File.basename(filename)} previously received from #{@entity}")
               # deleteFromEntity(fullpath, true)
               deleteFromEntity(fullpath, false)
            else
               numFilesToBeRetrieved += 1
               arrPolled << fullpath
            end
         else
            if hasBeenAlreadyTracked(filename) == true then
               arrDelete << fullpath
               if @isDebugMode == true then
                  puts "#{getFilenameFromFullPath(filename)} already tracked from #{@entity}"
               end
            else
               numFilesToBeRetrieved += 1
               arrPolled << fullpath
            end                     
         end
      
         if @pollingSize != nil and numFilesToBeRetrieved >= @pollingSize.to_i then
         	break
#          else
#             puts
#             puts @pollingSize
#             puts numFilesToBeRetrieved
#             puts
         end         
      }
      
   #   exit
      
      arrDelete.each{|element| list.delete(element)}
      
      @fileListError << arrDelete

      list.replace(arrPolled)

      } # end of measure

      @logger.info("Filtering Completed for #{@entity}")

      end # end of if @isNoDB

      if @isNoDB == true then
         list = list[0..@pollingSize-1]
      end

      if @isBenchmarkMode == true then
         puts
         puts "Time required to filter #{nStart}/#{tmpList.length} elements already Tracked/Received files (database):"
         puts perf.format("Real Time %r | Total CPU: %t | User CPU: %u | System CPU: %y")
         puts
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
                  puts "#{getFilenameFromFullPath(fileName)} already received from #{@entity}"
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
                  puts "#{getFilenameFromFullPath(fileName)} already tracked from #{@entity}"
               end
            end                     
         end
         
#          puts "PEDO"
#          exit
         
         if @pollingSize != nil and num_filesToRetrieve >= @pollingSize.to_i then
         	break
         end         

         
      }
      arrFile = arrFile.uniq
      return arrFile
   end

   #-------------------------------------------------------------
   
	# It invokes the method DCC_InventoryInfo::isFileReceived? 
   def hasBeenAlreadyReceived(filename)
      puts "checking previous reception of #{filename}"
      arrFiles = ReceivedFile.where(filename: filename)
      if arrFiles == nil then
         #@logger.info("not prev received #{filename}")
         @logger.debug("not prev received #{filename}")
         return false
      end

     # 20170822 temporal fix / if received by any interface is OK since S2PDGS is the entry point
     
     
#     puts
#     puts arrFiles
#     puts arrFiles.filename
#     puts arrFiles.interface_id
#     puts
#     
#     return true

     arrFiles.to_a.each{|file|
     
         # puts file.interface_id
     
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
      
      puts "checking previous reception of #{filename}"
      
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
         puts
         puts e.to_s
         @logger.error("DCC_ReceiverFromInterface::setReceivedFromEntity when updating database")
         @logger.error("FATAL ERROR when updating database RECEIVED_FILES #{filename},#{@interface} I/F")
         puts
         exit(99)
      end
   end
   #-------------------------------------------------------------
   
	# It copies the downloaded file into the Entity Local InBox
	def copyFileToInBox(filename, size)
	   
      if size.to_i == 0 then
         cmd = %Q{\\rm -f \"#{@localDir}/#{filename}"}

         if @isDebugMode == true then
            puts "\nRemoving #{filename} empty with size 0 received from #{@entity}"
            puts cmd
            puts
         end
      
         retVal = execute(cmd, "getFromInterface")
      
         if retVal == false then
            if @isDebugMode == true then
               puts "#{cmd} Failed !"
               puts "\nError in DCC_ReceiverFromInterface::copyFileToInBox :-(\n"
            else
               puts "\nError when removing empty file #{filename} :-("
            end
            @logger.error("Could not remove empty file #{filename}")
            @logger.warn("#{filename} is still placed in #{@localDir}")
            @logger.info("#{size}")
			   puts "Could not remove empty file #{filename}"
			   puts
			   exit(99)
         else
            @logger.error("Removing #{filename} empty with size 0 received from #{@entity}")
         end

         return
      
      end
      
      #cmd = %Q{\\cp #{@localDir}/#{filename} #{@finalDir}/}
      cmd = %Q{\\mv -f \"#{@localDir}/#{filename}\" #{@finalDir}/}

      if @isDebugMode == true then
         puts "\nCopying #{filename} received from #{@entity} to #{@finalDir}"
         puts cmd
         puts
      end
      
      retVal = execute(cmd, "getFromInterface")
      
      if retVal == false then
         if @isDebugMode == true then
            puts "#{cmd} Failed !"
            puts "\nError in DCC_ReceiverFromInterface::copyFileToInBox :-(\n"
         else
            puts "\nError when copying file to #{@entity} local Inbox :-("
         end
         @logger.error("Could not copy #{filename} into #{@entity} local Inbox")
         @logger.warn("#{filename} is still placed in #{@localDir}")
         @logger.info("#{size}")
			puts "Could not copy #{filename} into #{@finalDir}"
			puts
			exit(99)
      end
	end
	#-------------------------------------------------------------
	
	# It removes the file from the temporary directory.
	def deleteFileFromTemp(filename)
	   cmd = %Q{\\rm -f #{@localDir}/#{filename}}
      
      if @isDebugMode == true then
         puts "\nDeleting temporary file #{@localDir}/#{filename}"
         puts cmd
         puts
      end
      
      retVal = execute(cmd, "getFromInterface")
      
      if retVal == false then
         if @isDebugMode == true then
            puts "#{cmd} Failed !"
            puts "\nError in DCC_ReceiverFromInterface::deleteFileFromTemp :-(\n"
         else
            puts "\nError when deleting temporary file #{@localDir}/#{filename}"
         end
         @logger.error("Could not delete temporary file #{@localDir}/#{filename}")
			puts "Could not delete temporary file #{@localDir}/#{filename} :-("
			puts
      end
	end
	#-------------------------------------------------------------

   # Check if source for incoming file is the current entity
   # - fileName (IN): Incoming file basename
   #
   # Return
   # - true if source in ft_incoming_files.xml is current entity
   # - false otherwise
   def checkFileSource(fileName)

      # puts "DCC_ReceiverFromEntity::checkFileSource(#{fileName})"
      
      
      # First we try perform filename matching vs wildcards in ft_incoming_files 
      sources  = @fileSource.getEntitiesSendingIncomingFileName(fileName)

      # puts sources

      if sources == nil then
         if @isDebugMode == true then
            puts "\nNo File-Name matchs with #{fileName} in ft_incoming_files.xml ! \n"
         end
      else
         return sources.include?(@entity)
      end

      # Second we perform EE file-type matching in ft_incoming_files
      
      # Maybe it would be nice to force every file to extract its file-type but
      # with LTA files this method will fail  _EX.xml
      # There would not be a manner to distinguish normal file with its LTA receipt

      if  CUC::EE_ReadFileName.new(fileName).isEarthExplorerFile? == true then
         fileType = CUC::EE_ReadFileName.new(fileName).fileType
         sources  = @fileSource.getEntitiesSendingIncomingFileType(fileType)
 
         # If Earth Explorer file matchs by file-type      
         if sources != nil then
            if sources.include?(@interface.name) == true then
               return true
            else
               return false
            end
         else
            if @isDebugMode == true then
               puts "\nNo File-Type matchs with #{fileName} in ft_incoming_files.xml ! \n\n"
            end
            return false
         end
      else
         return false
      end
      return false
   end   
   #-------------------------------------------------------------
   
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
         
         puts "Created Content File #{filename}"
   
         if filename == "" then
            puts "Error in DCC_ReceiverFromInterface::createContentFile !!!! =:-O \n\n"
            exit(99)
         end
         
         if bDeliver == true then
            deliverer = DCC::FileDeliverer2InTrays.new
   
            if @isDebugMode == true then
               deliverer.setDebugMode
            end
            puts "Creating and Deliver Content File"
            deliverer.deliverFile(directory, filename)
            puts
         end
#		end
	end
	#-------------------------------------------------------------
   
   # Filter the files already received from I/F
   def filterAlreadyCheckedFiles(arrFiles, bTrack = true)
   
      if @isDebugMode == true and arrFiles.length > 0 then
         puts "--------------------------"
         puts
         puts "Filtering the Files"
         puts
      end
   
      if @isDebugMode == true and arrFiles.length == 0 then
         puts
         puts "No newer Files to be filtered"
      end
      bFirst = true
      filteredFiles = Array.new
      arrFiles.each{|file|
         #afile = file.chop
         afile = file
         if hasBeenAlreadyTracked(File.basename(afile)) == false then
            if bFirst == true
               puts "Tracking file(s) ..."
               bFirst = false
            end
            puts File.basename(afile)
            filteredFiles << afile
            if bTrack == true then
               aTrackedFile            = TrackedFile.new
               aTrackedFile.filename   = File.basename(afile)
               aTrackedFile.interface  = @interface
               aTrackedFile.tracking_date = Time.now
               begin
                  aTrackedFile.save!
               rescue Exception => e
                  puts
                  puts e.to_s
                  puts
                  @logger.error("DCC_ReceiverFromInterface::filterAlreadyCheckedFiles when updating database")
                  @logger.error("FATAL ERROR when updating database TRACKED_FILES #{File.basename(afile)},#{@interface} I/F")
                  next
                  exit(99)
               end
               @logger.info("#{getFilenameFromFullPath(afile)} Tracked from #{@entity} I/F")
               if @isDebugMode == true then
                  puts "File #{getFilenameFromFullPath(afile)} has been tracked in DCC-Inventory from #{@entity}"
               end
            end
         else
            if @isDebugMode == true then
               puts "File #{getFilenameFromFullPath(afile)} already tracked in DCC-Inventory from #{@entity}"
            end
         end
      }
      if bFirst == false then
         puts
      end
      return filteredFiles
   end
   #-------------------------------------------------------------
   #-------------------------------------------------------------
   # It removes temp directory created with the files. 
   def deleteTempDir      
      Dir.chdir("..")
      cmd = %Q{\\rm -rf #{@localDir} }
      
      if @isDebugMode == true then
         puts "\nRemoving #{@localDir} ..."
         puts cmd
      end
      
      retVal = execute(cmd, "getFromInterface")
      
      if retVal == false then
         puts "#{cmd} Failed !"
         puts "\nError in DCC_ReceiverFromInterface::deleteTempDir :-(\n\n"
      end
   end
   #-------------------------------------------------------------
   
   # It creates a dummy file just to inform new files have been received
   # This method is only invoked if FTPROOT is defined.
   # Mainly this feature is required by RPF/MMPF systems but any Client Project
   # may use it.
   def notifyNewFilesReceived
      system(%Q{touch #{@DCC_NEW_FILES_LOCK}})
   end 
   #-------------------------------------------------------------

   # Check if there are some temp dirs for this entity that stayed unremoved from a previous execution
   # - entity (IN): name of the currently processed entity
   def removePreviousTempDirs
      cmd = %Q{find #{@tmpDir}/ -name '.*\\_#{@entity}' -type d -exec rm -rf {} \\;}

      if @isDebugMode == true then
         puts "\nRemoving previous temporary dirs if any..."
         puts cmd
      end
      @logger.info("Removing old tmps for #{@entity}: #{cmd}")
      execute(cmd, "getFromInterface", false, false, false, false)

   end
   #-------------------------------------------------------------

end # class

end # module
