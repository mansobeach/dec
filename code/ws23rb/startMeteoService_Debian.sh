#! /bin/sh
### BEGIN INIT INFO
# Provides:          startMeteoService
# Required-Start:
# Required-Stop:
# Should-Start:      glibc
# Default-Start:     S
# Default-Stop:
# Short-Description: Set hostname based on /etc/hostname
# Description:       Read the machines hostname from /etc/hostname, and
#                    update the kernel value with this value.  If
#                    /etc/hostname is empty, the current kernel value
#                    for hostname is used.  If the kernel value is
#                    empty, the value 'localhost' is used.
### END INIT INFO

PATH=/sbin:/bin:$PATH

. /lib/init/vars.sh
. /lib/lsb/init-functions

do_start () {
   . /home/meteo/Projects/dec/config/./profile_weather
   echo $METEO_STATION
   echo "----------------"
   echo $HOME
   echo "----------------"
   echo $DCC_CONFIG
   echo "----------------"
   echo $METEO_CONFIG
   echo "----------------"
   # echo $PATH
   /home/meteo/Projects/dec/code/ws23rb/./startMeteoCasale2.rb -m station -s
   exit 0
}

do_status () {
	daemonME.rb -c "triggerMeteoData.rb -D" -D
	if [ "$METEO_STATION" ] ; then
		return 0
	else
		return 4
	fi
}

case "$1" in
  start|"")
	do_start
	;;
  restart|reload|force-reload)
	echo "Error: argument '$1' not supported" >&2
	exit 3
	;;
  stop)
	# No-op
	;;
  status)
	do_status
	exit $?
	;;
  *)
	echo "Usage: hostname.sh [start|stop]" >&2
	exit 3
	;;
esac

:
