#!/usr/bin/env bash

sudo apt-get -y update

sudo apt-get -y install software-properties-common

sudo apt-get -y install python-software-properties

sudo apt-add-repository -y ppa:brightbox/ruby-ng

sudo apt-get -y update

sudo apt-get -y install ruby2.4 ruby2.4-dev

sudo apt-get -y install sqlite3  libsqlite3-dev

sudo gem install bundler
