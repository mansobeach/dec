#!/bin/bash
set -e

/usr/bin/ln -sf /dev/stdout $LOG_FILE

[ "$DEBUG" == 'true' ] && set -x

echo "dec" > /etc/vsftpd_dec.userlist

export LOG_FILE=`grep xferlog_file /etc/vsftpd/vsftpd.conf|cut -d= -f2`

# /usr/bin/ln -sf /dev/stdout $LOG_FILE

touch $LOG_FILE

vsftpd /etc/vsftpd/vsftpd.conf -obackground=NO
