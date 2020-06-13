#!/bin/bash

## =========================================================
##
## Data Exchange Component
##
## Entry Point for DEC vsftpd with SSL enabled
##
## DO NOT USE IN PRODUCTION MODE
##
## =========================================================

set -e

/usr/bin/ln -sf /dev/stdout $LOG_FILE

[ "$DEBUG" == 'true' ] && set -x

echo "dec" > /etc/vsftpd_dec.userlist

export LOG_FILE=`grep xferlog_file /etc/vsftpd/vsftpd.conf|cut -d= -f2`

# /usr/bin/ln -sf /dev/stdout $LOG_FILE

touch $LOG_FILE

mkdir -p /tmp/dir1
mkdir -p /tmp/dir2
mkdir -p /tmp/dir3

chmod -R a+w /tmp/dir1
chmod -R a+w /tmp/dir2
chmod -R a+w /tmp/dir3


echo "dec touch file" > /tmp/touch_file

echo "dec touch file 1" > /tmp/dir1/touch_file_1
echo "dec touch file 2" > /tmp/dir2/touch_file_2
echo "dec touch file 3" > /tmp/dir3/touch_file_3


vsftpd /etc/vsftpd/vsftpd.conf -obackground=NO
