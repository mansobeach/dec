#!/usr/bin/env sh

gcc -o libopen2300.so open2300.o linux2300.o rw2300.o -shared
