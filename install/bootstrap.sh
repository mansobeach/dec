#!/usr/bin/env bash

# ================================================

# Create Swap File

# sudo truncate -s 1G /swapfile && \

sudo dd if=/dev/zero of=/swapfile bs=1M count=1000
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo cp /etc/fstab /etc/fstab.bak
sudo echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# ================================================

sudo add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ precise-pgdg main"

sudo apt-get -y update

sudo apt-get -y install software-properties-common

sudo apt-get -y install python-software-properties

sudo apt-get -y install build-essential

sudo apt-add-repository -y ppa:brightbox/ruby-ng

# ================================================

# Networking tools

sudo apt-get -y update

sudo apt-get -y bridge-utils

sudo apt-get -y lsof

sudo apt-get -y install curl

sudo apt-get -y install ncftp

sudo apt-get -y install libcurl3 libcurl3-gnutls libcurl4-openssl-dev

# General tools

# command line json editor
sudo apt-get -y install jq

sudo apt-get -y install p7zip

sudo apt-get -y install p7zip-full

sudo apt-get -y vim

sudo apt-get -y install sqlite3  libsqlite3-dev

sudo apt-get -y install libimage-exiftool-perl

# sudo apt-get -y install postgresql-9.1
# sudo apt-get -y install postgresql


# ================================================

# Docker Installation

sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get -y update
sudo apt-get -y install docker-ce

sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

chmod a+x /usr/local/bin/docker-compose


# ================================================


# It is recommended to install ruby locally with rvm
#
# sudo apt-get -y install ruby2.4 ruby2.4-dev

# sudo gem update --system  2.7.4
# sudo gem update --system

# sudo gem install bundler
