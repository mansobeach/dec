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

## https://www.shellhacks.com/disable-ssh-host-key-checking/

## SSH COMMAND 
## ssh -t -oBatchMode=no -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -oConnectTimeout=10 -oPort=22 -oLogLevel=QUIET gsc4eoadmin@naos-aiv-fds 'sudo systemctl start naos-fds4eo-app.service'

module CTC

module SSHClientCommands

   ## -----------------------------------------------------------

   ## -----------------------------------------------------------------
   ## 
   ## create remote SSH command

   def ssh_command(cmd, user, host)
      return "ssh -i ~/.ssh/naos-aiv.id_rsa -t -oBatchMode=no -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' -oConnectTimeout=10 -oPort=22 -oLogLevel=QUIET #{user}@#{host} '#{cmd}'"
   end
   ## -----------------------------------------------------------------
 
end

end
