#!/bin/bash

## ---------------------------------------------------------
## DEC AUXIP

sudo docker image build -t dec_auxip:latest . -f ./docker/Dockerfile.dec.auxip

sudo docker container run --name dec_auxip -it -d dec_auxip

sudo docker container exec -i -t dec_auxip /bin/bash

## ---------------------------------------------------------
## DEC FTP Service

sudo docker image build -t dec_ftp:latest . -f ./docker/Dockerfile.dec.vsftpd

sudo docker container run --name dec_ftp -p 21:21 -p 30200-30300:30200-30300 -it -d dec_ftp

sudo docker container exec -i -t dec_ftp /bin/bash

## ---------------------------------------------------------



