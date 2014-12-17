#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #FTPClientCommands module
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: FTPClientCommands.rb,v 1.3 2007/06/26 15:52:24 decdev Exp $
#
# === module Common Transfer Component module FTPClientCommands
#
# This module contains methods for creating the ncftp, sftp, ...
# command line statements. 
#
#########################################################################

module CTC

module FTPClientCommands

   #-------------------------------------------------------------
   
   # Create ncftpls command. 
   # %2F literal slash character is required for managing full path directories
   # - host (IN): string containing the host name.
   # - port (IN): string containing the port number.
   # - user (IN): string containing the user name.
   # - pass (IN): string containing the password.
   # - dir  (IN): string containing the dir required for the ls cmd.
   # - passive (IN): boolean to switch between Passive or Port mode.
   # - filter (IN): optional filtering in the directory.
   # * Returns the ncftpls command line statement created.
   def createNcFtpLs(host,port,user,pass,dir,passive = nil, filter = nil)
      
      # --------------------------------
      # Switch between FTP passive or port mode
      optionPassive = ""
      if passive == nil then
         optionPassive = "-E"
      else
         optionPassive = "-F"
      end
      # --------------------------------
      
      if filter == nil then
         command = %Q{ncftpls -P #{port} -u #{user} -p #{pass} #{optionPassive} -x \"-1" ftp://#{host}/#{dir}/}      
      else
         command = %Q{ncftpls -P #{port} -u #{user} -p #{pass} #{optionPassive} -x \"-1 #{filter}\" ftp://#{host}/#{dir}/}
      end
      return command         
   end
   #-------------------------------------------------------------
   
   # Create ncftpget command for downloading a given file.
   # %2F literal slash character is required for managing full path directories
   # - host (IN): string containing the host name.
   # - port (IN): string containing the port number.
   # - user (IN): string containing the user name.
   # - pass (IN): string containing the password.
   # - dir  (IN): string containing the dir where the file is placed.
   # - file (IN): string of the filename.
   # - delete (IN): boolean containing whether it is desired
   #                        to delete the file once retrieved or not
   # - verbose (IN): boolean for activating or not the verbose mode.
   def createNcFtpGet(host,port,user,pass,dir,file,delete,verbose)      
      command = %Q{ncftpget -P #{port} -u #{user} -p #{pass} -F}
      if verbose == true then
         command = %Q{#{command} -v}
      else
         command = %Q{#{command} -V}
      end
      
      if delete == true then
         command = %Q{#{command} -DD}
      end
      
      if dir != "" then
         command = %Q{#{command} ftp://#{host}/%2F#{dir}/#{file}}
      else
         command = %Q{#{command} ftp://#{host}/%2F#{file}}
      end
      return command         
   end
   #-------------------------------------------------------------
   
   # Create ncftpput command line for sending a given file.
   # - host (IN): string containing the host name.
   # - port (IN): string containing the port number.
   # - user (IN): string containing the user name.
   # - pass (IN): string containing the password.
   # - dir  (IN): string containing the dir where the file is placed.
   # - file (IN): string of the filename.
   # - verbose (IN): boolean for activating or not the verbose mode.
   # - passive (IN): boolean to switch between Passive or Port mode.
   def createNcFtpPut(host,port,user,pass,dir,file,verbose, passive = nil)
      
      # --------------------------------
      # Switch between FTP passive or port mode
      optionPassive = ""
      if passive == nil then
         optionPassive = "-E"
      else
         optionPassive = "-F"
      end
      # --------------------------------

      if verbose == true then
        command = %Q{ncftpput -u #{user} -p #{pass} -P #{port} #{optionPassive} -v #{host} #{dir} #{file} }      
      else
        command = %Q{ncftpput -u #{user} -p #{pass} -P #{port} #{optionPassive} -V #{host} #{dir} #{file} }
      end
      return command
   end
   #-------------------------------------------------------------
   
   # Create secureftp (sftp) command. Also creates or appends into 
   # the batchFile passed as parameter.
   # - host (IN): string containing the host name.
   # - port (IN): string containing the port number.
   # - user (IN): string containing the user name.
   # - batchFile (IN): string containing the batchfile filename.
   # - cmd (IN): string containing the sftp command to be executed.
   # - arg1 (IN): string containing an argument for the sftp cmd or nil.
   # - arg2 (IN): string containing an argument for the sftp cmd or nil.
   # - compress (IN): optional argument for compressing SSH communication. 
   def createSftpCommand(host, port, user, batchFile, cmd, arg1, arg2, compress=false)
      if compress == false then
         command = %Q{sftp -oPort=#{port} -oLogLevel=QUIET -b #{batchFile} #{user}@#{host}}
      else
         command = %Q{sftp -C -oPort=#{port} -oLogLevel=QUIET -b #{batchFile} #{user}@#{host}}   
      end
      addCommand2SftpBatchFile(batchFile, cmd, arg1, arg2)
      return command      
   end
   #-------------------------------------------------------------   
   
   private
   
   #-------------------------------------------------------------
      
   # Add an sftp command to a batch file
   #
   # If the file exists, it is opened in APPEND mode. Otherwise it is created.
   #
   # This is used for creating batch files with the list of sftp commands
   # needed for sending a single file (put + rename)
   # - batchFile (IN) : batchfile where cmds are stored
   # - cmd (IN) : sftp command
   # - arg1 (IN): 1st command argument (source file for PUT and temporary file
   #   for RENAME)
   # - arg2 (IN): 2nd command arguments (target temporary name for PUT and target
   #   file name for RENAME)
   def addCommand2SftpBatchFile(batchFile, cmd, arg1, arg2)
     
      aFile = nil     
      begin
         aFile = File.new(batchFile, File::CREAT|File::APPEND|File::WRONLY)
      rescue Exception
         puts
         puts "Fatal Error in FTPClientCommands::addCommand2SftpBatchFile"
         puts "Could not create file #{batchFile} in #{Dir.pwd}"
         exit(99)
      end
          
      command = cmd
      if arg1 != nil then
         command << " "
         command << arg1
      end
      if arg2 != nil then
         command << " "
         command << arg2
      end     
      command << "\n"    
     
      begin     
         aFile.puts(command)
         aFile.flush
         aFile.close
      rescue Exception => e
         puts
         puts "Fatal Error in FTPClientCommands::addCommand2SftpBatchFile"
         puts "Could not write into file #{batchFile} in #{Dir.pwd}"
         exit(99)         
      end
          
   end
   #------------------------------------------------------------- 

end

end
