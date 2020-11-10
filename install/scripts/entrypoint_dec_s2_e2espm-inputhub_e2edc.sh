#!/bin/bash
set -e

[ "$DEBUG" == 'true' ] && set -x

#echo "decManageDB -c"
#decManageDB -c

# echo "decConfigInterface2DB -p EXTERNAL"
# decConfigInterface2DB -p EXTERNAL

echo "decListener -m S2PDGS -i 20"
decListener -m S2PDGS -i 20

echo "decListener -m SUPER_TCI -i 60 --nodb"
decListener -m SUPER_TCI -i 60 --nodb

## Infinite loop tailing foo

touch /tmp/foo.txt
tail -f /tmp/foo.txt
