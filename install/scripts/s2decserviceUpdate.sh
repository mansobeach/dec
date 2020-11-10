#!/bin/bash

#sudo docker stop minarc_s2
#
#sudo docker rm minarc_s2
#
#sudo docker stop dec_s2
#
#sudo docker rm dec_s2

sudo docker image build -t app_minarc_s2 . -f install/docker/Dockerfile.s2decservice.minarc

sudo docker image build -t app_dec_s2 . -f install/docker/Dockerfile.s2decservice.dec

sudo docker-compose -f install/docker/docker-compose.s2decservice.yml down

sudo docker-compose -f install/docker/docker-compose.s2decservice.yml up -d

sudo docker-compose -f install/docker/docker-compose.s2decservice.yml ps



