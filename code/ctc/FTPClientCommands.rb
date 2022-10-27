#!/usr/bin/env ruby

#########################################################################
##
## === Ruby source for #FTPClientCommands module
##
## === Written by DEIMOS Space S.L. (bolf)
##
## === Data Exchange Component -> Common Transfer Component
## 
## git: FTPClientCommands.rb,v $Id$: 
##
## === module Common Transfer Component module FTPClientCommands
##
## This module contains methods for creating the ncftp, sftp, ...
## command line statements. 
##
#########################################################################

## http://www.mukeshkumar.net/articles/curl/how-to-use-curl-command-line-tool-with-ftp-and-sftp

## https://stackoverflow.com/questions/5386482/how-to-run-the-sftp-command-with-a-password-from-bash-script

## https://stackoverflow.com/questions/11738169/how-to-send-password-using-sftp-batch-file

module CTC

module FTPClientCommands

   ## -----------------------------------------------------------

   def createCurlFTPList(host, port, user, pass, dir, passive = nil, filter = nil)
      
      command = ""
      
      if dir[0,1] == '/' then
         dir = '%2F' + dir
      end
      
      # --------------------------------
      # Switch between FTP passive or port mode
      optionPassive = ""
      if passive == nil or passive == false then
         optionPassive = "--ftp-port"
      else
         optionPassive = "--ftp-pasv"
      end
      # --------------------------------
   
      cmd = "curl #{optionPassive} -l ftp://#{user}:#{pass}@#{host}:/#{dir}/"
   
   end

   ## -----------------------------------------------------------
   
   ## Create ncftpls command. 
   ## %2F literal slash character is required for managing full path directories
   ## - host (IN): string containing the host name.
   ## - port (IN): string containing the port number.
   ## - user (IN): string containing the user name.
   ## - pass (IN): string containing the password.
   ## - dir  (IN): string containing the dir required for the ls cmd.
   ## - passive (IN): boolean to switch between Passive or Port mode.
   ## - filter (IN): optional filtering in the directory.
   ## * Returns the ncftpls command line statement created.
   def createNcFtpLs(host, port, user, pass, dir, passive = nil, filter = nil)

      if dir[0,1] == '/' then
         dir = '%2F' + dir
      end
      
      # --------------------------------
      # Switch between FTP passive or port mode
      optionPassive = ""
      if passive == nil or passive == false then
         optionPassive = "-E"
      else
         optionPassive = "-F"
      end
      # --------------------------------
      
