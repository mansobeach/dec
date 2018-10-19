#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DDC_BodyMailer class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# CVS: $Id: DDC_BodyMailer.rb,v 1.7 2008/07/03 11:38:26 decdev Exp $
#
# Module Data Distributor Component
# This class delivers methods for sending files to entities using SMTP.
# The files are sent in the delivered mail BODY.
#
#########################################################################

require 'fileutils'

require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadMailConfig'
require 'ctc/CheckerMailConfig'
require 'ctc/MailSender'
# require 'dbm/DatabaseModel'
require 'ddc/ReadConfigDDC'


module DDC

class DDC_BodyMailer

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
      
      configDir = nil

      if ENV['DEC_CONFIG'] then
         configDir         = %Q{#{ENV['DEC_CONFIG']}}  
      else
         configDir         = %Q{#{ENV['DCC_CONFIG']}}  
      end
                  
      loggerFactory = CUC::Log4rLoggerFactory.new("DDC_BodyMailer", "#{configDir}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in DDC_BodyMailer::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{configDir}/dec_log_config.xml\"" 
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
      @outboxDir   = "#{@outboxDir}/mailbody"
      
      checkDirectory(@outboxDir)
      
      ddcConfig    = DDC::ReadConfigDDC.instance
      @arrFilters  = ddcConfig.getOutgoingFilters
      @subject     = ddcConfig.getMission
      @subject     = "#{@subject} Special Ops Request"
      @name        = ddcConfig.getProjectID
      @name        = "#{@name} Data Distributor Component"
            
      @arrFiles    = Array.new
      loadFileList

      if @isNoDB == false then
         # require 'dbm/DatabaseModel'
         require 'dec/DEC_DatabaseModel'
         @interface   = Interface.find_by_name(@entity)
      else
         @interface   = @entity
      end

      if @arrFiles.length > 0 then
      	checker   = CTC::CheckerMailConfig.new
      	# Check just for Send Configuration (SMTP)
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
          puts "Error in DDC_BodyMailer::initialize !\n\n"
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
      puts "DDC_BodyMailer debug mode is on"
   end
   #-------------------------------------------------------------
   
   def loadFileList
      @listFileToBeSent = Array.new
      @arrFiles         = Array.new
      prevDir   = Dir.pwd
      Dir.chdir(@outboxDir)
      
#       if @isDebugMode == true then
#          puts
#          puts "Loading list of files to be Sent from:"
#          puts @outboxDir
#          puts
#       end
      
      @arrFilters.each{|filter|
         @arrFiles << Dir[filter]
      }
      @arrFiles = @arrFiles.flatten
      @arrFiles = @arrFiles.uniq
      Dir.chdir(prevDir)
      
      if @isDebugMode == true
         if (@arrFiles.length > 0) then
            puts "-------------------------------------------------------"
            print("Files to be sent via MAILBODY to #{@entity} are :\n")
            puts @arrFiles
            puts "-------------------------------------------------------"
         end
      end
      
      if @arrFiles.length == 0 then
#         puts "No files to be delivered via email to #{@entity}"
         message = "No Files to #{@entity} I/F in MAILBODY outbox #{@outboxDir}"
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
            if SentFile.hasAlreadyBeenSent?(file, @entity, "mailbody") == true then
               puts "#{file} has already been sent to #{@entity} using mailbody"
               File.delete(%Q{#{@outboxDir}/#{file}})
               next
            end
         end            

         ret = mailFile(file)
         if ret == true then
            arrMailed << file
            @logger.info("#{file} sent to #{@entity} via mailbody")
            if bDelete == true then
               fullPathFile = "#{@outboxDir}/#{file}"
               FileUtils.rm_rf(fullPathFile)
            end
            # Now we register the files sent even if we allow them to be re-send
            # (deliveryOnce equal to false)
#            if @deliverOnce == true then

               if @isNoDB == false then
                  SentFile.setBeenSent(file, @interface, "mailbody", hParams)
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
      puts "Sending #{file} to #{@entity} via mailbody"
      until ((nRetries < 0) or (retVal == true))
         user = @mailParams[:user]
         port = @mailParams[:port]
         host = @mailParams[:server]
         mailer = CTC::MailSender.new(user, host, port)

         if @isDebugMode == true then
            mailer.setDebugMode
         end

         mailer.init
         mailer.setMailSubject(@subject)
         @sendTo.each{|anAddress|
            mailer.addToAddress(anAddress)
         }

         fullPathFile = "#{@outboxDir}/#{file}"

         # Read File to be delivered and place the content in mail body
         if File.directory?(fullPathFile) == false then
            arrLines = IO.readlines(fullPathFile)
            arrLines.each{|aLine|
               mailer.addLineToContent(aLine)
            }
         else
            prevDir = Dir.pwd
            Dir.chdir(fullPathFile)
            arrFiles = Dir["*"]
            arrFiles.each{|aFile|
               arrLines = IO.readlines("#{fullPathFile}/#{aFile}")
               arrLines.each{|aLine|
                  mailer.addLineToContent(aLine)
               }
            }
            Dir.chdir(prevDir)
         end

         bRetVal = mailer.sendMail
                  
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

