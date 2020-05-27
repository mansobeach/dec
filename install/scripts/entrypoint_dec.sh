#!/bin/bash
set -e

decListener -m ISLR -i 30

touch /tmp/foo.txt

tail -f /tmp/foo.txt

