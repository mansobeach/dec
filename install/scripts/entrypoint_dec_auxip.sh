#!/bin/bash
set -e

[ "$DEBUG" == 'true' ] && set -x

decListener -m ILRS -i 3600

decListener -m IGS -i 3600

decListener -m IERS -i 3600

decListener -m SCIHUB -i 86400

decListener -m ECDC -i 86400 --nodb --no-intray

decListener -m NOAA -i 3600

touch /tmp/foo.txt
tail -f /tmp/foo.txt

