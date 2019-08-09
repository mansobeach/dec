#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DEC_FileMailer class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component
# 
# CVS: $Id: DEC_FileMailer.rb,v 1.21 2013/03/14 13:40:57 algs Exp $
#
# Module Data Exchange Component
# This class delivers methods for sending files to entities using SMTP.
# The files are sent through attachments in a mail.
#
#########################################################################

require 'fileutils'

require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'cuc/EE_ReadFileName'

require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadMailConfig'
require 'ctc/CheckerMailConfig'
# require 'ctc/FileMailer'
require 'ctc/MailSender'

require 'dec/ReadConfigDEC'

module DEC

class DEC_FileMailer

   include CUC::DirUtils
   include FileUtils::NoWrite

   ## -------------------------------------------------------------

   attr_reader :listFileToBeSent
      
   # Class constructor.
   # * entity (IN):  Entity textual name (i.e. FOS)
   def initialize(entity, deliverOnce, isDebug=false, isNoDB=false)
      if isDebug == true then
         setDebugMode
      end
      @entity        = entity
      @deliverOnce   = deliverOnce
      @isNoDB        = isNoDB
      checkModuleIntegrity

      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("DEC_FileMailer", "#{ENV['DEC_CONFIG']}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      
      if @logger == nil then
         puts
			puts "Error in DEC_FileMailer::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{ENV['DEC_CONFIG']}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end
      
      # Load Mail Params for this I/F.
      decConf       = CTC::ReadInterfaceConfig.instance
      ftReadConf    = CTC::ReadMailConfig.instance
      
      @delay        = decConf.getLoopDelay(@entity).to_i
      @loops        = decConf.getLoopRetries(@entity).to_i
      @retries      = decConf.getImmediateRetries(@entity).to_i

      @mailParams   = ftReadConf.getSendMailParams   
      @sendTo       = decConf.getMailList(@entity)

      @listFiles   = Array.new

      @outboxDir   = decConf.getOutgoingDir(@entity)
      @outboxDir   = "#{@outboxDir}/email"
      
      checkDirectory(@outboxDir)
      
      decConfig    = ReadConfigDEC.instance
      @arrFilters  = decConfig.getOutgoingFilters
      @subject     = decConfig.getProjectName
#      @subject     = "#{@subject} mail delivery to #{@entity} I/F"
      @subject     = "#{@subject} delivery - "
      @name        = decConfig.getProjectID
      @name        = "#{@name} Data Exchange Component"
            
      @arrFiles    = Array.new
      loadFileList
      
      if @isNoDB == false then
         require 'dec/DEC_DatabaseModel'
         @interface   = Interface.find_by_name(@entity)
      else
         @interface   = @entity
      end


      if @arrFiles.length > 0 then
        checker   = CTC::CheckerMailConfig.new
        bRes      = checker.check(true, false)
        if !bRes then
          conf = checker.getSendMailConfig       
          @logger.error("[DEC_210] Could not connect to SMTP server in #{conf[:server]}:#{conf[:port]}")
          puts "\nCould not connect to SMTP server in #{conf[:server]}:#{conf[:port]}"
          @logger.error("[DEC_211] Could not deliver files to #{@entity} via Mail")
          puts "Could not deliver files to #{@entity} via Mail"
          puts "\nNetwork problems or configuration error in ft_mail_config.xml\n"
          if isDebug == true then
            puts "Error in DEC_FileMailer::initialize !\n\n"
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
      puts "DEC_FileMailer debug mode is on"
   end
   #-------------------------------------------------------------
   
   def loadFileList
      @listFileToBeSent = Array.new
      @arrFiles         = Array.new
      arrTmp            = Array.new
      prevDir   = Dir.pwd
      Dir.chdir(@outboxDir)

      if @isDebugMode then
         puts "\nLoading list of files to be Sent from:#{@outboxDir}"
      end

      @arrFilters.each{|filter|
         if @isDebugMode then
            puts "Filtering outgoing files by #{filter}"
         end
         arrTmp << Dir[filter]
      }
      arrTmp = arrTmp.flatten
      arrTmp = arrTmp.uniq
      Dir.chdir(prevDir)  
          
      # If delivery once has been selected, check whether the file
      # has already been delivered
      if @deliverOnce then
         arrTmp.each { |file|
            if SentFile.hasAlreadyBeenSent?(file, @entity, "email") == true then
               if @isDebugMode then
                  puts "#{file} already sent to #{@entity} via email"
               end
               File.delete(%Q{#{@outboxDir}/#{file}})
            else
               @arrFiles << file
            end                   
         }
      else
         @arrFiles= arrTmp.clone
      end

      if @isDebugMode and !@arrFiles.empty? then
         puts "-------------------------------------------------------"
         print("Files to be sent via EMAIL to #{@entity} are :\n")
         puts @arrFiles
         puts "-------------------------------------------------------"
      end
      
      if @arrFiles.empty? then    
         @logger.debug("No Files to #{@entity} I/F in mail outbox #{@outboxDir}")
      end
   
      @listFileToBeSent = @arrFiles
   end
   #-------------------------------------------------------------
   
   def deliver(hParams=nil, bDelete = true)
      bRet           = true
      arrMailed      = Array.new  
      sendTo         = Array.new

      @mailer   = CTC::MailSender.new(@mailParams[:server], @mailParams[:port].to_i, @mailParams[:user],
@mailParams[:pass], @mailParams[:isSecure], @name, @mailParams[:subject], @mailParams[:body])
      @mailer.init
      if @isDebugMode then
         @mailer.setDebugMode
      end
      @sendTo.each{|x| @mailer.addToAddress(x)}

    @arrFiles.each{|file|
 
         ret = mailFile(file)
         @mailer.newMail

         if ret == true then
            arrMailed << file
            @logger.info("#{file} sent to #{@entity} via mail")
            if bDelete == true then
               fullPathFile = "#{@outboxDir}/#{file}"
               FileUtils.rm_rf(fullPathFile)
            end
            if @isNoDB == false then
               SentFile.setBeenSent(file, @interface, "email", hParams)
            end
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
      fileType = CUC::EE_ReadFileName.new(File.basename(file)).fileType
      subject = "#{@subject}#{fileType}"
      nRetries = @retries - 1     
      retVal   = false
      i        = 0
      puts "Sending #{file} to #{@entity} via email"
      until ((nRetries < 0) or (retVal == true))
         fullPathFile = "#{@outboxDir}/#{file}"
   
         if File.directory?(fullPathFile) then
            prevDir = Dir.pwd
            Dir.chdir(fullPathFile)
            arrFiles = Dir["*"]
            @mailer.attachedMailSeveralFiles(subject, arrFiles)
            Dir.chdir(prevDir)
         else
            @mailer.attachedMail(subject, fullPathFile)
         end

         bRetVal = @mailer.sendMail         
                  
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

