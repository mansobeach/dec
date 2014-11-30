#!/bin/bash

URL_METEO="meteomonteporzio.altervista.org"
URL_METEO="meteoleon.altervista.org"

echo
echo "Casale & Beach - Meteo Casale conditional reboot"
echo
curl --silent $URL_METEO

RETVAL=$?

echo $RETVAL

if [ $RETVAL -ne 0 ] ; then
   echo "Rebooting ..."
   echo
   /sbin/shutdown -r now
else
   echo "Everything is OK"
fi
