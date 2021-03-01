#!/bin/bash
set -e

[ "$DEBUG" == 'true' ] && set -x


echo "entrypoint minarc"

echo "minArcDB -c -H"
minArcDB -c -H

echo "minArcServer -k"
minArcServer -k

echo "minArcServer -s"
minArcServer -s

## Infinite loop tailing foo

touch /tmp/foo.txt
tail -f /tmp/foo.txt
