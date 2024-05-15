#!/bin/bash
set -e

[ "$DEBUG" == 'true' ] && set -x


echo "entrypoint minarc"

# echo "minArcDB -c"
# minArcDB -c

echo "minArcServer -s"
minArcServer -s

## Infinite loop tailing foo

touch /tmp/foo.txt
tail -f /tmp/foo.txt
