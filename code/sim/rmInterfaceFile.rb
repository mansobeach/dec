#!/usr/bin/env ruby

#########################################################################
#
# rmInterfaceFile.rb
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Collector Component
# 
# CVS:
#
#########################################################################

# It deletes all the files present in the remote Interfaces.

require 'fileutils'
require 'net/ftp'

require 'cuc/DirUtils'
require 'dcc/ReadInTrayConfig'
require 'ctc/ReadInterfaceConfig'
require 'ctc/SFTPBatchClient'

def main

   include FileUtils
   include CUC::DirUtils
   

   puts "\nrmInterfaceFile ..."
   print "\nALL FILES in DEC configured Interfaces will be DELETED !!!\n"
   print "[downloadDirs]\n"
   print "[uploadDir]"
   print "\n[uploadTemp]\n"

   res = ""

   while res.chop != "N" and res.chop != "Y"
      print "\nDo you want to continue? [Y/N]\n\n"
      res = STDIN.gets.upcase
   end

   if res.chop == "N" then
      puts "\n\nwise guy !! ;-p \n\n\n"
      exit(0)
   end


   pwd = Dir.pwd
   
   @entityConfig = CTC::ReadInterfaceConfig.instance
   arrEntity     = @entityConfig.getAllExternalMnemonics
   
   arrEntity.each{|entity|

      # Delete files from the Interface local Inbox
      dir = @entityConfig.getIncomingDir(entity)
      checkDirectory(dir)
      Dir.chdir(dir)
      rm(Dir.glob("*"), :force => true)
      
      # Delete files from the Interface local Outbox
      dir = @entityConfig.getOutgoingDir(entity)
      checkDirectory(dir)
      Dir.chdir(dir)
      rm(Dir.glob("*"), :force => true)

      ftp4Receive = @entityConfig.getFTPServer4Receive(entity)
      ftp4Send    = @entityConfig.getFTPServer4Send(entity)
      
      arrDownloadDirs = ftp4Receive[:arrDownloadDirs]
                  
      uploadDir   = ftp4Send[:uploadDir]
      uploadTmp   = ftp4Send[:uploadTemp] 

      host = ftp4Receive[:hostname]
      port = ftp4Receive[:port]
      user = ftp4Receive[:user]
      pass = ftp4Receive[:password]            

      if ftp4Receive.isSecure == true then
         sftpClient = CTC::SFTPBatchClient.new(host, port, user, "sftp-batch")
         sftpClient.setDebugMode

         arrDownloadDirs.each{|downloadDir|
            sftpClient.addCommand("cd", downloadDir[:directory], nil)
            sftpClient.addCommand("rm", "*", nil)
            sftpClient.executeAll
         }

         # Delete Upload Dir
         sftpClient.addCommand("cd", uploadDir, nil)
         sftpClient.addCommand("rm", "*", nil)
         sftpClient.executeAll

         # Delete Upload Temp
         sftpClient.addCommand("cd", uploadTmp, nil)
         sftpClient.addCommand("rm", "*", nil)
         sftpClient.executeAll

      else

         @ftp = nil
                     
         begin
            @ftp = Net::FTP.new(host)
            @ftp.login(user, pass)
            @ftp.passive = true
           
            arrDownloadDirs.each{|downloadDir|
               @ftp.chdir(downloadDir[:directory])

               arrFiles = @ftp.nlst
               arrFiles.each{|aFile|
                  puts "Delete #{aFile}"
                  begin
                     @ftp.delete(aFile)
                  rescue Exception => e
                     puts e.to_s
                  end
               }

            }


            begin
               @ftp.chdir(uploadDir)
            
               arrFiles = @ftp.nlst
               arrFiles.each{|aFile|
                  puts "Delete #{aFile}"
                  @ftp.delete(aFile)
               }
            rescue Exception => e
            
            end

            begin
               @ftp.chdir(uploadTmp)
            
               arrFiles = @ftp.nlst
               arrFiles.each{|aFile|
                  puts "Delete #{aFile}"
                  @ftp.delete(aFile)
               }
            rescue Exception => e
            
            end

         rescue Exception => e
            puts
            puts e.to_s
            exit(99)
         end      

      end

   }
   Dir.chdir(pwd)

end
#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