#      if filter == nil then
#         command = %Q{ncftpls -P #{port} -u #{user} -p #{pass} #{optionPassive} -x \"-1" ftp://#{host}/#{dir}/}      
#      else
#         command = %Q{ncftpls -P #{port} -u #{user} -p #{pass} #{optionPassive} -x \"-1 #{filter}\" ftp://#{host}/#{dir}/}
#         ### Dummy comment \""
#      end
      
      if filter == nil then
         command = %Q{ncftpls -P #{port} -u #{user} -p #{pass} #{optionPassive} -x \"-l" ftp://#{host}/#{dir}/}      
      else
         command = %Q{ncftpls -P #{port} -u #{user} -p #{pass} #{optionPassive} -x \"-l #{filter}\" ftp://#{host}/#{dir}/}
         ### Dummy comment \""
      end

      return command         
   end
   ## -------------------------------------------------------------\""

   def createNcFtpPut_FJLH1(host, port, user, pass, dir, tdir, file, verbose)
      filename = File.basename(file)
      
      # Attention: RNFR fails in Cryosat development/test platform executed after NCFTPPUT
      # As a workaround, RNFR/RNTO commands are executed using an additional NCFTPLS
      # An extra NCFTPLS with the file name as filter is used to actually test the transfer success
      if verbose == true then
        command = %Q{ncftpput -u #{user} -p #{pass} -P #{port} -F -v  #{host} #{tdir} #{file} ;
                     ncftpls  -u #{user} -p #{pass} -P #{port} -F -X "RNFR #{tdir}/#{filename}" -X "RNTO #{dir}/#{filename}" ftp://#{host} }
      else
        command = %Q{ncftpput -u #{user} -p #{pass} -P #{port} -F -V #{host} #{tdir} #{file} ;
                     ncftpls  -u #{user} -p #{pass} -P #{port} -F -X "RNFR #{tdir}/#{filename}" -X "RNTO #{dir}/#{filename}" ftp://#{host} }
      end
      return command
   end

   # =======================================================================================
   
   def createNcFtpPut_FJLH2(host, port, user, pass, dir, tdir, file, verbose)
      filename = File.basename(file)
      
      # Attention: RNFR fails in Cryosat development/test platform executed after NCFTPPUT
      # As a workaround, RNFR/RNTO commands are executed using an additional NCFTPLS
      # An extra NCFTPLS with the file name as filter is used to actually test the transfer success
      if verbose == true then
        command = %Q{ncftpput -u #{user} -p #{pass} -P #{port} -F -v  #{host} #{tdir} #{file} ;
                     ncftpls  -u #{user} -p #{pass} -P #{port} -F -X "RNFR #{tdir}/#{filename}" -X "RNTO #{dir}/#{filename}" ftp://#{host} ;
                     ncftpls  -u #{user} -p #{pass} -P #{port} -F -x \"ls -1 #{filename}\" ftp://#{host}/#{dir}/ }      
      else
        command = %Q{ncftpput -u #{user} -p #{pass} -P #{port} -F -V #{host} #{tdir} #{file} ;
                     ncftpls  -u #{user} -p #{pass} -P #{port} -F -X "RNFR #{tdir}/#{filename}" -X "RNTO #{dir}/#{filename}" ftp://#{host} ;
                     ncftpls  -u #{user} -p #{pass} -P #{port} -F -x \"ls -1 #{filename}\" ftp://#{host}/#{dir}/ }
      end
      return command
   end

   # ======================================================================================= "
   
   
   ## Create ncftpget command for downloading a given file.
   ## %2F literal slash character is required for managing full path directories
   ## - host (IN): string containing the host name.
   ## - port (IN): string containing the port number.
   ## - user (IN): string containing the user name.
   ## - pass (IN): string containing the password.
   ## - dir  (IN): string containing the dir where the file is placed.
   ## - file (IN): string of the filename.
   ## - delete (IN): boolean containing whether it is desired
   ##                        to delete the file once retrieved or not
   ## - verbose (IN): boolean for activating or not the verbose mode.
   ## - passive (IN): boolean to switch between Passive or Port mode.
   def createNcFtpGet(host, port, user, pass, dir, file, delete, verbose, passive = nil)
   
      ## Esr!@$Pm or ein6eemaeH2Uo"ph
      pass    = pass.dup.gsub('"', '\"')
      pass    = pass.dup.gsub('!', '\!')
      pass    = pass.dup.gsub('@', '\@')
      pass    = pass.dup.gsub('$', '\$')
          
      if dir[0,1] == '/' then
         dir = '%2F'+dir
      end      

      if file[0,1] == '/' then
         file = '%2F'+file
      end      

      ## Passive vs Port
      if passive == nil or passive == false then
         command = %Q{ncftpget -P #{port} -u #{user} -p #{pass} -E}
      else
         command = %Q{ncftpget -P #{port} -u #{user} -p #{pass} -F}
      end
      
      if verbose == true then
         command = %Q{#{command} -v}
      else
         command = %Q{#{command} -V}
      end
      
      if delete == true then
         command = %Q{#{command} -DD}
      end
      
      if dir != "" then
         command = %Q{#{command} ftp://#{host}/#{dir}/#{file}}
      else
         command = %Q{#{command} ftp://#{host}/#{file}}
      end
      return command         
   end
   ## -------------------------------------------------------------
   
   ## Create ncftpput command line for sending a given file.
   ## - host (IN): string containing the host name.
   ## - port (IN): string containing the port number.
   ## - user (IN): string containing the user name.
   ## - pass (IN): string containing the password.
   ## - dir  (IN): string containing the dir where the file is placed.
   ## - file (IN): string of the filename.
   ## - verbose (IN): boolean for activating or not the verbose mode.
   ## - passive (IN): boolean to switch between Passive or Port mode.
   def createNcFtpPut(host, port, user, pass, tmpDir, dir, file, prefix, verbose, passive = nil)

      ## esrin_e2espm

      ## Esr!@$Pm or ein6eemaeH2Uo"ph
      pass    = pass.dup.gsub('"', '\"')
      pass    = pass.dup.gsub('!', '\!')
      pass    = pass.dup.gsub('@', '\@')
      pass    = pass.dup.gsub('$', '\$')
            
      if dir[0,1] != '/' then
         dir='~/'+dir
      end      
      # --------------------------------
      # Switch between FTP passive or port mode
      optionPassive = ""
      if passive == nil or passive == false then
         optionPassive = "-E"
      else
         optionPassive = "-F"
      end
      # --------------------------------

      # exit(99)

      if verbose == true then
         options= "-v"
      else
         options= "-V"
      end

#      if prefix != nil or !prefix.empty? then
#         tmpDir=dir
#         options= options+" -T #{prefix}"
#      end
      command = %Q{ncftpput -t 10 -u #{user} -p #{pass} -P #{port} #{optionPassive} -m #{options} -X "RNFR #{file}" -X "RNTO #{dir}/#{file}" #{host} #{tmpDir} #{file} }
#      puts
#      puts command
#      puts
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
   def createNcFtpPut_NEW(host,port,user,pass,tmpDir,dir,file,prefix,verbose)
      if dir[0,1] != '/' then
         dir='~/'+dir
      end

      if verbose == true then
         options= "-v"
      else
         options= "-V"
      end

      if !prefix.empty? then
         tmpDir=dir
         options= options+" -T #{prefix}"
      end

      command = %Q{ncftpput -t 10 -u #{user} -p #{pass} -P #{port} -F -m #{options} -X "RNFR #{file}" -X "RNTO #{dir}/#{file}" #{host} #{tmpDir} #{file} }
      return command
   end
   #-------------------------------------------------------------   

   #-------------------------------------------------------------
   # Create ncftpput command line for creating dynamic dirs.
   # - host    (IN): string containing the host name.
   # - port    (IN): string containing the port number.
   # - user    (IN): string containing the user name.
   # - pass    (IN): string containing the password.
   # - dir     (IN): string containing the dir where the file is placed.
   # - dirFile (IN): string containing the dir where the file is located.
   # - file    (IN): string of the filename.
   # - verbose (IN): boolean for activating or not the verbose mode.
   def createNcFtpMkd(host,port,user,pass,dir, dirFile, file,verbose)

      ## Esr!@$Pm or ein6eemaeH2Uo"ph
      pass    = pass.dup.gsub('"', '\"')
      pass    = pass.dup.gsub('!', '\!')
      pass    = pass.dup.gsub('@', '\@')
      pass    = pass.dup.gsub('$', '\$')
   
         if !FileTest.exists?(dirFile+'/'+file) then
            File.open(dirFile+'/'+file, "w" ) do |new_file| 
               new_file.puts "create dynamic dirs" 
            end 
         end
         if verbose == true then
            command = %Q{ncftpput -t 10 -u #{user} -p #{pass} -P #{port} -F -m -v -X "DELE #{file}" #{host} #{dir} #{dirFile}/#{file}}
         else
            command = %Q{ncftpput -t 10 -u #{user} -p #{pass} -P #{port} -F -m -V -X "DELE #{file}" #{host} #{dir} #{dirFile}/#{file}}
         end
      return command
   end   
   #-------------------------------------------------------------
   
   
   ## -----------------------------------------------------------
   
   ## Create secureftp (sftp) command. Also creates or appends into 
   ## the batchFile passed as parameter.
   ## - host (IN): string containing the host name.
   ## - port (IN): string containing the port number.
   ## - user (IN): string containing the user name.
   ## - batchFile (IN): string containing the batchfile filename.
   ## - cmd (IN): string containing the sftp command to be executed.
   ## - arg1 (IN): string containing an argument for the sftp cmd or nil.
   ## - arg2 (IN): string containing an argument for the sftp cmd or nil.
   ## - compress (IN): optional argument for compressing SSH communication. 
   def createSftpCommand(host, port, user, batchFile, cmd, arg1, arg2, compress=false)
      if compress == false then
         command = %Q{sftp -oBatchMode=no -oConnectTimeout=10 -oPort=#{port} -oLogLevel=QUIET -b #{batchFile} #{user}@#{host}}
      else
         command = %Q{sftp -oBatchMode=no -oConnectTimeout=10 -C -oPort=#{port} -oLogLevel=QUIET -b #{batchFile} #{user}@#{host}}   
      end
      addCommand2SftpBatchFile(batchFile, cmd, arg1, arg2)
      return command      
   end
   ## -----------------------------------------------------------   
   
   ## Create secureftp (sftp) command. Also creates or appends into 
   ## the batchFile passed as parameter.
   ## - host (IN): string containing the host name.
   ## - port (IN): string containing the port number.
   ## - user (IN): string containing the user name.
   ## - pass (IN): string containing the pass name.
   ## - batchFile (IN): string containing the batchfile filename.
   ## - cmd (IN): string containing the sftp command to be executed.
   ## - arg1 (IN): string containing an argument for the sftp cmd or nil.
   ## - arg2 (IN): string containing an argument for the sftp cmd or nil.
   ## - compress (IN): optional argument for compressing SSH communication. 
   def createSftpSshPassCommand(host, port, user, pass, batchFile, cmd, arg1, arg2, compress=false)
      if compress == false then
         command = %Q{sshpass -e sftp -oBatchMode=no -oConnectTimeout=10 -oPort=#{port} -oLogLevel=QUIET -b #{batchFile} #{user}@#{host}}
      else
         command = %Q{sshpass -e sftp -oBatchMode=no -oConnectTimeout=10 -C -oPort=#{port} -oLogLevel=QUIET -b #{batchFile} #{user}@#{host}}   
      end
      addCommand2SftpBatchFile(batchFile, cmd, arg1, arg2)
      return command      
   end
   ## -----------------------------------------------------------   

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


   # by FJLH
   def createNcFtpPut_FJLH_BOLF(host, port, user, pass, tdir, dir, file, verbose, passive = nil)
      
      url_dir = ""
      
      # Management of full paths
      if dir[0,1] == '/' then
         url_dir = "/%2F#{dir.dup[1..-1]}"
      else
         url_dir = dir
      end

      url_tdir = ""

      if tdir[0,1] == '/' then
         url_tdir = "/%2F#{tdir.dup[1..-1]}"
      else
         url_tdir = tdir
      end
      
      # --------------------------------
      # Switch between FTP passive or port mode
      optionPassive = ""
      if passive == nil or passive == false then
         optionPassive = "-E"
      else
         optionPassive = "-F"
      end
      # --------------------------------

      if verbose == true then
         options= "-v"
      else
         options= "-V"
      end
      
      filename = File.basename(file)
      
      # Attention: RNFR fails in Cryosat development/test platform executed after NCFTPPUT
      # As a workaround, RNFR/RNTO commands are executed using an additional NCFTPLS
      # An extra NCFTPLS with the file name as filter is used to actually test the transfer success
      if verbose == true then
        command = %Q{ncftpput -u #{user} -p #{pass} -P #{port} #{optionPassive} -v  #{host} #{tdir} #{file} ;
                     ncftpls  -u #{user} -p #{pass} -P #{port} #{optionPassive} -X "RNFR #{tdir}/#{filename}" -X "RNTO #{dir}/#{filename}" ftp://#{host} ;
                     ncftpls  -u #{user} -p #{pass} -P #{port} #{optionPassive} -x \"ls -1 #{filename}\" ftp://#{host}/#{url_dir}/ }      
      else
        command = %Q{ncftpput -u #{user} -p #{pass} -P #{port} #{optionPassive} -V #{host} #{tdir} #{file} ;
                     ncftpls  -u #{user} -p #{pass} -P #{port} #{optionPassive} -X "RNFR #{tdir}/#{filename}" -X "RNTO #{dir}/#{filename}" ftp://#{host} ;
                     ncftpls  -u #{user} -p #{pass} -P #{port} #{optionPassive} -x \"ls -1 #{filename}\" ftp://#{host}/#{url_dir}/ }
      end
      
      puts "=========================================="
      puts command
      puts "=========================================="
      
      return command
   end

   # -------------------------------------------------------------


end

end
