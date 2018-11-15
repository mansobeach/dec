#!/usr/bin/env bash

#########################################################################
#
# Git:
#     install-ruby.sh   $Author: bolf$
#                       $Date$ 
#                       $Committer: bolf$
#                       $Hash: f3afa7c$
#
#########################################################################

source $HOME/.rvm/scripts/rvm || source /etc/profile.d/rvm.sh

rvm use --default --install $1

shift

if (( $# ))
 then gem install $@
fi

rvm cleanup all

gem install bundler

gem update --system
