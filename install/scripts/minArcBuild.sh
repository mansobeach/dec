#!/bin/bash

# sudo docker image build --rm=false -t app_minarc_s2 . -f install/docker/Dockerfile.minarc.s2.e2espm-inputhub.e2edc

## Create both minARC and DEC

if [ $HOSTNAME != "S2MPA-V2-Dr-001" ] && [ $HOSTNAME != "S2MPA-IVV" ]
then
   echo $HOSTNAME
   cmd="rake -f build_minarc.rake minarc:install[s2decservice,e2espm-inputhub,s2_pg]"
   echo $cmd
   eval $cmd
fi

sudo docker image build -t app_minarc_s2 . -f install/docker/Dockerfile.s2decservice.minarc

if [ $HOSTNAME != "S2MPA-V2-Dr-001" ] && [ $HOSTNAME != "S2MPA-IVV" ]
then
   cmd="rake -f build_dec.rake dec:install[s2decservice,e2espm-inputhub]"
   echo $cmd
   eval $cmd
fi

sudo docker image build -t app_dec_s2 . -f install/docker/Dockerfile.s2decservice.dec
