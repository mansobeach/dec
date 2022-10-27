#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #SFTPBatchClient module
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: SFTPBatchClient.rb,v 1.3 2007/03/15 08:57:26 decdev Exp $
#
# This module contains methods for adding commands to a batch file and
# then execute them in a sftp client.
#
#########################################################################

## https://stackoverflow.com/questions/5386482/how-to-run-the-sftp-command-with-a-password-from-bash-script

## https://stackoverflow.com/questions/11738169/how-to-send-password-using-sftp-batch-file


require 'ctc/FTPClientCommands'

module CTC

class SFTPBatchClient
   
   include FTPClientCommands
   
   attr_reader :output
   
   # Class Constructor.
   # It requires the hostname, port, user and the batchfile.   
   def initialize(host, port, user, pass, batchFile, compress=false, logger = nil)
      @isDebugMode = false
      @host        = host
      @port        = port
      @user        = user
      @pass        = pass
      @batchFile   = "#{batchFile}.#{Time.now.to_f}.#{Random.new.rand(1.5)}"
      @cmd         = ""
      @compress    = compress
      checkModuleIntegrity
      if @pass != nil then
         ENV['SSHPASS'] = @pass
         ObjectSpace.define_finalizer( self, self.class.finalize )
      end
   end   
   # -------------------------------------------------------------
   
   def self.finalize
      proc { ENV.delete('SSHPASS') }
   end
   # -------------------------------------------------------------
   
   # It appends a sftp command to the batch file.
   # - cmd (IN): string containing the sftp command to be added to the batch file.
   # - arg1 (IN): string containing an argument for the sftp cmd or nil.
   # - arg2 (IN): string containing an argument for the sftp cmd or nil.
   def addCommand(cmd, arg1, arg2)
      if @pass == nil then
         @cmd = self.createSftpCommand(@host, @port, @user, @batchFile, cmd, arg1, arg2, @compress)
      else
         @cmd = self.createSftpSshPassCommand(@host, @port, @user, @pass, @batchFile, cmd, arg1, arg2, @compress)
      end
      return @cmd
   end
   #-------------------------------------------------------------   
   
   # It executes all sftp commands placed in the batch file.
   # After the execution the batchfile is emptied (deleted).
   # It Returns true if the execution is successful, otherwise
   # it returns false.
   def executeAll
      if @cmd == "" then
         puts("\nError in SFTPBatchClient::executeAll -> no command avalaible\n\n")
         return false
      end
      
      if @isDebugMode == true then
         puts "\n"
         puts "------------------------------------------"
         puts "SFTPBatchClient is about to execute :"
         puts @cmd
         puts IO.readlines(@batchFile)
         puts "------------------------------------------"
         puts "\n"
      end
         
      errorFile = %Q{#{@batchFile}.ERR}
                  
      STDERR.reopen(errorFile)      
      @output = `#{@cmd}`    
      STDERR.reopen(STDOUT)
      
      if $?.exitstatus !=0 then
         retVal = false
      else
         retVal = true
      end
      		
      # Give priority to the Unix return value to determine
      # the success of the command. If the system command
      # returns false, no need to process std error.
      #      
      # Process the STDERROR to determine whether the command
      # was successful or not.
      if retVal == true then
         retVal = processStdError(errorFile)
      end
      if FileTest.exists?(@batchFile) then # and retVal == true then 
         File.delete(@batchFile)
      end 
      if FileTest.exists?(errorFile) then # and retVal == true then 
         File.delete(errorFile)
      end      
      return retVal
   end   
   #-------------------------------------------------------------
   
   # Set debug flag on.
   def setDebugMode
     @isDebugMode = true
     puts "SFTPBatchClient debug mode is on"
   end
   #------------------------------------------------------------- 
   
private

   @isDebugMode = false

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   #-------------------------------------------------------------
   
   # It process the std error returned by the sftp command
   # to know whether the result was successful or not.
   # - It returns true if it is considered successful
   # - Otherwise it returns false.
   def processStdError(errorFile)
      
#      begin
         arr      = IO.readlines(errorFile)
#      rescue 
#         return true
#      end
      
      numLines = arr.length
      
      if @isDebugMode == true then
         puts
         puts "------------------------------------------"
         puts "stderr returned by sftp command is:\n"
         puts arr
         puts "------------------------------------------"
         puts "\n"
      end
      
		arr.each{|aLine|
			if aLine.include?("No such file or directory") == true then
				return false
			end
			
			if aLine.include?("Connection reset by peer") == true then
				return false
			end
			
			if aLine.include?("Couldn't read packet") == true then
				return false
			end
		}
		
      # numLines = 1 has been tested with OpenSSH 3.6.1p2
      # numLines = 0 has been tested with OpenSSH 3.9p1 - OpenSSH 4.6p1
      if numLines == 1 or numLines ==0 or numLines == 2 then
         return true
      end
      
      return false
   end
   #------------------------------------------------------------- 
  
end # class


end # module

