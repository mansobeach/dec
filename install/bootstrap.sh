#!/usr/bin/env bash

sudo add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ precise-pgdg main"

sudo apt-get -y update

sudo apt-get -y install software-properties-common

sudo apt-get -y install python-software-properties

sudo apt-get -y install build-essential

sudo apt-add-repository -y ppa:brightbox/ruby-ng

sudo apt-get -y update

sudo apt-get -y install curl

sudo apt-get -y install p7zip

sudo apt-get -y install p7zip-full

sudo apt-get -y install sqlite3  libsqlite3-dev

sudo apt-get -y install postgresql-9.4
# sudo apt-get -y install postgresql

# It is recommended to install ruby locally with rvm
#
# sudo apt-get -y install ruby2.4 ruby2.4-dev

# sudo gem update --system  2.7.4
# sudo gem update --system

# sudo gem install bundler
