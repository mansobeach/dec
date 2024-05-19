#!/bin/bash
set +e

[ "$DEBUG" == 'true' ] && set -x


echo "entrypoint adgs dec / waiting 30s for db"
sleep 30

echo "decManageDB -c"
decManageDB -c

echo "decConfigInterface2DB -p EXTERNAL"
decConfigInterface2DB -p EXTERNAL

echo "container entrypoint init ADGS DEC"
decListener -m NOAA_IMS -i 21600
sleep 10

decListener -m NASA_EOSDIS_IERS -i 21600
sleep 10

echo "container entrypoint started adgs dec"

touch /tmp/foo.txt
tail -f /tmp/foo.txt
