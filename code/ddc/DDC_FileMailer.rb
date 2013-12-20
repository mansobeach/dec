#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DDC_FileMailer class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# CVS: $Id: DDC_FileMailer.rb,v 1.13 2008/07/03 11:38:26 decdev Exp $
#
# Module Data Distributor Component
# This class delivers methods for sending files to entities using SMTP.
# The files are sent through attachments in a mail.
#
#########################################################################

require 'fileutils'

require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadMailConfig'
require 'ctc/CheckerMailConfig'
require 'ctc/FileMailer'
# require 'dbm/DatabaseModel'
require 'ddc/ReadConfigDDC'


module DDC

class DDC_FileMailer

   include CUC::DirUtils
   include FileUtils::NoWrite

   #-------------------------------------------------------------

   attr_reader :listFileToBeSent
      
   # Class constructor.
   # * entity (IN):  Entity textual name (i.e. FOS)
   def initialize(entity, isDebug=false, isNoDB=false)
      if isDebug == true then
         setDebugMode
      end
      @entity   = entity
      @isNoDB   = isNoDB
      
      checkModuleIntegrity

      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("DDC_FileMailer", "#{ENV['DCC_CONFIG']}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in DDC_FileMailer::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{ENV['DCC_CONFIG']}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end
      
      # Load Mail Params for this I/F.
      ddcConf       = CTC::ReadInterfaceConfig.instance
      ftReadConf    = CTC::ReadMailConfig.instance
      
      @delay        = ddcConf.getLoopDelay(@entity).to_i
      @loops        = ddcConf.getLoopRetries(@entity).to_i
      @retries      = ddcConf.getImmediateRetries(@entity).to_i

      @mailParams   = ftReadConf.getSendMailParams   
      @sendTo       = ddcConf.getMailList(@entity)

      @listFiles   = Array.new

      @outboxDir   = ddcConf.getOutgoingDir(@entity)
      @outboxDir   = "#{@outboxDir}/email"
      
      checkDirectory(@outboxDir)
      
      ddcConfig    = DDC::ReadConfigDDC.instance
      @arrFilters  = ddcConfig.getOutgoingFilters
      @subject     = ddcConfig.getProjectName
      @subject     = "#{@subject} mail delivery to #{@entity} I/F"
      @name        = ddcConfig.getProjectID
      @name        = "#{@name} Data Distributor Component"
            
      @arrFiles    = Array.new
      loadFileList

      if @isNoDB == false then
         require 'dbm/DatabaseModel'
         @interface   = Interface.find_by_name(@entity)
      else
         @interface   = @entity
      end

      if @arrFiles.length > 0 then
        checker   = CTC::CheckerMailConfig.new
        bRes      = checker.check(true, false)
        if bRes == false then
          conf = checker.getSendMailConfig
          msg  = "Could not connect to SMTP server in #{conf[:server]}:#{conf[:port]}"
          @logger.error(msg)
          puts
          puts msg
          msg  = "Could not deliver files to #{@entity} via Mail"
          @logger.error(msg)
          puts msg
          puts "\nNetwork problems or configuration error in ft_mail_config.xml\n"
          if isDebug == true then
            puts "Error in DDC_FileMailer::initialize !\n\n"
          end
          exit(99)
        end
      end
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      if @mailer != nil then
         @mailer.setDebugMode
      end
      puts "DDC_FileMailer debug mode is on"
   end
   #-------------------------------------------------------------
   
   def loadFileList
      @listFileToBeSent = Array.new
      @arrFiles         = Array.new
      prevDir   = Dir.pwd
      Dir.chdir(@outboxDir)
      
      if @isDebugMode == true then
         puts
         puts "Loading list of files to be Sent from:"
         puts @outboxDir
         puts
      end
      
      @arrFilters.each{|filter|
         @arrFiles << Dir[filter]
      }
      @arrFiles = @arrFiles.flatten
      @arrFiles = @arrFiles.uniq
      Dir.chdir(prevDir)
      
      if @isDebugMode == true
         if (@arrFiles.length > 0) then
            puts "-------------------------------------------------------"
            print("Files to be sent via EMAIL to #{@entity} are :\n")
            puts @arrFiles
            puts "-------------------------------------------------------"
         end
      end
      
      if @arrFiles.length == 0 then
#         puts "No files to be delivered via email to #{@entity}"
         message = "No Files to #{@entity} I/F in mail outbox #{@outboxDir}"
         @logger.debug(message)
      end
   
      @listFileToBeSent = @arrFiles
   end
   #-------------------------------------------------------------
   
   def deliver(deliverOnce=false, hParams=nil, bDelete = true)
      bRet           = true
      arrMailed      = Array.new
      @deliverOnce   = deliverOnce

      @arrFiles.each{|file|
         # If delivery once has been selected, check whether the file
         # has already been delivered
         if @deliverOnce == true then
            if SentFile.hasAlreadyBeenSent?(file, @entity, "email") == true then
               puts "#{file} has already been sent to #{@entity} via email"
               File.delete(%Q{#{@outboxDir}/#{file}})
               next
            end
         end            

         ret = mailFile(file)
         if ret == true then
            arrMailed << file
            @logger.info("#{file} sent to #{@entity} via mail")
            if bDelete == true then
               fullPathFile = "#{@outboxDir}/#{file}"
               FileUtils.rm_rf(fullPathFile)
            end
#            if @deliverOnce == true then

            if @isNoDB == false then
               SentFile.setBeenSent(file, @interface, "email", hParams)
            end

#            end
         else
            puts "Error mailing #{file}"
            bRet = false
         end
      }
      arrMailed.each{|x| @arrFiles.delete(x)}
      return bRet
   end
   #-------------------------------------------------------------
   
   def mailFile(file)
      nRetries = @retries - 1     
      retVal   = false
      i        = 0
      puts "Sending #{file} to #{@entity} via email"
      until ((nRetries < 0) or (retVal == true))  
         mailer = CTC::FileMailer.new(@mailParams, @sendTo, @name)
         mailer.setMailSubject(@subject)
         if @isDebugMode == true then
            mailer.setDebugMode
         end
         fullPathFile = "#{@outboxDir}/#{file}"
         
         if File.directory?(fullPathFile) == true then
            prevDir = Dir.pwd
            Dir.chdir(fullPathFile)
            arrFiles = Dir["*"]
            arrFiles.each{|aFile|
               mailer.addFileToBeSent("#{fullPathFile}/#{aFile}")
            }
            Dir.chdir(prevDir)
         else
            mailer.addFileToBeSent(fullPathFile)
         end

         bRetVal = mailer.deliver         
                  
         if bRetVal == true then
            return true
         end
         
         nRetries = nRetries - 1
         i        = i + 1
         
         puts "RE-Sending(#{i}) #{file} to #{@entity} via email"
         @logger.info("RE-Sending(#{i}) #{file} to #{@entity} via email")
      end
      return false        
   end
   #-------------------------------------------------------------
   

   #-------------------------------------------------------------

private

   @listFiles = nil
   @mailer    = nil

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   #-------------------------------------------------------------

   #-------------------------------------------------------------
      
end # class

end # module

