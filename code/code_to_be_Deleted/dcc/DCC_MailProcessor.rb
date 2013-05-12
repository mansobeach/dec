#!/usr/bin/ruby

#########################################################################
#
# Ruby source for #DCC_MailProcessor class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Collector Component
# 
# CVS:
#   $Id: DCC_MailProcessor.rb,v 1.3 2008/07/03 11:38:07 decdev Exp $
#
#########################################################################

   #- This class processes all the incoming mails to the DCC email account.
	#- It extracts the notification mails

require "cuc/Log4rLoggerFactory"
require "cuc/DirUtils"
require "ctc/ReadMailConfig"
require "ctc/MailReceiver"
require "ctc/MailParser"
require "dcc/FileDeliverer2InTrays"


module DCC

class DCC_MailProcessor
   
   include CUC::DirUtils
   #-------------------------------------------------------------
   
   # Class constructor.
   # IN Parameters:
   def initialize(debugMode = false)
      @isDebugMode = debugMode
		checkModuleIntegrity

      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("DCC_MailProcessor", "#{ENV['DCC_CONFIG']}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in DCC_MailProcessor::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{ENV['DCC_CONFIG']}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end

		@mailConfig = CTC::ReadMailConfig.instance
      @mailParams = @mailConfig.getReceiveMailParams

      if @isDebugMode == true then
		   puts @mailParams 
		end
		 
      popHost = @mailParams[:server]
      popPort = @mailParams[:port]
      popUser = @mailParams[:user]
      popPass = @mailParams[:pass]

      @mailer = CTC::MailReceiver.new(popHost, popPort.to_i, popUser, popPass)
      
		if @isDebugMode == true then
		   @mailer.setDebugMode
      end
		if @mailer.init == false
		   puts
			puts "Error in DCC_MailProcessor::initialize"
			puts "Could not set up mailer !  :-("
			puts
			puts
			exit(99)
		end
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "DCC_MailProcessor debug mode is on"
   end
   #-------------------------------------------------------------
   
	# It process all emails stored in the DCC mail account.
	# deleteFlag (IN) : flag for deleting or not the processed mails
	def processAll(deleteFlag = false)
      bIsFile = false
	   mparser = CTC::MailParser.new()
		if @isDebugMode == true then
         mparser.setDebugMode
      end
      arrMails = @mailer.getAllMails(deleteFlag)
		arrMails.each{|mail|
		   mparser.parse(mail)
			puts "=========================================="
			puts "Subject: #{mparser.subject}"
			puts
         @logger.info("Mail received with Subject: #{mparser.subject}")
			if mparser.isFile == true then
            bIsFile = true
			   puts "File Attached: #{mparser.filename}"
				write2Disk(@tmpDir, mparser.filename, mparser.body)
         else
            puts "No Attachment detected !"
			end
#         puts "body:"
#         puts mailparser.body
#			puts "=========================================="
		}
		if arrMails.length > 0 then
		   puts "=========================================="
      else
         puts
         puts "There are no mails"
         @logger.info("There are no mail notifications")
	   end

#      if bIsFile == true then
         deliverer = DCC::FileDeliverer2InTrays.new
	      if @isDebugMode == true then
	         deliverer.setDebugMode
	      end
	      deliverer.deliverFromDirectory(@tmpDir)
#      end
      
	end
   #-------------------------------------------------------------

private

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bDefined = true     
      if !ENV['DCC_TMP'] then
         puts "\nDCC_TMP environment variable not defined !\n"
         bDefined = false
      end
      if !ENV['DCC_CONFIG'] then
         puts "\nDCC_CONFIG environment variable not defined !\n"
         bDefined = false
      end      
      if bDefined == false then
         puts "\nError in DCC_MailProcessor::checkModuleIntegrity :-(\n\n"
         exit(99)
      end                  
      @tmpDir = ENV['DCC_TMP']
      @tmpDir = %Q{#{@tmpDir}/dccmail}
      checkDirectory(@tmpDir)                  
   end
   #-------------------------------------------------------------
	
	# This method writes to disk a the body of a file received
	def write2Disk(directory, filename, arrContent)
	   prevDir = Dir.pwd
		Dir.chdir(directory)
		aFile = nil     
      begin
         # Assure no strange class is used for filename variable
         # And remove any extrange characters in case they are. 
         aFile = File.new(filename.to_s.chop, File::CREAT|File::WRONLY)
      rescue Exception
         puts
         puts "Fatal Error in DCC_MailProcessor::write2Disk"
         puts "Could not create file #{filename} in #{Dir.pwd}"
         exit(99)
      end
      
      aFile.binmode
		
		arrContent.each{|chunk|
		   aFile.print chunk
		}
      
		aFile.flush
      aFile.close     
      Dir.chdir(prevDir)
      return true
	end
   #-------------------------------------------------------------
end # class

end # module
