#!/bin/bash

sudo docker image build --rm=false -t app_dec_s2 . -f install/docker/Dockerfile.dec.s2.e2espm-inputhub.e2edc
