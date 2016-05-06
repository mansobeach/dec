#!/bin/bash

# E2ESPM is leaking "temporal" shit everywhere

# ------------------------------------------------------------------------------
# CLEAN-UP WPS CLIENT TEMP SHIT

# clean wps temporal files older than 1 day

source /home/e2espm/.bashrc

URL_WPS="http://10.182.17.22:9504/wps/RetrieveResultServlet?id="

# ------------------------------------------------------------------------------
# CLEAN-UP MCF_TRIGGERING TEMP SHIT

# clean mcf temporal directories with name signature with a date such as 20151214*

OLD_DIR=$PWD

cd $MCF_DATA/tmp/

OLD_JOBS=$(find 20* -mtime +1 -type d 2>/dev/null | xargs ls -d)

if [ "$OLD_JOBS" != "." ]
then
   for job in $OLD_JOBS; do
      echo "$URL_WPS$job"
      curl "$URL_WPS$job"
      rm -rf $job
   done
fi 


# ----------------------------------------------------------------------------

cd $MCF_DATA/tmp/mcf_triggering

OLD_JOBS=$(find 20* -maxdepth 0 -mtime +1 -type d 2>/dev/null | xargs ls -d)

if [ "$OLD_JOBS" != "." ] 
then
   for job in $OLD_JOBS; do
      echo "$URL_WPS$job"
      curl "$URL_WPS$job"
      rm -rf $job
   done
fi 

# ----------------------------------------------------------------------------

cd $OLD_DIR

# ------------------------------------------------------------------------------
