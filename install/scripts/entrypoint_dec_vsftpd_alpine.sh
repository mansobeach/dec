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

# --------------------------------------
# Remove all ftp users
grep '/ftp/' /etc/passwd | cut -d':' -f1 | xargs -n1 deluser

# --------------------------------------

#Create users
#USERS='name1|password1|[folder1][|uid1] name2|password2|[folder2][|uid2]'
#may be:
# user|password foo|bar|/home/foo
#OR
# user|password|/home/user/dir|10000
#OR
# user|password||10000


#Default user 'ftp' with password 'alpineftp'


if [ -z "$USERS" ]; then
  USERS="ftp|alpineftp"
fi

for i in $USERS ; do
    NAME=$(echo $i | cut -d'|' -f1)
    PASS=$(echo $i | cut -d'|' -f2)
  FOLDER=$(echo $i | cut -d'|' -f3)
     UID=$(echo $i | cut -d'|' -f4)

  if [ -z "$FOLDER" ]; then
    FOLDER="/ftp/$NAME"
  fi

  if [ ! -z "$UID" ]; then
    UID_OPT="-u $UID"
  fi

  echo -e "$PASS\n$PASS" | adduser -h $FOLDER -s /sbin/nologin $UID_OPT $NAME
  mkdir -p $FOLDER
  chown $NAME:$NAME $FOLDER
  unset NAME PASS FOLDER UID
done


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
