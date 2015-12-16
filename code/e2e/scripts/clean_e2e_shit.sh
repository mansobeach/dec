#!/bin/bash

# E2ESPM is leaking "temporal" shit everywhere

# ------------------------------------------------------------------------------
# CLEAN-UP WPS CLIENT TEMP SHIT

# clean wps temporal files older than 1 day

find $WPS4EO_CLIENT_CONF_PATH/../tmp -depth -mindepth 1 -mtime +0 -print
find $WPS4EO_CLIENT_CONF_PATH/../tmp -depth -mindepth 1 -mtime +0 -delete


# clean job files leaked in the process control older 1 week

find $WPS4EO_CLIENT_CONF_PATH/../processCtrl/running_processes/20* -depth -maxdepth 0 -mtime +6 -print
find $WPS4EO_CLIENT_CONF_PATH/../processCtrl/running_processes/20* -depth -maxdepth 0 -mtime +6 -delete

# ------------------------------------------------------------------------------

# CLEAN-UP WPS SERVER TEMP SHIT

# job and lock files are left 1 week for investigation purposes

find $WPS4EO_SERVER_CONF_PATH/../tmp/20* -depth -maxdepth 0 -mtime +6 -print
find $WPS4EO_SERVER_CONF_PATH/../tmp/unlock* -depth -maxdepth 0 -mtime +6 -print

find $WPS4EO_SERVER_CONF_PATH/../tmp/20* -depth -maxdepth 0 -mtime +6 -delete
find $WPS4EO_SERVER_CONF_PATH/../tmp/unlock* -depth -maxdepth 0 -mtime +6 -delete

#echo $WPS4EO_SERVER_DATA

# ------------------------------------------------------------------------------
# CLEAN-UP MCF_TRIGGERING TEMP SHIT

# clean mcf temporal directories with name signature with a date such as 20151214*

find $MCF_DATA/tmp/20* -mtime +1 -type d 2>/dev/null | xargs ls -d
find $MCF_DATA/tmp/20* -mtime +1 -type d 2>/dev/null | xargs rm -rf


# clean mcf temporal directories which execution left rubbish in mcf_triggering dir
# Leftover jobs are left 7 days for investigation purposes

find $MCF_DATA/tmp/mcf_triggering/20* -maxdepth 0 -mtime +6 -type d 2>/dev/null | xargs ls -d
find $MCF_DATA/tmp/mcf_triggering/20* -maxdepth 0 -mtime +6 -type d 2>/dev/null | xargs rm -rf


# clean mcf result directories from successfully completed jobs to avoid rubbish flood
# Leftover jobs are left 1 days to avoid clashing

find $MCF_DATA/tmp/mcf_triggering/.ok/20* -maxdepth 0 -mtime +0 -type d 2>/dev/null | xargs ls -d
find $MCF_DATA/tmp/mcf_triggering/.ok/20* -maxdepth 0 -mtime +0 -type d 2>/dev/null | xargs rm -rf


# clean mcf result directories from failed jobs to avoid rubbish flood
# temporal are kept 7 days for investigation purposes

find $MCF_DATA/tmp/mcf_triggering/.ko/20* -maxdepth 0 -mtime +6 -type d 2>/dev/null | xargs ls -d
find $MCF_DATA/tmp/mcf_triggering/.ko/20* -maxdepth 0 -mtime +6 -type d 2>/dev/null | xargs rm -rf

# ------------------------------------------------------------------------------
