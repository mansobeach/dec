#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DEC_BodyMailer class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# Git: $Id: DEC_BodyMailer.rb,v 1.11 2011/08/24 18:56:24 algs Exp $
#
# Module Data Distributor Component
# This class delivers methods for sending files to entities using SMTP.
# The files are sent in the delivered mail BODY.
#
#########################################################################

require 'fileutils'

require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'ctc/ReadMailConfig'
require 'ctc/CheckerMailConfig'
require 'ctc/MailSender'
require 'dec/ReadConfigDEC'
require 'dec/ReadInterfaceConfig'

module DEC

class DEC_BodyMailer

   include CUC::DirUtils
   include FileUtils::NoWrite
   
   attr_reader :listFileToBeSent
   
   ## -------------------------------------------------------------
   ##
   ##  
   ## Class constructor.
   ## * entity (IN):  Entity textual name (i.e. FOS)
   def initialize(entity, deliverOnce, isDebug=false)

      @entity   = entity
      @deliverOnce = deliverOnce
      if isDebug == true then
         setDebugMode
      end
      checkModuleIntegrity

      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("push", "#{ENV['DEC_CONFIG']}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in DEC_BodyMailer::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{ENV['DEC_CONFIG']}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end
      
      # Load Mail Params for this I/F.
      ddcConf       = ReadInterfaceConfig.instance
      ftReadConf    = CTC::ReadMailConfig.instance
      
      @delay        = ddcConf.getLoopDelay(@entity).to_i
      @loops        = ddcConf.getLoopRetries(@entity).to_i
      @retries      = ddcConf.getImmediateRetries(@entity).to_i

      @mailParams   = ftReadConf.getSendMailParams   
      @sendTo       = ddcConf.getMailList(@entity)

      @listFiles   = Array.new

      @outboxDir   = ReadConfigOutgoing.instance.getOutgoingDir(@entity)
      @outboxDir   = "#{@outboxDir}/mailbody"
      
      checkDirectory(@outboxDir)
      
      decConfig    = ReadConfigDEC.instance
      @arrFilters  = decConfig.getOutgoingFilters
      @subject     = decConfig.getMission
      @subject     = "#{@subject} Special Ops Request - "
      @name        = decConfig.getProjectID
      @name        = "#{@name} Data Distributor Component"
            
      @arrFiles    = Array.new
      loadFileList
      @interface   = Interface.find_by_name(@entity)

      if @arrFiles.length > 0 then
      	checker   = CTC::CheckerMailConfig.new
      	# Check just for Send Configuration (SMTP)
      	bRes      = checker.check(true, false)
      
        if bRes == false then
          conf = checker.getSendMailConfig
          @logger.error("[DEC_210] Could not connect to SMTP server in #{conf[:server]}:#{conf[:port]}")
          puts
          puts "Could not connect to SMTP server in #{conf[:server]}:#{conf[:port]}"
          @logger.error("[DEC_211] Could not deliver files to #{@entity} via Mail")

          puts "Could not deliver files to #{@entity} via Mail"
          puts "\nNetwork problems or configuration error in ft_mail_config.xml\n"
          puts "Error in DEC_BodyMailer::initialize !\n\n"
          exit(99)
        end
      end
   end   
   ## -------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      if @mailer != nil then
         @mailer.setDebugMode
      end
      puts "DEC_BodyMailer debug mode is on"
   end
   ## -------------------------------------------------------------
   
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
            if SentFile.hasAlreadyBeenSent?(file, @entity, "mailbody") == true then
               if @isDebugMode then
                  puts "#{file} already sent to #{@entity} via mailbody"
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
         print("Files to be sent via MAILBODY to #{@entity} are :\n")
         puts @arrFiles
         puts "-------------------------------------------------------"
      end
      
      if @arrFiles.empty? then
         if @isDebugMode == true then
            @logger.debug("#{@entity} I/F: No Files to  in ftp outbox #{@outboxDir}")
         end
      end
   
      @listFileToBeSent = @arrFiles
   end
   #-------------------------------------------------------------
   
   def deliver(hParams=nil, bDelete = true)
      bRet           = true
      arrMailed      = Array.new

      sendTo    = Array.new
      @mailer   = CTC::MailSender.new(@mailParams[:server], @mailParams[:port].to_i, @mailParams[:user], @mailParams[:pass], @mailParams[:isSecure])
      @mailer.init
      if @isDebugMode then
         @mailer.setDebugMode
      end
      @sendTo.each{|x| @mailer.addToAddress(x)}

   #send/process each file
      @arrFiles.each{|file|    

         ret = mailFile(file)
         @mailer.newMail

         if ret == true then
            arrMailed << file
            @logger.info("#{file} sent to #{@entity} via mailbody")
            if bDelete then
               fullPathFile = "#{@outboxDir}/#{file}"
               FileUtils.rm_rf(fullPathFile)
            end
            # Now we register the files sent even if we allow them to be re-send
            # (deliveryOnce equal to false)
            SentFile.setBeenSent(file, @interface, "mailbody", hParams)
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
      puts "Sending #{file} to #{@entity} via mailbody"
      until ((nRetries < 0) or (retVal == true))
         fullPathFile = "#{@outboxDir}/#{file}"         
         @mailer.setMailSubject(subject)

         # Read File to be delivered and place the content in mail body
         if !File.directory?(fullPathFile) then
            arrLines = IO.readlines(fullPathFile)
            arrLines.each{|aLine|
               @mailer.addLineToContent(aLine)
            }
         else
            prevDir = Dir.pwd
            Dir.chdir(fullPathFile)
            arrFiles = Dir["*"]
            arrFiles.each{|aFile|
               arrLines = IO.readlines("#{fullPathFile}/#{aFile}")
               arrLines.each{|aLine|
                  @mailer.addLineToContent(aLine)
               }
            }
            Dir.chdir(prevDir)
         end

         bRetVal = @mailer.sendMail
                  
         if bRetVal == true then
            return true
         end
         
         nRetries = nRetries - 1
         i        = i + 1
         
         puts "RE-Sending(#{i}) #{file} to #{@entity} via mailbody"
         @logger.info("RE-Sending(#{i}) #{file} to #{@entity} via mailbody")
      end
      return false        
   end
   # -------------------------------------------------------------

private

   @listFiles = nil
   @mailer    = nil

   ## -------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   ## -------------------------------------------------------------
      
end # class

end # module

