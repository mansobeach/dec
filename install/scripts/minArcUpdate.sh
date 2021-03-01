#!/bin/bash

sudo docker stop minarc_s2

sudo docker rm minarc_s2

sudo docker-compose -f install/docker/docker-compose.minarc.s2.e2espm-inputhub.e2edc.yml up -d

sudo docker container ls -l



