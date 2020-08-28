#!/bin/bash

sudo docker rename dec_s2 TO_BE_REPLACED_dec_s2

sudo docker pause TO_BE_REPLACED_dec_s2

sudo docker-compose -f install/docker/docker-compose.dec.s2.e2espm-inputhub.e2edc.yml up -d

sudo docker container ls -l



